//
//  CGMarketData.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated struct CGMarketData: Decodable, Sendable {
    let currentPrice: [String: Double]

    enum CodingKeys: String, CodingKey {
        case currentPrice = "current_price"
    }
}
