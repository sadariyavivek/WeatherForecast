//
//  APIBaseURLTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

/// Checks the build settings reach the app through Info.plist.
final class APIBaseURLTests: XCTestCase {

    func test_baseURLs_comeFromBuildSettings() {
        XCTAssertEqual(APIBaseURL.geocoding.absoluteString, "https://geocoding-api.open-meteo.com/v1")
        XCTAssertEqual(APIBaseURL.forecast.absoluteString, "https://api.open-meteo.com/v1")
        XCTAssertEqual(APIBaseURL.marine.absoluteString, "https://marine-api.open-meteo.com/v1")
    }
}
