//
//  CGAPIConfigMock.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
@testable import Coingecko

struct CGAPIConfigMock: CGAPIConfigType {
    var baseBackend = "https://api.example.com/api/v3"
    var apiKey: String? = "test-api-key"
}
