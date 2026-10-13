//
//  CGPriceRowBindableData.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated struct CGPriceRowBindableData: Identifiable,
                                           Hashable,
                                           Sendable {
    let id: Date
    let date: String
    let price: String
    let isLive: Bool
    let isStale: Bool
    let updatedTime: String?
}

// MARK: - Placeholder

nonisolated extension CGPriceRowBindableData {

    private struct Constants {
        static let placeholderDate = "Mon, 1 Jan"
        static let placeholderPrice = "€00,000.00"
    }

    static func placeholders(count: Int) -> [CGPriceRowBindableData] {
        return (0..<count).map { index in
            return CGPriceRowBindableData(
                id: Date(timeIntervalSince1970: TimeInterval(index)),
                date: Constants.placeholderDate,
                price: Constants.placeholderPrice,
                isLive: false,
                isStale: false,
                updatedTime: nil
            )
        }
    }

}
