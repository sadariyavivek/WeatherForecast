//
//  HTTPMethod.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

extension HTTPMethod {
    enum ParameterEncoding {
        /// Parameters go in the URL query string.
        case query
        /// Parameters go in the request body as JSON.
        case jsonBody
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
        case .get, .delete:
            return .query
        case .post, .put, .patch:
            return .jsonBody
        }
    }
}
