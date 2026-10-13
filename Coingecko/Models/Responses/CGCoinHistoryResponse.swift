//
//  CGCoinHistoryResponse.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated struct CGCoinHistoryResponse: Decodable, Sendable {
    let marketData: CGMarketData?

    enum CodingKeys: String, CodingKey {
        case marketData = "market_data"
    }
}
