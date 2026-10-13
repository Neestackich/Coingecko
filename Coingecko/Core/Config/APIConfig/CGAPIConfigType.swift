//
//  CGAPIConfigType.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated protocol CGAPIConfigType: Sendable {
    var baseBackend: String { get }
    var apiKey: String? { get }
}
