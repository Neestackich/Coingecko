//
//  CGEndpoint.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated struct CGEndpoint: Equatable, Sendable {

    // MARK: Properties

    let path: String
    let method: CGEndpointMethod
    let queryItems: [URLQueryItem]

    private struct Constants {
        struct Path {
            static func marketChart(coinId: String) -> String { "/coins/\(coinId)/market_chart" }
            static func coinHistory(coinId: String) -> String { "/coins/\(coinId)/history" }
            static let simplePrice = "/simple/price"
        }

        struct Query {
            static let vsCurrency = "vs_currency"
            static let vsCurrencies = "vs_currencies"
            static let days = "days"
            static let interval = "interval"
            static let ids = "ids"
            static let date = "date"
            static let localization = "localization"
            static let includeLastUpdatedAt = "include_last_updated_at"
        }

        struct Value {
            static let dailyInterval = "daily"
            static let localizationDisabled = "false"
            static let enabled = "true"
            static let listSeparator = ","
        }
    }

    // MARK: Initialization

    init(
        path: String,
        method: CGEndpointMethod = .get,
        queryItems: [URLQueryItem] = []
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }

}

// MARK: - CoinGecko

nonisolated extension CGEndpoint {

    static func marketChart(
        coinId: String,
        currency: CGCurrency,
        days: Int
    ) -> CGEndpoint {
        return .init(
            path: Constants.Path.marketChart(coinId: coinId),
            queryItems: [
                URLQueryItem(name: Constants.Query.vsCurrency, value: currency.rawValue),
                URLQueryItem(name: Constants.Query.days, value: String(days)),
                URLQueryItem(name: Constants.Query.interval, value: Constants.Value.dailyInterval)
            ]
        )
    }

    static func simplePrice(coinId: String, currencies: [CGCurrency]) -> CGEndpoint {
        let currencies = currencies.map(\.rawValue).joined(separator: Constants.Value.listSeparator)

        return .init(
            path: Constants.Path.simplePrice,
            queryItems: [
                URLQueryItem(name: Constants.Query.ids, value: coinId),
                URLQueryItem(name: Constants.Query.vsCurrencies, value: currencies),
                URLQueryItem(name: Constants.Query.includeLastUpdatedAt, value: Constants.Value.enabled)
            ]
        )
    }

    static func coinHistory(coinId: String, date: Date) -> CGEndpoint {
        return .init(
            path: Constants.Path.coinHistory(coinId: coinId),
            queryItems: [
                URLQueryItem(name: Constants.Query.date, value: date.apiDateString()),
                URLQueryItem(name: Constants.Query.localization, value: Constants.Value.localizationDisabled)
            ]
        )
    }

}
