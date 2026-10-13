//
//  CGViewState.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated enum CGViewState: Equatable, Sendable {
    case loading
    case loaded
    case empty
    case failed(String)
}
