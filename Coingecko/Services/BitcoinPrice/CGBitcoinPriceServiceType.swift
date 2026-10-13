//
//  CGBitcoinPriceServiceType.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated protocol CGBitcoinPriceServiceType: Sendable {
    func fetchDailyPricesList(days: Int, currency: CGCurrency) async throws -> [CGDailyPrice]
    func fetchCurrentDayPrice(currency: CGCurrency) async throws -> CGDailyPrice
    func fetchMultipleCurrenciesPrices(on date: Date, currencies: [CGCurrency]) async throws -> [CGCurrency: Double]
}
