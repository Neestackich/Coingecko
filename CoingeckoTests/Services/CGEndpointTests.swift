//
//  CGEndpointTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest
@testable import Coingecko

final class CGEndpointTests: XCTestCase {

    func test_OnMarketChart_ShouldRequestDailyPricesForGivenDays() {
        let sut = CGEndpoint.marketChart(coinId: "bitcoin", currency: .eur, days: 14)

        XCTAssertEqual(sut.path, "/coins/bitcoin/market_chart")
        XCTAssertEqual(sut.method, .get)
        XCTAssertEqual(sut.queryItems, [
            URLQueryItem(name: "vs_currency", value: "eur"),
            URLQueryItem(name: "days", value: "14"),
            URLQueryItem(name: "interval", value: "daily")
        ])
    }

    func test_OnSimplePrice_ShouldRequestAllCurrenciesWithUpdateTime() {
        let sut = CGEndpoint.simplePrice(coinId: "bitcoin", currencies: [.eur, .usd, .gbp])

        XCTAssertEqual(sut.path, "/simple/price")
        XCTAssertEqual(sut.queryItems, [
            URLQueryItem(name: "ids", value: "bitcoin"),
            URLQueryItem(name: "vs_currencies", value: "eur,usd,gbp"),
            URLQueryItem(name: "include_last_updated_at", value: "true")
        ])
    }

    func test_OnCoinHistory_ShouldFormatDateInUTC() {
        let lateEveningUTC = Date.makeUTC(year: 2026, month: 10, day: 5, hour: 23, minute: 30)

        let sut = CGEndpoint.coinHistory(coinId: "bitcoin", date: lateEveningUTC)

        XCTAssertEqual(sut.path, "/coins/bitcoin/history")
        XCTAssertEqual(sut.queryItems, [
            URLQueryItem(name: "date", value: "05-10-2026"),
            URLQueryItem(name: "localization", value: "false")
        ])
    }

}
