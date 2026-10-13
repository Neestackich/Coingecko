//
//  CGBitcoinPriceServiceMock.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
@testable import Coingecko

final class CGBitcoinPriceServiceMock: CGBitcoinPriceServiceType, @unchecked Sendable {

    var fetchDailyPricesResult: Result<[CGDailyPrice], Error> = .success(CGFixtures.dailyPrices())
    var fetchCurrentPriceResult: Result<CGDailyPrice, Error> = .success(CGFixtures.dailyPrices()[0])
    var fetchPricesResult: Result<[CGCurrency: Double], Error> = .success(CGFixtures.historicalPrices)
    var delay: Duration?

    var fetchDailyPricesCalled = false
    var fetchDailyPricesCallCount = 0
    var fetchCurrentPriceCalled = false
    var fetchCurrentPriceCallCount = 0
    var fetchPricesCalled = false
    var requestedDate: Date?
    var requestedCurrencies: [CGCurrency] = []

    func fetchDailyPricesList(days: Int, currency: CGCurrency) async throws -> [CGDailyPrice] {
        fetchDailyPricesCalled = true
        fetchDailyPricesCallCount += 1

        try await simulateDelay()

        return try fetchDailyPricesResult.get()
    }

    func fetchCurrentDayPrice(currency: CGCurrency) async throws -> CGDailyPrice {
        fetchCurrentPriceCalled = true
        fetchCurrentPriceCallCount += 1

        try await simulateDelay()

        return try fetchCurrentPriceResult.get()
    }

    func fetchMultipleCurrenciesPrices(on date: Date, currencies: [CGCurrency]) async throws -> [CGCurrency: Double] {
        fetchPricesCalled = true
        requestedDate = date
        requestedCurrencies = currencies

        try await simulateDelay()

        return try fetchPricesResult.get()
    }

    private func simulateDelay() async throws {
        if let delay {
            try await Task.sleep(for: delay)
        }
    }

}
