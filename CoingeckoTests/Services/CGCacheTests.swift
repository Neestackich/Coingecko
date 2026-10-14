//
//  CGCacheTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest
@testable import Coingecko

final class CGCacheTests: XCTestCase {

    private struct Constants {
        static let key = "coinHistory-bitcoin-12-10-2026"
    }

    func test_OnValue_WhenValueWasStored_ShouldReturnIt() {
        let sut = CGCache()

        sut.store(CGFixtures.historicalPrices, forKey: Constants.key)

        XCTAssertEqual(sut.value(forKey: Constants.key, as: [CGCurrencyType: Double].self), CGFixtures.historicalPrices)
    }

    func test_OnValue_WhenKeyIsUnknown_ShouldReturnNil() {
        let sut = CGCache()

        XCTAssertNil(sut.value(forKey: Constants.key, as: [CGCurrencyType: Double].self))
    }

    func test_OnValue_WhenStoredTypeIsDifferent_ShouldReturnNil() {
        let sut = CGCache()

        sut.store("text", forKey: Constants.key)

        XCTAssertNil(sut.value(forKey: Constants.key, as: [CGCurrencyType: Double].self))
    }

    func test_OnStore_WhenKeyExists_ShouldReplaceValue() {
        let sut = CGCache()

        sut.store(1.0, forKey: Constants.key)
        sut.store(2.0, forKey: Constants.key)

        XCTAssertEqual(sut.value(forKey: Constants.key, as: Double.self), 2.0)
    }

}
