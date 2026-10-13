//
//  CGDateProviderType.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated protocol CGDateProviderType: Sendable {
    var calendar: Calendar { get }
    var now: Date { get }
    var today: Date { get }
    func isDateSameAsToday(_ date: Date) -> Bool
}
