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

nonisolated extension CGAPIClientType {

    func sendRequest<Response: Decodable>(_ endpoint: CGEndpoint, as type: Response.Type) async throws -> Response {
        let data = try await sendRequest(endpoint)

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw CGAPIClientError.decodingError
        }
    }

}
