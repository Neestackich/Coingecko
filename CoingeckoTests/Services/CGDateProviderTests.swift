//
//  CGDateProviderTests.swift
//  CoingeckoTests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest
@testable import Coingecko

final class CGDateProviderTests: XCTestCase {

    func test_OnInit_ShouldUseUTCCalendar() {
        let sut = CGDateProvider()

        XCTAssertEqual(sut.calendar.timeZone, .gmt)
    }

    func test_OnToday_ShouldReturnStartOfCurrentUTCDay() {
        let sut = CGDateProvider()

        let today = sut.today

        XCTAssertEqual(today, Calendar.utc.startOfDay(for: today))
        XCTAssertTrue(sut.isDateSameAsToday(today))
    }

    func test_OnIsDateSameAsToday_WhenDateIsYesterday_ShouldReturnFalse() {
        let sut = CGDateProvider()

        XCTAssertFalse(sut.isDateSameAsToday(sut.today.addingDays(-1)))
    }

}
