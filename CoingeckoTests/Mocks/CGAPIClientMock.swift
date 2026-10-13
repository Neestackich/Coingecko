//
//  CGAPIClientMock.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
@testable import Coingecko

final class CGAPIClientMock: CGAPIClientType, @unchecked Sendable {

    var dataByPath: [String: Data] = [:]
    var error: Error?

    var sendRequestCalled = false
    var sentEndpoints: [CGEndpoint] = []

    func sendRequest(_ endpoint: CGEndpoint) async throws -> Data {
        sendRequestCalled = true
        sentEndpoints.append(endpoint)

        if let error {
            throw error
        }

        guard let data = dataByPath[endpoint.path] else {
            throw CGAPIClientError.httpStatus(404)
        }

        return data
    }

}
