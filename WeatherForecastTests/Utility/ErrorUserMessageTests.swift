//
//  ErrorUserMessageTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

final class ErrorUserMessageTests: XCTestCase {

    func test_userMessage_forEveryNetworkError() {
        let cases: [(NetworkError, String)] = [
            (.transport(.notConnectedToInternet), "You're offline. Check your connection and try again."),
            (.transport(.networkConnectionLost), "You're offline. Check your connection and try again."),
            (.transport(.timedOut), "The request timed out. Please try again."),
            (.transport(.cannotFindHost), "Couldn't reach the server. Please try again."),
            (.badStatusCode(500), "The server couldn't complete the request. Please try again later."),
            (.invalidHTTPResponse, "The server couldn't complete the request. Please try again later."),
            (.decodingFailed("keyNotFound"), "We received unexpected data. Please try again later."),
            (.invalidURL, "Something went wrong. Please try again."),
            (.invalidParameters, "Something went wrong. Please try again.")
        ]

        for (error, expected) in cases {
            XCTAssertEqual(error.userMessage, expected, "\(error)")
        }
    }

    func test_userMessage_forNonNetworkError_isGeneric() {
        struct UnknownError: Error {}

        XCTAssertEqual(UnknownError().userMessage, "Something went wrong. Please try again.")
    }
}
