//
//  Date+Extension.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated extension Date {

    func apiDateString(calendar: Calendar = .utc) -> String {
        let components = calendar.dateComponents([.day, .month, .year], from: self)
        let day = components.day ?? 0
        let month = components.month ?? 0
        let year = components.year ?? 0

        return String(format: "%02d-%02d-%04d", day, month, year)
    }

}
