//
//  CitySearchUITests.swift
//  WeatherForecastUITests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest

/// Runs against `StubCityRepository` scenarios. The success scenario returns two cities named Berlin.
final class CitySearchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_launch_showsTitleAndSearchPrompt() {
        let app = XCUIApplication.launch(scenario: "success")

        XCTAssertTrue(app.navigationBars["Weather"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Search for a City"].exists)
    }

    @MainActor
    func test_successScenario_showsOneRowPerStubCity() {
        let app = XCUIApplication.launch(scenario: "success")

        app.searchForCity("Berlin")

        XCTAssertTrue(app.element("cityRow_2950159").waitForExistence(timeout: 5))
        XCTAssertEqual(app.rowCount(withIdentifierPrefix: "cityRow_"), 2)
        XCTAssertTrue(app.element("cityRow_2950159").label.contains("State of Berlin, Germany"))
    }

    @MainActor
    func test_emptyScenario_showsNoCitiesFound() {
        let app = XCUIApplication.launch(scenario: "empty")

        app.searchForCity("Nowhere")

        XCTAssertTrue(app.staticTexts["No Cities Found"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.rowCount(withIdentifierPrefix: "cityRow_"), 0)
    }

    @MainActor
    func test_failureScenario_showsErrorWithRetry() {
        let app = XCUIApplication.launch(scenario: "failure")

        app.searchForCity("Berlin")

        XCTAssertTrue(app.staticTexts["Couldn't Search Cities"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["You're offline. Check your connection and try again."].exists)
        XCTAssertTrue(app.buttons["Retry"].exists)
    }
}
