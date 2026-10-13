//
//  CGDateProviderMock.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
@testable import Coingecko

final class CGDateProviderMock: CGDateProviderType, @unchecked Sendable {

    let calendar = Calendar.utc
    var now: Date

    var today: Date {
        return calendar.startOfDay(for: now)
    }

    init(now: Date = CGFixtures.now) {
        self.now = now
    }

    func isDateSameAsToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: now)
    }

}
