//
//  CGPriceListViewModelTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI
import XCTest
@testable import Coingecko

@MainActor
final class CGPriceListViewModelTests: XCTestCase {

    private struct Constants {
        static let newLivePrice = 75012.34
        static let longDelay: Duration = .seconds(10)
        static let shortRefreshInterval: Duration = .milliseconds(10)
    }

    private func makeSUT(
        priceService: CGBitcoinPriceServiceMock,
        dateProvider: CGDateProviderMock = CGDateProviderMock(),
        refreshInterval: Duration = .seconds(60)
    ) -> CGPriceListViewModel {
        return CGPriceListViewModel(priceService: priceService, dateProvider: dateProvider, refreshInterval: refreshInterval)
    }

    private func moveToBackgroundAndWait(_ sut: CGPriceListViewModel) async {
        let task = sut.loadDataTask
        sut.handleScenePhase(.background)
        await task?.value
    }

    private func formatted(_ price: Double) -> String {
        return price.formatted(.currency(code: "EUR"))
    }

    private func makeTodaysPrice(_ price: Double, updatedAt: Date) -> CGDailyPrice {
        return CGDailyPrice(date: CGFixtures.today, price: price, currency: .eur, updatedAt: updatedAt)
    }

}

// MARK: - Initial state

extension CGPriceListViewModelTests {

    func test_OnInit_ShouldShowLoadingWithFourteenPlaceholders() {
        let sut = makeSUT(priceService: CGBitcoinPriceServiceMock())

        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(sut.rows.count, 14)
        XCTAssertNil(sut.lastUpdated)
        XCTAssertFalse(sut.isRefreshFailing)
    }

}

// MARK: - Loading history

extension CGPriceListViewModelTests {

    func test_OnRefresh_WhenPricesLoad_ShouldShowRowsNewestFirst() async {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.rows.map(\.id), CGFixtures.dailyPrices().map(\.date))
        XCTAssertEqual(sut.rows.first?.price, formatted(CGFixtures.livePrice))
        XCTAssertEqual(sut.rows.last?.price, formatted(CGFixtures.price(daysAgo: 13)))
        XCTAssertNotNil(sut.lastUpdated)
        XCTAssertFalse(sut.isRefreshFailing)
    }

    func test_OnRefresh_WhenTodaysPriceIsFresh_ShouldMarkOnlyTodayAsLiveWithTime() async {
        let sut = makeSUT(priceService: CGBitcoinPriceServiceMock())

        await sut.refresh()
        sut.handleScenePhase(.background)

        let time = CGFixtures.now.formatted(date: .omitted, time: .shortened)
        XCTAssertEqual(sut.rows.first?.isLive, true)
        XCTAssertEqual(sut.rows.first?.isStale, false)
        XCTAssertEqual(sut.rows.first?.updatedTime, String(localized: .priceListPriceTime(time)))
        XCTAssertTrue(sut.rows.dropFirst().allSatisfy { !$0.isLive && !$0.isStale && $0.updatedTime == nil })
    }

    func test_OnRefresh_WhenTodaysPriceIsOlderThanFiveMinutes_ShouldMarkTodayAsStale() async {
        let priceService = CGBitcoinPriceServiceMock()
        let oldUpdateTime = CGFixtures.now.addingTimeInterval(-6 * 60)
        priceService.fetchDailyPricesResult = .success(CGFixtures.dailyPrices(todayUpdatedAt: oldUpdateTime))
        priceService.fetchCurrentPriceResult = .success(makeTodaysPrice(CGFixtures.livePrice, updatedAt: oldUpdateTime))
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.rows.first?.isLive, false)
        XCTAssertEqual(sut.rows.first?.isStale, true)
    }

    func test_OnRefresh_WhenTodayOnlyHasMidnightPrice_ShouldMarkTodayAsStale() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchDailyPricesResult = .success(CGFixtures.dailyPrices(todayUpdatedAt: CGFixtures.today))
        priceService.fetchCurrentPriceResult = .failure(CGAPIClientError.httpStatus(500))
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.rows.first?.isStale, true)
    }

    func test_OnRefresh_WhenTodaysPriceIsFourMinutesOld_ShouldKeepTodayLive() async {
        let priceService = CGBitcoinPriceServiceMock()
        let recentUpdateTime = CGFixtures.now.addingTimeInterval(-4 * 60)
        priceService.fetchDailyPricesResult = .success(CGFixtures.dailyPrices(todayUpdatedAt: recentUpdateTime))
        priceService.fetchCurrentPriceResult = .success(makeTodaysPrice(CGFixtures.livePrice, updatedAt: recentUpdateTime))
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.rows.first?.isLive, true)
    }

    func test_OnRefresh_WhenNoPricesReturned_ShouldShowEmptyState() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchDailyPricesResult = .success([])
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .empty)
        XCTAssertTrue(sut.rows.isEmpty)
    }

    func test_OnRefresh_WhenFirstLoadFails_ShouldShowFailedStateWithMessage() async {
        let priceService = CGBitcoinPriceServiceMock()
        let error = CGAPIClientError.transportError(.notConnectedToInternet)
        priceService.fetchDailyPricesResult = .failure(error)
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .failed(error.localizedDescription))
    }

    func test_OnRefresh_WhenServiceIsCancelled_ShouldNotShowError() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchDailyPricesResult = .failure(CancellationError())
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .loading)
    }

}

