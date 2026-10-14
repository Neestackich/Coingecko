//
//  CGBitcoinPriceService.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated final class CGBitcoinPriceService: CGBitcoinPriceServiceType {

    private let apiClient: CGAPIClientType
    private let dateProvider: CGDateProviderType
    private let cache: CGCacheType

    private struct Constants {
        static let coinId = "bitcoin"
        static let historyCacheKeyPrefix = "coinHistory"
        static let lastUpdatedAtKey = "last_updated_at"
        static let maxClockSkew: TimeInterval = 60
    }

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

    func fetchDailyPricesList(days: Int, currency: CGCurrencyType) async throws -> [CGDailyPrice] {
        guard days > 0 else {
            return []
        }

        let endpoint = CGEndpoint.marketChart(coinId: Constants.coinId, currency: currency, days: days)
        let data = try await apiClient.sendRequest(endpoint)
        let response = try decode(CGMarketChartResponse.self, from: data)

        return makeDailyPrices(from: response.prices, days: days, currency: currency)
    }

    func fetchCurrentDayPrice(currency: CGCurrencyType) async throws -> CGDailyPrice {
        let endpoint = CGEndpoint.simplePrice(coinId: Constants.coinId, currencies: [currency])

        let data = try await apiClient.sendRequest(endpoint)
        let response = try decode(CGSimplePriceResponse.self, from: data)

        let coinPrices = response.prices[Constants.coinId]

        guard let price = coinPrices?[currency.rawValue],
              isValidPrice(price) else {
            throw CGBitcoinPriceServiceError.missingPrice(currency)
        }

        guard let lastUpdatedAt = coinPrices?[Constants.lastUpdatedAtKey],
              let updatedAt = makeTimestamp(secondsSince1970: lastUpdatedAt) else {
            throw CGBitcoinPriceServiceError.decodingError
        }

        return CGDailyPrice(
            date: dateProvider.calendar.startOfDay(for: updatedAt),
            price: price,
            currency: currency,
            updatedAt: updatedAt
        )
    }

    func fetchMultipleCurrenciesPrices(on date: Date, currencies: [CGCurrencyType]) async throws -> [CGCurrencyType: Double] {
        guard !currencies.isEmpty else {
            return [:]
        }

        let day = dateProvider.calendar.startOfDay(for: date)

        if dateProvider.isDateSameAsToday(day) {
            return try await fetchCurrentPrices(currencies: currencies)
        } else {
            let historicalPrices = try await fetchHistoricalPrices(on: day)
            return try makePrices(for: currencies, from: historicalPrices)
        }
    }

}

// MARK: - Private

private nonisolated extension CGBitcoinPriceService {

    func fetchCurrentPrices(currencies: [CGCurrencyType]) async throws -> [CGCurrencyType: Double] {
        let endpoint = CGEndpoint.simplePrice(coinId: Constants.coinId, currencies: currencies)
        let data = try await apiClient.sendRequest(endpoint)
        let response = try decode(CGSimplePriceResponse.self, from: data)

        let coinPrices = response.prices[Constants.coinId] ?? [:]
        let currentPrices = makeCurrencyPrices(from: coinPrices)

        return try makePrices(for: currencies, from: currentPrices)
    }

    func fetchHistoricalPrices(on day: Date) async throws -> [CGCurrencyType: Double] {
        let cacheKey = "\(Constants.historyCacheKeyPrefix)-\(Constants.coinId)-\(day.apiDateString(calendar: dateProvider.calendar))"

        if let cachedPrices = cache.value(forKey: cacheKey, as: [CGCurrencyType: Double].self) {
            return cachedPrices
        } else {

            let endpoint = CGEndpoint.coinHistory(coinId: Constants.coinId, date: day)

            let data = try await apiClient.sendRequest(endpoint)
            let response = try decode(CGCoinHistoryResponse.self, from: data)

            let currentPrice = response.marketData?.currentPrice ?? [:]
            let prices = makeCurrencyPrices(from: currentPrice)

            if prices.count == CGCurrencyType.allCases.count {
                cache.store(prices, forKey: cacheKey)
            }

            return prices
        }
    }

    func makeDailyPrices(
        from points: [[Double]],
        days: Int,
        currency: CGCurrencyType
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
            guard point.count == 2,
                  isValidPrice(point[1]),
                  let timestamp = makeTimestamp(secondsSince1970: point[0] / 1000) else {
                continue
            }

            let day = calendar.startOfDay(for: timestamp)

            guard dayRange.contains(day) else {
                continue
            }

            if let existingPoint = latestPointByDay[day],
               existingPoint.timestamp > timestamp {
                continue
            }

            latestPointByDay[day] = (timestamp, point[1])
        }

        var dailyPrices = latestPointByDay.map {
            return CGDailyPrice(date: $0.key, price: $0.value.price, currency: currency, updatedAt: $0.value.timestamp)
        }

        dailyPrices.sort {
            return $0.date > $1.date
        }

        return dailyPrices
    }

    func makePrices(
        for currencies: [CGCurrencyType],
        from availablePrices: [CGCurrencyType: Double]
    ) throws -> [CGCurrencyType: Double] {
        var prices: [CGCurrencyType: Double] = [:]
        prices.reserveCapacity(currencies.count)

        for currency in currencies {
            guard let price = availablePrices[currency] else {
                throw CGBitcoinPriceServiceError.missingPrice(currency)
            }

            prices[currency] = price
        }

        return prices
    }

    func makeCurrencyPrices(from pricesByCode: [String: Double]) -> [CGCurrencyType: Double] {
        var prices: [CGCurrencyType: Double] = [:]
        prices.reserveCapacity(CGCurrencyType.allCases.count)

        for currency in CGCurrencyType.allCases {
            if let price = pricesByCode[currency.rawValue], isValidPrice(price) {
                prices[currency] = price
            }
        }

        return prices
    }

    func isValidPrice(_ price: Double) -> Bool {
        return price.isFinite && price > 0
    }

    func makeTimestamp(secondsSince1970 seconds: Double) -> Date? {
        guard seconds.isFinite, seconds > 0 else {
            return nil
        }

        let timestamp = Date(timeIntervalSince1970: seconds)

        guard timestamp <= dateProvider.now.addingTimeInterval(Constants.maxClockSkew) else {
            return nil
        }

        return timestamp
    }

    func decode<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw CGBitcoinPriceServiceError.decodingError
        }
    }

}
