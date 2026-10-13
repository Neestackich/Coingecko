//
//  CGBitcoinPriceServiceTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest
@testable import Coingecko

final class CGBitcoinPriceServiceTests: XCTestCase {

    private struct Constants {
        static let marketChartPath = "/coins/bitcoin/market_chart"
        static let historyPath = "/coins/bitcoin/history"
        static let simplePricePath = "/simple/price"
        static let historyCacheKey = "coinHistory-bitcoin-12-10-2026"
    }

    private var apiClient: CGAPIClientMock!
    private var cache: CGCacheMock!

    override func setUp() {
        super.setUp()
        apiClient = CGAPIClientMock()
        cache = CGCacheMock()
    }

    override func tearDown() {
        apiClient = nil
        cache = nil
        super.tearDown()
    }

    private func makeSUT() -> CGBitcoinPriceService {
        return CGBitcoinPriceService(apiClient: apiClient, dateProvider: CGDateProviderMock(), cache: cache)
    }

    private func stubMarketChart(points: [[Double]]) {
        apiClient.dataByPath[Constants.marketChartPath] = CGFixtures.marketChartData(points: points)
    }

}

// MARK: - fetchDailyPrices

extension CGBitcoinPriceServiceTests {

    func test_OnFetchDailyPrices_ShouldRequestMarketChartEndpoint() async throws {
        let sut = makeSUT()
        stubMarketChart(points: CGFixtures.fullHistoryPoints())

        _ = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        XCTAssertEqual(apiClient.sentEndpoints, [.marketChart(coinId: "bitcoin", currency: .eur, days: 14)])
    }

    func test_OnFetchDailyPrices_WhenHistoryIsComplete_ShouldReturnFourteenDaysNewestFirst() async throws {
        let sut = makeSUT()
        stubMarketChart(points: CGFixtures.fullHistoryPoints())

        let prices = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        let expectedDays = (0..<14).map { daysAgo in
            return CGFixtures.today.addingDays(-daysAgo)
        }
        XCTAssertEqual(prices.map(\.date), expectedDays)
        XCTAssertEqual(prices.last?.price, CGFixtures.price(daysAgo: 13))
    }

    func test_OnFetchDailyPrices_WhenTodayHasSeveralPoints_ShouldUseLatestPoint() async throws {
        let sut = makeSUT()
        stubMarketChart(points: CGFixtures.fullHistoryPoints())

        let prices = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        XCTAssertEqual(prices.first?.price, CGFixtures.livePrice)
        XCTAssertEqual(prices.first?.updatedAt, CGFixtures.now)
    }

    func test_OnFetchDailyPrices_WhenPointsAreOutOfOrder_ShouldStillUseLatestPointPerDay() async throws {
        let sut = makeSUT()
        stubMarketChart(points: CGFixtures.fullHistoryPoints().reversed())

        let prices = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        XCTAssertEqual(prices.count, 14)
        XCTAssertEqual(prices.first?.price, CGFixtures.livePrice)
        XCTAssertEqual(prices.map(\.date), prices.map(\.date).sorted(by: >))
    }

    func test_OnFetchDailyPrices_WhenPointsAreOutsideRange_ShouldSkipThem() async throws {
        let sut = makeSUT()
        let tooOld = CGFixtures.today.addingDays(-14).millisecondsSince1970
        let tomorrow = CGFixtures.today.addingDays(1).millisecondsSince1970
        stubMarketChart(points: [[tooOld, 1], [tomorrow, 2]] + CGFixtures.fullHistoryPoints())

        let prices = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        XCTAssertEqual(prices.count, 14)
        XCTAssertEqual(prices.first?.date, CGFixtures.today)
        XCTAssertEqual(prices.last?.date, CGFixtures.today.addingDays(-13))
    }

    func test_OnFetchDailyPrices_WhenDayIsMissing_ShouldReturnRemainingDays() async throws {
        let sut = makeSUT()
        let missingDay = CGFixtures.today.addingDays(-5).millisecondsSince1970
        let points = CGFixtures.fullHistoryPoints().filter { point in
            return point[0] != missingDay
        }
        stubMarketChart(points: points)

        let prices = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        XCTAssertEqual(prices.count, 13)
        XCTAssertFalse(prices.contains { $0.date == CGFixtures.today.addingDays(-5) })
    }

