//
//  CGCacheMock.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
@testable import Coingecko

final class CGCacheMock: CGCacheType, @unchecked Sendable {

    var storage: [String: Any] = [:]

    var valueCalled = false
    var storeCalled = false
    var storedKey: String?

    func value<Value: Sendable>(forKey key: String, as type: Value.Type) -> Value? {
        valueCalled = true

        return storage[key] as? Value
    }

    func store<Value: Sendable>(_ value: Value, forKey key: String) {
        storeCalled = true
        storedKey = key
        storage[key] = value
    }

}
