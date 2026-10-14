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
    var fetchPricesResult: Result<[CGCurrencyType: Double], Error> = .success(CGFixtures.historicalPrices)

    var fetchDailyPricesCalled = false
    var fetchDailyPricesCallCount = 0
    var fetchCurrentPriceCalled = false
    var fetchPricesCalled = false
    var requestedDate: Date?
    var requestedCurrencies: [CGCurrencyType] = []

    func fetchDailyPricesList(days: Int, currency: CGCurrencyType) async throws -> [CGDailyPrice] {
        fetchDailyPricesCalled = true
        fetchDailyPricesCallCount += 1

        return try fetchDailyPricesResult.get()
    }

    func fetchCurrentDayPrice(currency: CGCurrencyType) async throws -> CGDailyPrice {
        fetchCurrentPriceCalled = true

        return try fetchCurrentPriceResult.get()
    }

    func fetchMultipleCurrenciesPrices(on date: Date, currencies: [CGCurrencyType]) async throws -> [CGCurrencyType: Double] {
        fetchPricesCalled = true
        requestedDate = date
        requestedCurrencies = currencies

        return try fetchPricesResult.get()
    }

}
