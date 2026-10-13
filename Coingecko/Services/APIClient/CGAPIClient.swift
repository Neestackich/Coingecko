//
//  CGAPIClient.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated final class CGAPIClient: CGAPIClientType {

    private let config: CGAPIConfigType
    private let session: URLSession

    private struct Constants {
        static let apiKeyHeader = "x-cg-demo-api-key"
        static let acceptHeader = "Accept"
        static let jsonContentType = "application/json"
        static let successStatusCodes = 200..<300
        static let requestTimeout: TimeInterval = 15
    }

    init(config: CGAPIConfigType, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

}

// MARK: - Public

nonisolated extension CGAPIClient {

    func sendRequest(_ endpoint: CGEndpoint) async throws -> Data {
        let request = try setupRequest(endpoint: endpoint)
        let (data, response) = try await performRequest(request)
        try validateResponse(response)

        return data
    }

}

// MARK: - Private

private nonisolated extension CGAPIClient {

    func setupRequest(endpoint: CGEndpoint) throws -> URLRequest {
        guard var components = URLComponents(string: config.baseBackend + endpoint.path) else {
            throw CGAPIClientError.urlCreateError
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url,
              url.scheme != nil,
              url.host() != nil else {
            throw CGAPIClientError.urlCreateError
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = Constants.requestTimeout
        request.setValue(Constants.jsonContentType, forHTTPHeaderField: Constants.acceptHeader)

        if let apiKey = config.apiKey {
            request.setValue(apiKey, forHTTPHeaderField: Constants.apiKeyHeader)
        }

        return request
    }

    func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError {
            throw CGAPIClientError.transportError(error.code)
        }
    }

    func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CGAPIClientError.invalidResponse
        }

        guard Constants.successStatusCodes.contains(httpResponse.statusCode) else {
            throw CGAPIClientError.httpStatus(httpResponse.statusCode)
        }
    }

}
