//
//  UITestHelpers.swift
//  WeatherForecastUITests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest

/// Shared steps for UI tests. The app runs against the stub repositories,
/// so no test depends on the network.
extension XCUIApplication {
    /// Launches with `-UITestScenario <success|empty|failure>`, which `AppContainer` reads
    /// to swap in `StubCityRepository` and `StubWeatherForecastRepository`.
    @MainActor
    static func launch(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestScenario", scenario]
        app.launch()
        return app
    }

    /// Types into the city search field. Results appear after the search debounce.
    @MainActor
    func searchForCity(_ name: String) {
        let field = searchFields["Search for a city"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)
    }

    @MainActor
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)[identifier].firstMatch
    }

    /// Number of rows whose identifier starts with `prefix`.
    /// Counts distinct identifiers: a `NavigationLink` row exposes both its cell and its content
    /// under the same identifier, so counting elements would count each row twice.
    @MainActor
    func rowCount(withIdentifierPrefix prefix: String) -> Int {
        let rows = descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
        return Set(rows.allElementsBoundByIndex.map(\.identifier)).count
    }
}
