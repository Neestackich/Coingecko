//
//  CGFixtures.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
@testable import Coingecko

enum CGFixtures {

    static let now = Date.makeUTC(year: 2026, month: 10, day: 13, hour: 20, minute: 29, second: 40)
    static let today = Date.makeUTC(year: 2026, month: 10, day: 13)
    static let yesterday = today.addingDays(-1)
    static let days = 14
    static let livePrice = 74504.70

    static let historicalPrices: [CGCurrencyType: Double] = [
        .eur: 74693.77,
        .usd: 86980.12,
        .gbp: 64870.45
    ]

    static let currentPrices: [CGCurrencyType: Double] = [
        .eur: 74504.70,
        .usd: 86760.31,
        .gbp: 64705.92
    ]

}

// MARK: - Domain

extension CGFixtures {

    static func price(daysAgo: Int) -> Double {
        return 70000 + Double(daysAgo) * 100
    }

    static func dailyPrices(todayUpdatedAt: Date = now) -> [CGDailyPrice] {
        return (0..<days).map { daysAgo in
            let day = today.addingDays(-daysAgo)

            return CGDailyPrice(
                date: day,
                price: daysAgo == 0 ? livePrice : price(daysAgo: daysAgo),
                currency: .eur,
                updatedAt: daysAgo == 0 ? todayUpdatedAt : day
            )
        }
    }

}

// MARK: - API responses

extension CGFixtures {

    static func fullHistoryPoints() -> [[Double]] {
        var points: [[Double]] = []

        for daysAgo in (0..<days).reversed() {
            let day = today.addingDays(-daysAgo)
            points.append([day.millisecondsSince1970, price(daysAgo: daysAgo)])
        }

        points.append([now.millisecondsSince1970, livePrice])

        return points
    }

    static func marketChartData(points: [[Double]]) -> Data {
        return makeJSON(["prices": points])
    }

    static func simplePriceData(prices: [CGCurrencyType: Double], lastUpdatedAt: Date? = now) -> Data {
        var bitcoin: [String: Double] = [:]

        for (currency, price) in prices {
            bitcoin[currency.rawValue] = price
        }

        if let lastUpdatedAt {
            bitcoin["last_updated_at"] = lastUpdatedAt.timeIntervalSince1970
        }

        return makeJSON(["bitcoin": bitcoin])
    }

    static func coinHistoryData(prices: [CGCurrencyType: Double]?) -> Data {
        guard let prices else {
            return makeJSON(["id": "bitcoin"])
        }

        var currentPrice: [String: Double] = [:]

        for (currency, price) in prices {
            currentPrice[currency.rawValue] = price
        }

        return makeJSON(["market_data": ["current_price": currentPrice]])
    }

    static func makeJSON(_ object: Any) -> Data {
        return try! JSONSerialization.data(withJSONObject: object)
    }

}
