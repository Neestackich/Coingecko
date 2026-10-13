//
//  CGPriceDetailIntegrationTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest
@testable import Coingecko

@MainActor
final class CGPriceDetailIntegrationTests: XCTestCase {

    private struct Constants {
        static let historyPath = "/coins/bitcoin/history"
        static let simplePricePath = "/simple/price"
    }

    private var priceService: CGBitcoinPriceService!
    private var dateProvider: CGDateProviderMock!

    override func setUp() {
        super.setUp()
        CGURLProtocolStub.reset()
        dateProvider = CGDateProviderMock()
        let apiClient = CGAPIClient(config: CGAPIConfigMock(), session: CGURLProtocolStub.makeSession())
        priceService = CGBitcoinPriceService(apiClient: apiClient, dateProvider: dateProvider, cache: CGCache())
    }

    override func tearDown() {
        CGURLProtocolStub.reset()
        priceService = nil
        dateProvider = nil
        super.tearDown()
    }

    private func makeSUT(date: Date) -> CGPriceDetailViewModel {
        return CGPriceDetailViewModel(date: date, priceService: priceService, dateProvider: dateProvider)
    }

    private func loadPrices(on date: Date) async -> CGPriceDetailViewModel {
        let sut = makeSUT(date: date)

        sut.loadData()
        await waitUntil { sut.state != .loading }

        return sut
    }

}

// MARK: - Tests

extension CGPriceDetailIntegrationTests {

    func test_OnStartLoading_WhenDayIsInPast_ShouldShowHistoricalPricesForThatDay() async throws {
        let data = CGFixtures.coinHistoryData(prices: CGFixtures.historicalPrices)
        CGURLProtocolStub.stub(path: Constants.historyPath, with: .http(statusCode: 200, data: data))

        let sut = await loadPrices(on: CGFixtures.yesterday)

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.rows.map(\.code), ["EUR", "USD", "GBP"])
        XCTAssertEqual(sut.rows.last?.price, CGFixtures.historicalPrices[.gbp]!.formatted(.currency(code: "GBP")))

        let request = try XCTUnwrap(CGURLProtocolStub.requests(withPathSuffix: Constants.historyPath).first)
        XCTAssertEqual(request.url?.query()?.contains("date=12-10-2026"), true)
    }

    func test_OnStartLoading_WhenSameDayIsOpenedTwice_ShouldUseCachedPrices() async {
        let data = CGFixtures.coinHistoryData(prices: CGFixtures.historicalPrices)
        CGURLProtocolStub.stub(path: Constants.historyPath, with: .http(statusCode: 200, data: data))

        _ = await loadPrices(on: CGFixtures.yesterday)
        let sut = await loadPrices(on: CGFixtures.yesterday)

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(CGURLProtocolStub.requests(withPathSuffix: Constants.historyPath).count, 1)
    }

    func test_OnStartLoading_WhenDayIsToday_ShouldShowCurrentPrices() async {
        let data = CGFixtures.simplePriceData(prices: CGFixtures.currentPrices)
        CGURLProtocolStub.stub(path: Constants.simplePricePath, with: .http(statusCode: 200, data: data))

        let sut = await loadPrices(on: CGFixtures.today)

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.rows.first?.price, CGFixtures.currentPrices[.eur]!.formatted(.currency(code: "EUR")))
        XCTAssertTrue(CGURLProtocolStub.requests(withPathSuffix: Constants.historyPath).isEmpty)
    }

    func test_OnStartLoading_WhenOffline_ShouldShowNoInternetError() async {
        CGURLProtocolStub.stub(path: Constants.historyPath, with: .failure(.notConnectedToInternet))

        let sut = await loadPrices(on: CGFixtures.yesterday)

        XCTAssertEqual(sut.state, .failed(String(localized: .errorNoInternetConnection)))
    }

    func test_OnStartLoading_WhenCurrencyIsMissing_ShouldShowMissingPriceError() async {
        let data = CGFixtures.coinHistoryData(prices: [.eur: 1, .usd: 2])
        CGURLProtocolStub.stub(path: Constants.historyPath, with: .http(statusCode: 200, data: data))

        let sut = await loadPrices(on: CGFixtures.yesterday)

        XCTAssertEqual(sut.state, .failed(CGBitcoinPriceServiceError.missingPrice(.gbp).localizedDescription))
    }

}
