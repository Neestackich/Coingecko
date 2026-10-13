//
//  Date+Test.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
@testable import Coingecko

extension Date {

    static func makeUTC(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )

        return Calendar.utc.date(from: components)!
    }

    func addingDays(_ days: Int) -> Date {
        return Calendar.utc.date(byAdding: .day, value: days, to: self)!
    }

    var millisecondsSince1970: Double {
        return timeIntervalSince1970 * 1000
    }

}
