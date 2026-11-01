//
//  Error+UserMessage.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//
import Foundation

extension Error {
    /// A message that's safe to show the user, shared by every feature.
    var userMessage: String {
        switch self as? NetworkError {
        case .transport(.notConnectedToInternet), .transport(.networkConnectionLost):
            return "You're offline. Check your connection and try again."
        case .transport(.timedOut):
            return "The request timed out. Please try again."
        case .transport:
            return "Couldn't reach the server. Please try again."
        case .badStatusCode, .invalidHTTPResponse:
            return "The server couldn't complete the request. Please try again later."
        case .decodingFailed:
            return "We received unexpected data. Please try again later."
        case .invalidURL, .invalidParameters, nil:
            return "Something went wrong. Please try again."
        }
    }
}
