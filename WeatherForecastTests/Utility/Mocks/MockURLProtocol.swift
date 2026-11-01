//
//  MockURLProtocol.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

/// Intercepts every request made through `MockURLProtocol.makeSession()`
/// and answers it with `requestHandler`, so no test touches the network.
final class MockURLProtocol: URLProtocol {
    // Set by each test before it runs and cleared in tearDown; tests never run it concurrently.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension HTTPURLResponse {
    static func stub(url: URL?, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
