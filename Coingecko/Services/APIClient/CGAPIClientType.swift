//
//  CGAPIClientType.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated protocol CGAPIClientType: Sendable {
    func sendRequest(_ endpoint: CGEndpoint) async throws -> Data
}
