//
//  CGSimplePriceResponse.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated struct CGSimplePriceResponse: Decodable, Sendable {
    let prices: [String: [String: Double]]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        prices = try container.decode([String: [String: Double]].self)
    }
}
