//
//  CGURLProtocolStub.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

final class CGURLProtocolStub: URLProtocol, @unchecked Sendable {

    enum Response {
        case http(statusCode: Int, data: Data)
        case nonHTTP
        case failure(URLError.Code)
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var responsesByPath: [String: Response] = [:]
    nonisolated(unsafe) private static var recordedRequests: [URLRequest] = []

    static var requests: [URLRequest] {
        lock.withLock { recordedRequests }
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CGURLProtocolStub.self]

        return URLSession(configuration: configuration)
    }

    static func stub(path: String, with response: Response) {
        lock.withLock {
            responsesByPath[path] = response
        }
    }

    static func reset() {
        lock.withLock {
            responsesByPath = [:]
            recordedRequests = []
        }
    }

    static func requests(withPathSuffix suffix: String) -> [URLRequest] {
        return requests.filter { request in
            return request.url?.path.hasSuffix(suffix) == true
        }
    }

    // MARK: URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = Self.lock.withLock {
            Self.recordedRequests.append(request)

            return Self.responsesByPath.first { path, _ in
                return url.path.hasSuffix(path)
            }?.value
        }

        switch response {
        case .http(let statusCode, let data):
            let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .nonHTTP:
            let plainResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            client?.urlProtocol(self, didReceive: plainResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case nil:
            let notFound = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: notFound, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}

}
