//
//  XCTestCase+Observation.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 14.10.26.
//

import Observation
import XCTest

extension XCTestCase {

    /// Observation reports a change before the new value is stored. The test runs on the main actor,
    /// so it resumes only after the main-actor job that made the change has reached its next suspension point.
    @MainActor
    func waitForNextChange<Value>(of value: () -> Value) async {
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = value()
            } onChange: {
                continuation.resume()
            }
        }
    }

}
