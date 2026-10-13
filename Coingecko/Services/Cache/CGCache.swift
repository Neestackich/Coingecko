//
//  CGCache.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated final class CGCache: CGCacheType, @unchecked Sendable {

    private let cache = NSCache<NSString, AnyObject>()

    private struct Constants {
        static let defaultCountLimit = 30
    }

    init(countLimit: Int) {
        cache.countLimit = countLimit
    }

    convenience init() {
        self.init(countLimit: Constants.defaultCountLimit)
    }

}

// MARK: - Public

nonisolated extension CGCache {

    func value<Value: Sendable>(forKey key: String, as type: Value.Type) -> Value? {
        return cache.object(forKey: key as NSString) as? Value
    }

    func store<Value: Sendable>(_ value: Value, forKey key: String) {
        cache.setObject(value as AnyObject, forKey: key as NSString)
    }

}
