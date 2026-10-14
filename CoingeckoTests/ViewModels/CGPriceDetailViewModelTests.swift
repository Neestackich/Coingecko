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
        static let currencies: [CGCurrencyType] = [.eur, .usd, .gbp]
    }

    private func makeSUT(
        date: Date = CGFixtures.yesterday,
        priceService: CGBitcoinPriceServiceMock = CGBitcoinPriceServiceMock()
    ) -> CGPriceDetailViewModel {
        return CGPriceDetailViewModel(date: date, priceService: priceService, dateProvider: CGDateProviderMock())
    }

    private func loadDataAndWait(_ sut: CGPriceDetailViewModel) async throws {
        sut.loadData()
        let loadTask = try XCTUnwrap(sut.loadTask)
        await loadTask.value
    }

}

// MARK: - Loading

extension CGPriceDetailViewModelTests {

    func test_OnInit_ShouldShowLoadingWithPlaceholderPerCurrency() {
        let sut = makeSUT()

        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(sut.rows.map(\.id), Constants.currencies)
    }

    func test_OnStartLoading_ShouldRequestAllCurrenciesForSelectedDay() async throws {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)

        try await loadDataAndWait(sut)

        XCTAssertEqual(priceService.requestedDate, CGFixtures.yesterday)
        XCTAssertEqual(priceService.requestedCurrencies, Constants.currencies)
    }

    func test_OnStartLoading_WhenPricesLoad_ShouldShowFormattedRowsInCurrencyOrder() async throws {
        let sut = makeSUT()

        try await loadDataAndWait(sut)

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.rows.map(\.code), ["EUR", "USD", "GBP"])
        XCTAssertEqual(sut.rows.first?.price, CGFixtures.historicalPrices[.eur]!.formatted(.currency(code: "EUR")))
        XCTAssertEqual(sut.rows.first?.name, Locale.current.localizedString(forCurrencyCode: "EUR"))
    }

    func test_OnStartLoading_WhenNoPricesReturned_ShouldShowEmptyState() async throws {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchPricesResult = .success([:])
        let sut = makeSUT(priceService: priceService)

        try await loadDataAndWait(sut)

        XCTAssertEqual(sut.state, .empty)
        XCTAssertTrue(sut.rows.isEmpty)
    }

    func test_OnStartLoading_WhenRequestFails_ShouldShowFailedStateWithMessage() async throws {
        let priceService = CGBitcoinPriceServiceMock()
        let error = CGBitcoinPriceServiceError.missingPrice(.gbp)
        priceService.fetchPricesResult = .failure(error)
        let sut = makeSUT(priceService: priceService)

        try await loadDataAndWait(sut)

        XCTAssertEqual(sut.state, .failed(error.localizedDescription))
    }

    func test_OnRetry_AfterFailure_ShouldLoadPrices() async throws {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchPricesResult = .failure(CGAPIClientError.httpStatus(500))
        let sut = makeSUT(priceService: priceService)
        try await loadDataAndWait(sut)
        priceService.fetchPricesResult = .success(CGFixtures.historicalPrices)

        sut.retryLoading()
        let retryTask = try XCTUnwrap(sut.loadTask)
        await retryTask.value

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.rows.count, 3)
    }

}

// MARK: - Cancellation

extension CGPriceDetailViewModelTests {

    func test_OnStopLoading_BeforeResponseIsHandled_ShouldNotApplyIt() async throws {
        let priceService = CGBitcoinPriceServiceMock()
        let sut = makeSUT(priceService: priceService)

        sut.loadData()
        let loadTask = try XCTUnwrap(sut.loadTask)
        sut.cancelDataLoading()
        await loadTask.value

        XCTAssertTrue(priceService.fetchPricesCalled)
        XCTAssertNil(sut.loadTask)
        XCTAssertEqual(sut.state, .loading)
    }

    func test_OnStartLoading_WhenServiceIsCancelled_ShouldNotShowError() async throws {
        let priceService = CGBitcoinPriceServiceMock()
        priceService.fetchPricesResult = .failure(CancellationError())
        let sut = makeSUT(priceService: priceService)

        try await loadDataAndWait(sut)

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
