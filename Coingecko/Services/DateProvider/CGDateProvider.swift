//
//  CGDateProvider.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated final class CGDateProvider: CGDateProviderType {

    let calendar: Calendar

    var now: Date {
        return Date()
    }

    var today: Date {
        return calendar.startOfDay(for: now)
    }

    init(calendar: Calendar = .utc) {
        self.calendar = calendar
    }

    func isDateSameAsToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: now)
    }

}
