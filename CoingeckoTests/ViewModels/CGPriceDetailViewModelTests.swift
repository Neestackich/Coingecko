//
//  CGPriceDetailViewModelTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest
@testable import Coingecko

@MainActor
final class CGPriceDetailViewModelTests: XCTestCase {

    private struct Constants {
        static let currencies: [CGCurrency] = [.eur, .usd, .gbp]
        static let longDelay: Duration = .seconds(10)
    }

    private func makeSUT(
        date: Date = CGFixtures.yesterday,
        priceService: CGBitcoinPriceServiceMock = CGBitcoinPriceServiceMock()
    ) -> CGPriceDetailViewModel {
        return CGPriceDetailViewModel(date: date, priceService: priceService, dateProvider: CGDateProviderMock())
    }

}

// MARK: - Loading

extension CGPriceDetailViewModelTests {

    func test_OnInit_ShouldShowLoadingWithPlaceholderPerCurrency() {
        let sut = makeSUT()

        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(sut.rows.map(\.id), Constants.currencies)
    }

    func test_OnStartLoading_ShouldRequestAllCurrenciesForSelectedDay() async {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)

        sut.loadData()
        await waitUntil { sut.state == .loaded }

        XCTAssertEqual(priceService.requestedDate, CGFixtures.yesterday)
        XCTAssertEqual(priceService.requestedCurrencies, Constants.currencies)
    }

    func test_OnStartLoading_WhenPricesLoad_ShouldShowFormattedRowsInCurrencyOrder() async {
        let sut = makeSUT()

        sut.loadData()
        await waitUntil { sut.state == .loaded }

        XCTAssertEqual(sut.rows.map(\.code), ["EUR", "USD", "GBP"])
        XCTAssertEqual(sut.rows.first?.price, CGFixtures.historicalPrices[.eur]!.formatted(.currency(code: "EUR")))
        XCTAssertEqual(sut.rows.first?.name, Locale.current.localizedString(forCurrencyCode: "EUR"))
    }

    func test_OnStartLoading_WhenNoPricesReturned_ShouldShowEmptyState() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchPricesResult = .success([:])
        let sut = makeSUT(priceService: priceService)

        sut.loadData()
        await waitUntil { sut.state == .empty }

        XCTAssertTrue(sut.rows.isEmpty)
    }

    func test_OnStartLoading_WhenRequestFails_ShouldShowFailedStateWithMessage() async {
        let priceService = CGBitcoinPriceServiceMock()
        let error = CGBitcoinPriceServiceError.missingPrice(.gbp)
        priceService.fetchPricesResult = .failure(error)
        let sut = makeSUT(priceService: priceService)

        sut.loadData()
        await waitUntil { sut.state != .loading }

        XCTAssertEqual(sut.state, .failed(error.localizedDescription))
    }

    func test_OnRetry_AfterFailure_ShouldLoadPrices() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchPricesResult = .failure(CGAPIClientError.httpStatus(500))
        let sut = makeSUT(priceService: priceService)
        sut.loadData()
        await waitUntil { sut.state != .loading }
        priceService.fetchPricesResult = .success(CGFixtures.historicalPrices)

        sut.retryLoading()
        await waitUntil { sut.state == .loaded }

        XCTAssertEqual(sut.rows.count, 3)
    }

}

// MARK: - Cancellation

extension CGPriceDetailViewModelTests {

    func test_OnStopLoading_WhenRequestIsInFlight_ShouldCancelWithoutShowingError() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.delay = Constants.longDelay
        let sut = makeSUT(priceService: priceService)

        sut.loadData()
        await waitUntil { priceService.fetchPricesCalled }
        let loadTask = sut.loadTask
        sut.cancelDataLoading()
        await loadTask?.value

        XCTAssertEqual(sut.state, .loading)
    }

    func test_OnStartLoading_WhenServiceIsCancelled_ShouldNotShowError() async {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchPricesResult = .failure(CancellationError())
        let sut = makeSUT(priceService: priceService)

        sut.loadData()
        await sut.loadTask?.value

        XCTAssertTrue(priceService.fetchPricesCalled)

        XCTAssertEqual(sut.state, .loading)
    }

}

// MARK: - Title and footer

extension CGPriceDetailViewModelTests {

    func test_OnGetTitle_ShouldFormatSelectedDayInUTC() {
        let sut = makeSUT(date: CGFixtures.yesterday)

        let expectedStyle = Date.FormatStyle(date: .long, time: .omitted, timeZone: .gmt)
        XCTAssertEqual(sut.getTitle(), CGFixtures.yesterday.formatted(expectedStyle))
    }

    func test_OnGetFooter_WhenDayIsToday_ShouldDescribeCurrentPrice() {
        let sut = makeSUT(date: CGFixtures.today)

        XCTAssertEqual(sut.getFooter(), String(localized: .priceDetailFooterToday))
    }

    func test_OnGetFooter_WhenDayIsInPast_ShouldDescribeMidnightPrice() {
        let sut = makeSUT(date: CGFixtures.yesterday)

        XCTAssertEqual(sut.getFooter(), String(localized: .priceDetailFooterHistorical))
    }

}
