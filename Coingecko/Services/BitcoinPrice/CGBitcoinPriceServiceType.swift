//
//  CGBitcoinPriceServiceType.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated protocol CGBitcoinPriceServiceType: Sendable {
    func fetchDailyPrices(days: Int, currency: CGCurrency) async throws -> [CGDailyPrice]
    func fetchCurrentPrice(currency: CGCurrency) async throws -> CGDailyPrice
    func fetchPrices(on date: Date, currencies: [CGCurrency]) async throws -> [CGCurrency: Double]
}
