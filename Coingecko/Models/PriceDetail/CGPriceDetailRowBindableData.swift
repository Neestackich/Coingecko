//
//  CGPriceDetailRowBindableData.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated struct CGPriceDetailRowBindableData: Identifiable,
                                                 Hashable,
                                                 Sendable {
    let id: CGCurrencyType
    let code: String
    let name: String
    let price: String
}

// MARK: - Placeholder

nonisolated extension CGPriceDetailRowBindableData {

    private struct Constants {
        static let placeholderName = "Currency name"
        static let placeholderPrice = "€00,000.00"
    }

    static func placeholders(for currencies: [CGCurrencyType]) -> [CGPriceDetailRowBindableData] {
        return currencies.map { currency in
            return CGPriceDetailRowBindableData(
                id: currency,
                code: currency.code,
                name: Constants.placeholderName,
                price: Constants.placeholderPrice
            )
        }
    }

}
