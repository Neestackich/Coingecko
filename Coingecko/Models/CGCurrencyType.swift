//
//  CGCurrencyType.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated enum CGCurrencyType: String,
                             CaseIterable,
                             Identifiable,
                             Sendable {
    case eur
    case usd
    case gbp

    var id: String {
        return rawValue
    }

    var code: String {
        return rawValue.uppercased()
    }
}
