//
//  CGAPIClientTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest
@testable import Coingecko

final class CGAPIClientTests: XCTestCase {

    private struct Constants {
        static let path = "/simple/price"
        static let endpoint = CGEndpoint(path: path, queryItems: [URLQueryItem(name: "ids", value: "bitcoin")])
        static let responseData = Data("{}".utf8)
    }

    override func setUp() {
        super.setUp()
        CGURLProtocolStub.reset()
    }

    override func tearDown() {
        CGURLProtocolStub.reset()
        super.tearDown()
    }

    private func makeSUT(config: CGAPIConfigMock = CGAPIConfigMock()) -> CGAPIClient {
        return CGAPIClient(config: config, session: CGURLProtocolStub.makeSession())
    }

    private func assertSendRequestThrows<ExpectedError: Error & Equatable>(
        _ expectedError: ExpectedError,
        sut: CGAPIClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await sut.sendRequest(Constants.endpoint)
            XCTFail("Expected \(expectedError)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? ExpectedError, expectedError, file: file, line: line)
        }
    }

}

// MARK: - Request

extension CGAPIClientTests {

    func test_OnSendRequest_ShouldBuildURLFromBaseBackendPathAndQuery() async throws {
        let sut = makeSUT()
        CGURLProtocolStub.stub(path: Constants.path, with: .http(statusCode: 200, data: Constants.responseData))

        _ = try await sut.sendRequest(Constants.endpoint)

        let request = try XCTUnwrap(CGURLProtocolStub.requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/api/v3/simple/price?ids=bitcoin")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.timeoutInterval, 15)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func test_OnSendRequest_WhenAPIKeyExists_ShouldSendAPIKeyHeader() async throws {
        let sut = makeSUT()
        CGURLProtocolStub.stub(path: Constants.path, with: .http(statusCode: 200, data: Constants.responseData))

        _ = try await sut.sendRequest(Constants.endpoint)

        let request = try XCTUnwrap(CGURLProtocolStub.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-cg-demo-api-key"), "test-api-key")
    }

    func test_OnSendRequest_WhenAPIKeyIsMissing_ShouldNotSendAPIKeyHeader() async throws {
        let sut = makeSUT(config: CGAPIConfigMock(apiKey: nil))
        CGURLProtocolStub.stub(path: Constants.path, with: .http(statusCode: 200, data: Constants.responseData))

        _ = try await sut.sendRequest(Constants.endpoint)

        let request = try XCTUnwrap(CGURLProtocolStub.requests.first)
        XCTAssertNil(request.value(forHTTPHeaderField: "x-cg-demo-api-key"))
    }

    func test_OnSendRequest_WhenBaseBackendIsInvalid_ShouldThrowURLCreateError() async {
        let sut = makeSUT(config: CGAPIConfigMock(baseBackend: ""))

        await assertSendRequestThrows(CGAPIClientError.urlCreateError, sut: sut)
        XCTAssertTrue(CGURLProtocolStub.requests.isEmpty)
    }

}

// MARK: - Response

extension CGAPIClientTests {

    func test_OnSendRequest_WhenStatusIsSuccessful_ShouldReturnData() async throws {
        let sut = makeSUT()
        CGURLProtocolStub.stub(path: Constants.path, with: .http(statusCode: 200, data: Constants.responseData))

        let data = try await sut.sendRequest(Constants.endpoint)

        XCTAssertEqual(data, Constants.responseData)
    }

    func test_OnSendRequest_WhenStatusIsNotSuccessful_ShouldThrowHTTPStatus() async {
        let sut = makeSUT()
        CGURLProtocolStub.stub(path: Constants.path, with: .http(statusCode: 429, data: Data()))

        await assertSendRequestThrows(CGAPIClientError.httpStatus(429), sut: sut)
    }

    func test_OnSendRequest_WhenResponseIsNotHTTP_ShouldThrowInvalidResponse() async {
        let sut = makeSUT()
        CGURLProtocolStub.stub(path: Constants.path, with: .nonHTTP)

        await assertSendRequestThrows(CGAPIClientError.invalidResponse, sut: sut)
    }

    func test_OnSendRequest_WhenConnectionFails_ShouldThrowTransportError() async {
        let sut = makeSUT()
        CGURLProtocolStub.stub(path: Constants.path, with: .failure(.notConnectedToInternet))

        await assertSendRequestThrows(CGAPIClientError.transportError(.notConnectedToInternet), sut: sut)
    }

    func test_OnSendRequest_WhenRequestIsCancelled_ShouldThrowCancellationError() async {
        let sut = makeSUT()
        CGURLProtocolStub.stub(path: Constants.path, with: .failure(.cancelled))

        do {
            _ = try await sut.sendRequest(Constants.endpoint)
            XCTFail("Expected cancellation error")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

}

// MARK: - Error messages

extension CGAPIClientTests {

    func test_OnErrorDescription_WhenRateLimited_ShouldReturnTooManyRequestsMessage() {
        let sut = CGAPIClientError.httpStatus(429)

        XCTAssertEqual(sut.errorDescription, String(localized: .errorTooManyRequests))
    }

    func test_OnErrorDescription_WhenOffline_ShouldReturnNoInternetMessage() {
        let sut = CGAPIClientError.transportError(.notConnectedToInternet)

        XCTAssertEqual(sut.errorDescription, String(localized: .errorNoInternetConnection))
    }

    func test_OnErrorDescription_WhenServerFails_ShouldReturnGenericMessage() {
        let sut = CGAPIClientError.httpStatus(500)

        XCTAssertEqual(sut.errorDescription, String(localized: .errorGeneric))
    }

}