    func test_OnFetchDailyPrices_WhenPointIsMalformed_ShouldSkipIt() async throws {
        let sut = makeSUT()
        let yesterday = CGFixtures.yesterday.millisecondsSince1970
        stubMarketChart(points: [[yesterday], [yesterday, 1, 2], [CGFixtures.now.millisecondsSince1970, 100]])

        let prices = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        XCTAssertEqual(prices.map(\.date), [CGFixtures.today])
    }

    func test_OnFetchDailyPrices_WhenPriceIsNotPositive_ShouldSkipIt() async throws {
        let sut = makeSUT()
        let yesterday = CGFixtures.yesterday.millisecondsSince1970
        let twoDaysAgo = CGFixtures.today.addingDays(-2).millisecondsSince1970
        stubMarketChart(points: [[twoDaysAgo, -5], [yesterday, 0], [CGFixtures.now.millisecondsSince1970, 100]])

        let prices = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        XCTAssertEqual(prices.map(\.date), [CGFixtures.today])
    }

    func test_OnFetchDailyPrices_WhenLatestPointIsInvalid_ShouldKeepEarlierValidPoint() async throws {
        let sut = makeSUT()
        stubMarketChart(points: [
            [CGFixtures.today.millisecondsSince1970, 100],
            [CGFixtures.now.millisecondsSince1970, 0]
        ])

        let prices = try await sut.fetchDailyPricesList(days: 14, currency: .eur)

        XCTAssertEqual(prices.first?.price, 100)
        XCTAssertEqual(prices.first?.updatedAt, CGFixtures.today)
    }

    func test_OnFetchDailyPrices_WhenResponseIsInvalid_ShouldThrowDecodingError() async {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.marketChartPath] = CGFixtures.makeJSON(["prices": [[1, NSNull()]]])

        do {
            _ = try await sut.fetchDailyPricesList(days: 14, currency: .eur)
            XCTFail("Expected decoding error")
        } catch {
            XCTAssertEqual(error as? CGBitcoinPriceServiceError, .decodingError)
        }
    }

    func test_OnFetchDailyPrices_WhenAPIClientFails_ShouldRethrowError() async {
        let sut = makeSUT()
        apiClient.error = CGAPIClientError.httpStatus(429)

        do {
            _ = try await sut.fetchDailyPricesList(days: 14, currency: .eur)
            XCTFail("Expected API client error")
        } catch {
            XCTAssertEqual(error as? CGAPIClientError, .httpStatus(429))
        }
    }

    func test_OnFetchDailyPrices_WhenDaysIsZero_ShouldNotSendRequest() async throws {
        let sut = makeSUT()

        let prices = try await sut.fetchDailyPricesList(days: 0, currency: .eur)

        XCTAssertTrue(prices.isEmpty)
        XCTAssertFalse(apiClient.sendRequestCalled)
    }

}

// MARK: - fetchCurrentPrice

extension CGBitcoinPriceServiceTests {

    func test_OnFetchCurrentPrice_ShouldReturnPriceWithItsUpdateTime() async throws {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.simplePricePath] = CGFixtures.simplePriceData(prices: [.eur: CGFixtures.livePrice])

        let price = try await sut.fetchCurrentDayPrice(currency: .eur)

        XCTAssertEqual(price.price, CGFixtures.livePrice)
        XCTAssertEqual(price.date, CGFixtures.today)
        XCTAssertEqual(price.updatedAt, CGFixtures.now)
        XCTAssertEqual(apiClient.sentEndpoints, [.simplePrice(coinId: "bitcoin", currencies: [.eur])])
    }

    func test_OnFetchCurrentPrice_WhenCurrencyIsMissing_ShouldThrowMissingPrice() async {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.simplePricePath] = CGFixtures.simplePriceData(prices: [.usd: 1])

        do {
            _ = try await sut.fetchCurrentDayPrice(currency: .eur)
            XCTFail("Expected missing price error")
        } catch {
            XCTAssertEqual(error as? CGBitcoinPriceServiceError, .missingPrice(.eur))
        }
    }

    func test_OnFetchCurrentPrice_WhenUpdateTimeIsMissing_ShouldThrowDecodingError() async {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.simplePricePath] = CGFixtures.simplePriceData(prices: [.eur: 1], lastUpdatedAt: nil)

        do {
            _ = try await sut.fetchCurrentDayPrice(currency: .eur)
            XCTFail("Expected decoding error")
        } catch {
            XCTAssertEqual(error as? CGBitcoinPriceServiceError, .decodingError)
        }
    }

}

