//
//  CGCacheType.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated protocol CGCacheType: Sendable {
    func value<Value: Sendable>(forKey key: String, as type: Value.Type) -> Value?
    func store<Value: Sendable>(_ value: Value, forKey key: String)
}
