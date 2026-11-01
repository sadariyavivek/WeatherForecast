//
//  NetworkManager.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//
import Foundation

protocol NetworkManagerProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: some Endpoint) async throws -> T
}

/// Talks to one backend. Each module gets its own instance with its own base URL, such as `APIBaseURL.geocoding`.
final class NetworkManager: NetworkManagerProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: some Endpoint) async throws -> T {
        let request = try endpoint.urlRequest(relativeTo: baseURL)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            // A cancelled request is not a failure the user should see.
            throw CancellationError()
        } catch let error as URLError {
            throw NetworkError.transport(error.code)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidHTTPResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.badStatusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(String(describing: error))
        }
    }
}
