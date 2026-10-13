//
//  CGFixedDateProvider.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

#if DEBUG

import Foundation

nonisolated final class CGFixedDateProvider: CGDateProviderType {

    let calendar: Calendar
    let now: Date

    var today: Date {
        return calendar.startOfDay(for: now)
    }

    init(now: Date, calendar: Calendar = .utc) {
        self.now = now
        self.calendar = calendar
    }

    func isDateSameAsToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: now)
    }

}

#endif
