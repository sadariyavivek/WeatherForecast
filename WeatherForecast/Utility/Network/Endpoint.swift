//
//  Endpoint.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//

import Foundation

typealias Parameters = [String: any Sendable]

/// Describes one API call. Each feature defines its own conforming enum, such as `ProductEndpoint`.
protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    /// Sent as the query string for GET and DELETE, and as a JSON body for POST, PUT and PATCH.
    var parameters: Parameters { get }
}

extension Endpoint {
    var parameters: Parameters { [:] }

    func urlRequest(relativeTo baseURL: URL) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }

        var body: Data?
        if !parameters.isEmpty {
            switch method.parameterEncoding {
            case .query:
                // Sorted so the URL is the same on every call.
                components.queryItems = parameters
                    .sorted { $0.key < $1.key }
                    .map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            case .jsonBody:
                guard JSONSerialization.isValidJSONObject(parameters) else {
                    throw NetworkError.invalidParameters
                }
                body = try JSONSerialization.data(withJSONObject: parameters, options: .sortedKeys)
            }
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
