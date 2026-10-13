//
//  XCTestCase+Wait.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest

extension XCTestCase {

    @MainActor
    func waitUntil(
        timeout: Duration = .seconds(2),
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async {
        let deadline = ContinuousClock.now + timeout

        while !condition() {
            guard ContinuousClock.now < deadline else {
                XCTFail("Condition was not met within \(timeout)", file: file, line: line)
                return
            }

            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
