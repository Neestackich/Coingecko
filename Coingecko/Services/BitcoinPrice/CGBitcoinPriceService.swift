//
//  CGBitcoinPriceService.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated final class CGBitcoinPriceService: CGBitcoinPriceServiceType {

    // MARK: Properties

    private let apiClient: CGAPIClientType
    private let dateProvider: CGDateProviderType
    private let cache: CGCacheType

    private struct Constants {
        static let coinId = "bitcoin"
        static let historyCacheKeyPrefix = "coinHistory"
    }

    // MARK: Initialization

    init(
        apiClient: CGAPIClientType,
        dateProvider: CGDateProviderType,
        cache: CGCacheType
    ) {
        self.apiClient = apiClient
        self.dateProvider = dateProvider
        self.cache = cache
    }

}

// MARK: - Public

nonisolated extension CGBitcoinPriceService {

    func fetchDailyPrices(days: Int, currency: CGCurrency) async throws -> [CGDailyPrice] {
        guard days > 0 else {
            return []
        }

        let endpoint = CGEndpoint.marketChart(coinId: Constants.coinId, currency: currency, days: days)
        let response = try await apiClient.sendRequest(endpoint, as: CGMarketChartResponse.self)

        return makeDailyPrices(from: response.prices, days: days, currency: currency)
    }

    func fetchPrices(on date: Date, currencies: [CGCurrency]) async throws -> [CGCurrency: Double] {
        guard !currencies.isEmpty else {
            return [:]
        }

        let day = dateProvider.calendar.startOfDay(for: date)

        if dateProvider.isDateSameAsToday(day) {
            return try await fetchCurrentPrices(currencies: currencies)
        }

        let historicalPrices = try await fetchHistoricalPrices(on: day)

        return try makePrices(for: currencies) { currency in
            historicalPrices[currency]
        }
    }

}

// MARK: - Private

private nonisolated extension CGBitcoinPriceService {

    func fetchCurrentPrices(currencies: [CGCurrency]) async throws -> [CGCurrency: Double] {
        let endpoint = CGEndpoint.simplePrice(coinId: Constants.coinId, currencies: currencies)
        let response = try await apiClient.sendRequest(endpoint, as: CGSimplePriceResponse.self)

        return try makePrices(for: currencies) { currency in
            response.prices[Constants.coinId]?[currency.rawValue]
        }
    }

    func fetchHistoricalPrices(on day: Date) async throws -> [CGCurrency: Double] {
        let cacheKey = "\(Constants.historyCacheKeyPrefix)-\(Constants.coinId)-\(day.apiDateString(calendar: dateProvider.calendar))"

        if let cachedPrices = cache.value(forKey: cacheKey, as: [CGCurrency: Double].self) {
            return cachedPrices
        }

        let endpoint = CGEndpoint.coinHistory(coinId: Constants.coinId, date: day)
        let response = try await apiClient.sendRequest(endpoint, as: CGCoinHistoryResponse.self)

        let currentPrice = response.marketData?.currentPrice ?? [:]

        var prices: [CGCurrency: Double] = [:]
        prices.reserveCapacity(CGCurrency.allCases.count)

        for currency in CGCurrency.allCases {
            prices[currency] = currentPrice[currency.rawValue]
        }

        cache.store(prices, forKey: cacheKey)

        return prices
    }

    func makeDailyPrices(
        from points: [[Double]],
        days: Int,
        currency: CGCurrency
    ) -> [CGDailyPrice] {
        let calendar = dateProvider.calendar
        let today = dateProvider.today

        guard let firstDay = calendar.date(byAdding: .day, value: -(days - 1), to: today) else {
            return []
        }

        let dayRange = firstDay...today

        var latestPointByDay: [Date: (timestamp: Date, price: Double)] = [:]
        latestPointByDay.reserveCapacity(min(days, points.count))

        for point in points {
            guard point.count == 2 else {
                continue
            }

            let timestamp = Date(timeIntervalSince1970: point[0] / 1000)
            let day = calendar.startOfDay(for: timestamp)

            guard dayRange.contains(day) else {
                continue
            }

            if let existingPoint = latestPointByDay[day], existingPoint.timestamp > timestamp {
                continue
            }

            latestPointByDay[day] = (timestamp, point[1])
        }

        var dailyPrices = latestPointByDay.map {
            return CGDailyPrice(date: $0.key, price: $0.value.price, currency: currency)
        }

        dailyPrices.sort {
            return $0.date > $1.date
        }

        return dailyPrices
    }

    func makePrices(
        for currencies: [CGCurrency],
        price: (CGCurrency) -> Double?
    ) throws -> [CGCurrency: Double] {
        var prices: [CGCurrency: Double] = [:]
        prices.reserveCapacity(currencies.count)

        for currency in currencies {
            guard let value = price(currency) else {
                throw CGBitcoinPriceServiceError.missingPrice(currency)
            }
            prices[currency] = value
        }

        return prices
    }

}
