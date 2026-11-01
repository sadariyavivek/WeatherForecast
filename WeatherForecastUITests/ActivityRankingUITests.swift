//
//  ActivityRankingUITests.swift
//  WeatherForecastUITests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest

/// Runs against `StubWeatherForecastRepository.sampleDays` and `StubMarineForecastRepository`,
/// scored by the real engine. The first sample day is sunny, dry and snow-free with good surf.
final class ActivityRankingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_tappingCity_opensRankingWithCityNameAsTitle() {
        let app = openBerlinRanking()

        XCTAssertTrue(app.navigationBars["Berlin"].exists)
        XCTAssertTrue(app.staticTexts["Today"].exists)
    }

    @MainActor
    func test_firstDay_showsOneRowPerActivity() {
        let app = openBerlinRanking()

        XCTAssertEqual(app.rowCount(withIdentifierPrefix: "activityRow_0_"), 4)
    }

    @MainActor
    func test_sunnyFirstDay_ranksOutdoorSightseeingFirstAndSkiingLast() {
        let app = openBerlinRanking()

        XCTAssertTrue(app.element("activityRow_0_outdoorSightseeing").label.hasPrefix("Rank 1, Outdoor sightseeing"))
        XCTAssertTrue(app.element("activityRow_0_skiing").label.hasPrefix("Rank 4, Skiing, score 0"))
    }

    @MainActor
    func test_backButton_returnsToSearchResults() {
        let app = openBerlinRanking()

        app.navigationBars["Berlin"].buttons["Weather"].tap()

        XCTAssertTrue(app.element("cityRow_2950159").waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    /// Searches, taps the first stub city (Berlin, Germany) and waits for its first day to load.
    @MainActor
    private func openBerlinRanking() -> XCUIApplication {
        let app = XCUIApplication.launch(scenario: "success")
        app.searchForCity("Berlin")

        let berlin = app.element("cityRow_2950159")
        XCTAssertTrue(berlin.waitForExistence(timeout: 5))
        berlin.tap()

        XCTAssertTrue(app.element("activityRow_0_outdoorSightseeing").waitForExistence(timeout: 5))
        return app
    }
}
