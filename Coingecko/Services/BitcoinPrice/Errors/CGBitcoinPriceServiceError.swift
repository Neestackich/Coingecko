//
//  CGBitcoinPriceServiceError.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated enum CGBitcoinPriceServiceError: Error, Equatable {
    case missingPrice(CGCurrency)
}

nonisolated extension CGBitcoinPriceServiceError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .missingPrice(let currency):
            return String(localized: .errorMissingPrice(currency.code))
        }
    }

}