// MARK: - fetchMultipleCurrenciesPrices

extension CGBitcoinPriceServiceTests {

    func test_OnFetchPrices_WhenDateIsToday_ShouldUseSimplePriceEndpoint() async throws {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.simplePricePath] = CGFixtures.simplePriceData(prices: CGFixtures.currentPrices)

        let prices = try await sut.fetchMultipleCurrenciesPrices(on: CGFixtures.now, currencies: [.eur, .usd, .gbp])

        XCTAssertEqual(prices, CGFixtures.currentPrices)
        XCTAssertEqual(apiClient.sentEndpoints, [.simplePrice(coinId: "bitcoin", currencies: [.eur, .usd, .gbp])])
        XCTAssertFalse(cache.valueCalled)
    }

    func test_OnFetchPrices_WhenDateIsInPast_ShouldUseHistoryEndpointAndCacheResult() async throws {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.historyPath] = CGFixtures.coinHistoryData(prices: CGFixtures.historicalPrices)

        let prices = try await sut.fetchMultipleCurrenciesPrices(on: CGFixtures.yesterday, currencies: [.eur, .usd, .gbp])

        XCTAssertEqual(prices, CGFixtures.historicalPrices)
        XCTAssertEqual(apiClient.sentEndpoints, [.coinHistory(coinId: "bitcoin", date: CGFixtures.yesterday)])
        XCTAssertTrue(cache.storeCalled)
        XCTAssertEqual(cache.storedKey, Constants.historyCacheKey)
    }

    func test_OnFetchPrices_WhenPastDayIsCached_ShouldNotSendRequest() async throws {
        let sut = makeSUT()
        cache.storage[Constants.historyCacheKey] = CGFixtures.historicalPrices

        let prices = try await sut.fetchMultipleCurrenciesPrices(on: CGFixtures.yesterday, currencies: [.eur])

        XCTAssertEqual(prices, [.eur: CGFixtures.historicalPrices[.eur]!])
        XCTAssertFalse(apiClient.sendRequestCalled)
    }

    func test_OnFetchPrices_WhenHistoricalCurrencyIsMissing_ShouldThrowMissingPrice() async {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.historyPath] = CGFixtures.coinHistoryData(prices: [.eur: 1, .usd: 2])

        do {
            _ = try await sut.fetchMultipleCurrenciesPrices(on: CGFixtures.yesterday, currencies: [.eur, .usd, .gbp])
            XCTFail("Expected missing price error")
        } catch {
            XCTAssertEqual(error as? CGBitcoinPriceServiceError, .missingPrice(.gbp))
        }
    }

    func test_OnFetchPrices_WhenHistoricalCurrencyIsMissing_ShouldNotCacheResult() async {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.historyPath] = CGFixtures.coinHistoryData(prices: [.eur: 1, .usd: 2])

        _ = try? await sut.fetchMultipleCurrenciesPrices(on: CGFixtures.yesterday, currencies: [.eur, .usd, .gbp])

        XCTAssertFalse(cache.storeCalled)
    }

    func test_OnFetchPrices_WhenMarketDataIsMissing_ShouldThrowMissingPrice() async {
        let sut = makeSUT()
        apiClient.dataByPath[Constants.historyPath] = CGFixtures.coinHistoryData(prices: nil)

        do {
            _ = try await sut.fetchMultipleCurrenciesPrices(on: CGFixtures.yesterday, currencies: [.eur])
            XCTFail("Expected missing price error")
        } catch {
            XCTAssertEqual(error as? CGBitcoinPriceServiceError, .missingPrice(.eur))
        }
    }

    func test_OnFetchPrices_WhenCurrenciesAreEmpty_ShouldNotSendRequest() async throws {
        let sut = makeSUT()

        let prices = try await sut.fetchMultipleCurrenciesPrices(on: CGFixtures.yesterday, currencies: [])

        XCTAssertTrue(prices.isEmpty)
        XCTAssertFalse(apiClient.sendRequestCalled)
    }

}
