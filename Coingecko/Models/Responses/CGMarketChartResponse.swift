//
//  CGMarketChartResponse.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated struct CGMarketChartResponse: Decodable, Sendable {
    let prices: [[Double]]
}
