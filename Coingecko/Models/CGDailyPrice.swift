//
//  CGDailyPrice.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated struct CGDailyPrice: Identifiable,
                                 Hashable,
                                 Sendable {
    let date: Date
    let price: Double
    let currency: CGCurrencyType
    let updatedAt: Date

    var id: Date {
        return date
    }
}