// MARK: - Failing refresh

extension CGPriceListViewModelTests {

    func test_OnRefresh_WhenReloadFailsWithPricesShown_ShouldKeepRowsAndMarkTodayStale() async {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)
        await sut.refresh()
        priceService.fetchDailyPricesResult = .failure(CGAPIClientError.httpStatus(500))
        priceService.fetchCurrentPriceResult = .failure(CGAPIClientError.httpStatus(500))

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.rows.count, 14)
        XCTAssertTrue(sut.isRefreshFailing)
        XCTAssertEqual(sut.rows.first?.isStale, true)
        XCTAssertEqual(sut.rows.first?.isLive, false)
    }

    func test_OnRefresh_WhenReloadSucceedsAfterFailure_ShouldMarkTodayLiveAgain() async {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)
        await sut.refresh()
        priceService.fetchDailyPricesResult = .failure(CGAPIClientError.httpStatus(500))
        priceService.fetchCurrentPriceResult = .failure(CGAPIClientError.httpStatus(500))
        await sut.refresh()
        priceService.fetchDailyPricesResult = .success(CGFixtures.dailyPrices())
        priceService.fetchCurrentPriceResult = .success(CGFixtures.dailyPrices()[0])

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertFalse(sut.isRefreshFailing)
        XCTAssertEqual(sut.rows.first?.isLive, true)
        XCTAssertEqual(sut.rows.first?.isStale, false)
    }

    func test_OnRetry_AfterFailedFirstLoad_ShouldLoadPrices() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchDailyPricesResult = .failure(CGAPIClientError.httpStatus(500))
        let sut = makeSUT(priceService: priceService)
        await sut.refresh()
        sut.handleScenePhase(.background)
        priceService.fetchDailyPricesResult = .success(CGFixtures.dailyPrices())

        sut.retry()
        XCTAssertEqual(sut.state, .loading)
        await waitUntil { sut.state == .loaded }
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.rows.count, 14)
    }

}

// MARK: - Live updates

extension CGPriceListViewModelTests {

    func test_OnBecomingActive_WhenNothingIsLoaded_ShouldLoadHistory() async {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)

        sut.handleScenePhase(.active)
        await waitUntil { sut.state == .loaded }
        sut.handleScenePhase(.background)

