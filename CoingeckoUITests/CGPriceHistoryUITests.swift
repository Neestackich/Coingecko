//
//  CGPriceHistoryUITests.swift
//  CoingeckoUITests
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import XCTest

@MainActor
final class CGPriceHistoryUITests: XCTestCase {

    private struct Constants {
        static let launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        static let timeout: TimeInterval = 10
        static let listTitle = "Bitcoin"
        static let historyRowIdentifiers = [
            "priceListRow_13-10-2026",
            "priceListRow_12-10-2026",
            "priceListRow_11-10-2026",
            "priceListRow_10-10-2026",
            "priceListRow_09-10-2026",
            "priceListRow_08-10-2026",
            "priceListRow_07-10-2026",
            "priceListRow_06-10-2026",
            "priceListRow_05-10-2026",
            "priceListRow_04-10-2026",
            "priceListRow_03-10-2026",
            "priceListRow_02-10-2026",
            "priceListRow_01-10-2026",
            "priceListRow_30-09-2026"
        ]
        static let selectedDayIdentifier = "priceListRow_12-10-2026"
        static let selectedDayTitle = "October 12, 2026"
        static let expectedPricesByRowIdentifier = [
            "priceDetailRow_EUR": "€96,412.08",
            "priceDetailRow_USD": "$112,305.44",
            "priceDetailRow_GBP": "£83,190.17"
        ]
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func test_PriceHistory_WhenSelectingDay_ShouldDisplayPricesInThreeCurrencies() {
        let app = XCUIApplication()
        app.launchArguments = Constants.launchArguments
        app.launch()

        XCTAssertTrue(app.navigationBars[Constants.listTitle].waitForExistence(timeout: Constants.timeout))

        for identifier in Constants.historyRowIdentifiers {
            let row = app.buttons[identifier]

            if !row.exists {
                app.swipeUp()
            }

            XCTAssertTrue(row.waitForExistence(timeout: Constants.timeout), "Missing history row \(identifier)")
        }

        let selectedRow = app.buttons[Constants.selectedDayIdentifier]

        if !selectedRow.isHittable {
            app.swipeDown()
        }

        selectedRow.tap()

        XCTAssertTrue(app.navigationBars[Constants.selectedDayTitle].waitForExistence(timeout: Constants.timeout))

        for (identifier, price) in Constants.expectedPricesByRowIdentifier {
            let row = app.descendants(matching: .any)[identifier]
            let showsPrice = NSPredicate(format: "label CONTAINS %@", price)
            let expectation = XCTNSPredicateExpectation(predicate: showsPrice, object: row)

            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: Constants.timeout), .completed, "\(identifier) doesn't show \(price)")
        }

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.navigationBars[Constants.listTitle].waitForExistence(timeout: Constants.timeout))
        XCTAssertTrue(app.buttons[Constants.selectedDayIdentifier].waitForExistence(timeout: Constants.timeout))
    }

}
