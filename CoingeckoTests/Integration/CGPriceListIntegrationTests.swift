//
//  CGPriceListIntegrationTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI
import XCTest
@testable import Coingecko

@MainActor
final class CGPriceListIntegrationTests: XCTestCase {

    private struct Constants {
        static let marketChartPath = "/coins/bitcoin/market_chart"
        static let simplePricePath = "/simple/price"
        static let newLivePrice = 75012.34
    }

    override func setUp() {
        super.setUp()
        CGURLProtocolStub.reset()
    }

    override func tearDown() {
        CGURLProtocolStub.reset()
        super.tearDown()
    }

    private func makeSUT() -> CGPriceListViewModel {
        let dateProvider = CGDateProviderMock()
        let apiClient = CGAPIClient(config: CGAPIConfigMock(), session: CGURLProtocolStub.makeSession())
        let priceService = CGBitcoinPriceService(apiClient: apiClient, dateProvider: dateProvider, cache: CGCache())

        return CGPriceListViewModel(priceService: priceService, dateProvider: dateProvider)
    }

    private func stubHistory(statusCode: Int = 200) {
        let data = CGFixtures.marketChartData(points: CGFixtures.fullHistoryPoints())
        CGURLProtocolStub.stub(path: Constants.marketChartPath, with: .http(statusCode: statusCode, data: data))
    }

    private func stubCurrentPrice(_ price: Double = CGFixtures.livePrice) {
        let data = CGFixtures.simplePriceData(prices: [.eur: price])
        CGURLProtocolStub.stub(path: Constants.simplePricePath, with: .http(statusCode: 200, data: data))
    }

}

// MARK: - Tests

extension CGPriceListIntegrationTests {

    func test_OnRefresh_WhenAPIReturnsHistory_ShouldShowFourteenDaysWithLiveToday() async {
        stubHistory()
        stubCurrentPrice()
        let sut = makeSUT()

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.rows.count, 14)
        XCTAssertEqual(sut.rows.first?.id, CGFixtures.today)
        XCTAssertEqual(sut.rows.first?.isLive, true)
        XCTAssertEqual(sut.rows.first?.price, CGFixtures.livePrice.formatted(.currency(code: "EUR")))
    }

    func test_OnRefresh_ShouldRequestFourteenDaysOfEURWithAPIKey() async throws {
        stubHistory()
        stubCurrentPrice()
        let sut = makeSUT()

        await sut.refresh()
        sut.handleScenePhase(.background)

        let request = try XCTUnwrap(CGURLProtocolStub.requests(withPathSuffix: Constants.marketChartPath).first)
        let url = try XCTUnwrap(request.url)
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems, [
            URLQueryItem(name: "vs_currency", value: "eur"),
            URLQueryItem(name: "days", value: "14"),
            URLQueryItem(name: "interval", value: "daily")
        ])
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-cg-demo-api-key"), "test-api-key")
    }

    func test_OnLiveUpdate_ShouldReplaceTodaysPriceFromSimplePriceEndpoint() async {
        stubHistory()
        stubCurrentPrice(Constants.newLivePrice)
        let sut = makeSUT()

        await sut.refresh()
        sut.handleScenePhase(.active)
        await waitUntil { sut.rows.first?.price == Constants.newLivePrice.formatted(.currency(code: "EUR")) }
        sut.handleScenePhase(.background)

        XCTAssertEqual(CGURLProtocolStub.requests(withPathSuffix: Constants.marketChartPath).count, 1)
        XCTAssertFalse(CGURLProtocolStub.requests(withPathSuffix: Constants.simplePricePath).isEmpty)
    }

    func test_OnRefresh_WhenAPIRateLimits_ShouldShowTooManyRequestsError() async {
        stubHistory(statusCode: 429)
        let sut = makeSUT()

        await sut.refresh()
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .failed(String(localized: .errorTooManyRequests)))
    }

    func test_OnLiveUpdate_WhenCurrentPriceFails_ShouldKeepHistoryAndMarkTodayStale() async {
        stubHistory()
        CGURLProtocolStub.stub(path: Constants.simplePricePath, with: .failure(.notConnectedToInternet))
        let sut = makeSUT()

        await sut.refresh()
        sut.handleScenePhase(.active)
        await waitUntil { sut.isRefreshFailing }
        sut.handleScenePhase(.background)

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.rows.count, 14)
        XCTAssertEqual(sut.rows.first?.isStale, true)
    }

}