        XCTAssertTrue(priceService.fetchDailyPricesCalled)
        XCTAssertFalse(priceService.fetchCurrentPriceCalled)
    }

    func test_OnBecomingActive_WhenTodayIsLoaded_ShouldUpdateOnlyTodaysPrice() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchCurrentPriceResult = .success(makeTodaysPrice(Constants.newLivePrice, updatedAt: CGFixtures.now))
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        sut.handleScenePhase(.active)
        await waitUntil { sut.rows.first?.price == self.formatted(Constants.newLivePrice) }
        sut.handleScenePhase(.background)

        XCTAssertEqual(priceService.fetchDailyPricesCallCount, 1)
        XCTAssertEqual(sut.rows.first?.isLive, true)
        XCTAssertEqual(sut.rows[1].price, formatted(CGFixtures.price(daysAgo: 1)))
    }

    func test_OnLiveUpdate_WhenCurrentPriceBelongsToAnotherDay_ShouldKeepTodaysRow() async {
        let priceService = CGBitcoinPriceServiceMock()
        let otherDayPrice = CGDailyPrice(date: CGFixtures.yesterday, price: 1, currency: .eur, updatedAt: CGFixtures.yesterday)
        priceService.fetchCurrentPriceResult = .success(otherDayPrice)
        let sut = makeSUT(priceService: priceService, refreshInterval: Constants.shortRefreshInterval)

        await sut.refresh()
        sut.handleScenePhase(.active)
        await waitUntil { priceService.fetchCurrentPriceCallCount >= 2 }
        await moveToBackgroundAndWait(sut)

        XCTAssertEqual(sut.rows.first?.id, CGFixtures.today)
        XCTAssertEqual(sut.rows.first?.price, formatted(CGFixtures.livePrice))
    }

    func test_OnMovingToBackground_WhenRequestIsInFlight_ShouldCancelWithoutShowingError() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.delay = Constants.longDelay
        let sut = makeSUT(priceService: priceService)

        sut.handleScenePhase(.active)
        await waitUntil { priceService.fetchDailyPricesCalled }
        await moveToBackgroundAndWait(sut)

        XCTAssertEqual(sut.state, .loading)
        XCTAssertNil(sut.lastUpdated)
    }

    func test_OnBecomingActive_WhenFirstLoadFailed_ShouldKeepErrorWhileLoadingAgain() async {
        let priceService = CGBitcoinPriceServiceMock()
        let error = CGAPIClientError.transportError(.notConnectedToInternet)
        priceService.fetchDailyPricesResult = .failure(error)
        let sut = makeSUT(priceService: priceService)
        await sut.refresh()
        sut.handleScenePhase(.background)
        priceService.delay = Constants.longDelay

        sut.handleScenePhase(.active)
        await waitUntil { priceService.fetchDailyPricesCallCount == 2 }
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .failed(error.localizedDescription))
    }

    func test_OnBecomingActive_WhenShownPriceBecameOld_ShouldMarkTodayStaleBeforeRequestFinishes() async {
        let priceService = CGBitcoinPriceServiceMock()
        let dateProvider = CGDateProviderMock()
        let sut = makeSUT(priceService: priceService, dateProvider: dateProvider)
        await sut.refresh()
        sut.handleScenePhase(.background)
        dateProvider.now = CGFixtures.now.addingTimeInterval(10 * 60)
        priceService.delay = Constants.longDelay

        sut.handleScenePhase(.active)
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.rows.first?.isStale, true)
        XCTAssertEqual(sut.rows.first?.isLive, false)
    }

    func test_OnRefresh_WhenLoadSucceeds_ShouldNotRequestTodaysPriceAgainImmediately() async {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)

        await sut.refresh()
        await moveToBackgroundAndWait(sut)

        XCTAssertFalse(priceService.fetchCurrentPriceCalled)
    }

    func test_OnMovingToBackground_WhenRefreshIsInFlight_ShouldCancelRefreshWithoutChangingState() async {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)
        await sut.refresh()
        let lastUpdated = sut.lastUpdated
        priceService.delay = Constants.longDelay
        let startTime = ContinuousClock.now

        let refresh = Task { await sut.refresh() }
        await waitUntil { priceService.fetchDailyPricesCallCount == 2 }
        sut.handleScenePhase(.background)
        await refresh.value

        XCTAssertNil(sut.loadDataTask)
        XCTAssertLessThan(ContinuousClock.now - startTime, Constants.longDelay)
        XCTAssertEqual(sut.state, .loaded)
        XCTAssertFalse(sut.isRefreshFailing)
        XCTAssertEqual(sut.lastUpdated, lastUpdated)
        XCTAssertEqual(priceService.fetchDailyPricesCallCount, 2)
        XCTAssertFalse(priceService.fetchCurrentPriceCalled)
    }

}

// MARK: - Header

extension CGPriceListViewModelTests {

    func test_OnGetSectionHeader_ShouldDescribeDaysAndCurrency() {
        let sut = makeSUT(priceService: CGBitcoinPriceServiceMock())

        XCTAssertEqual(sut.getSectionHeader(), String(localized: .priceListSectionHeader(14, "EUR")))
    }

}

// MARK: - Navigation

extension CGPriceListViewModelTests {

    func test_OnMakeDetailViewModel_ShouldCreateViewModelForSelectedDay() {
        let sut = makeSUT(priceService: CGBitcoinPriceServiceMock())

        let detailViewModel = sut.makeDetailViewModel(for: CGFixtures.yesterday)

        XCTAssertEqual(detailViewModel.getFooter(), String(localized: .priceDetailFooterHistorical))
    }

}
