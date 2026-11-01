//
//  NetworkManagerTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

final class NetworkManagerTests: XCTestCase {
    /// Has a path, like every Open-Meteo base URL, to check endpoint paths are appended to it.
    private let baseURL = URL(string: "https://example.com/v1")!
    private var sut: NetworkManager!

    override func setUp() {
        super.setUp()
        sut = NetworkManager(baseURL: baseURL, session: MockURLProtocol.makeSession())
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Request

    func test_request_appendsEndpointPathToBaseURLPath() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (.stub(url: request.url, statusCode: 200), Data(Self.validJSON.utf8))
        }

        let _: CitySearchResponseDTO = try await sut.request(GeocodingEndpoint.searchCities(name: "Berlin"))

        XCTAssertEqual(capturedURL?.path, "/v1/search")
        XCTAssertEqual(capturedURL?.host, "example.com")
    }

    // MARK: - Success

    func test_request_with200_decodesResponse() async throws {
        stubResponse(statusCode: 200, body: Self.validJSON)

        let response: CitySearchResponseDTO = try await sut.request(GeocodingEndpoint.searchCities(name: "Berlin"))

        XCTAssertEqual(response.results.map { $0.toDomain() }.map(\.name), ["Berlin"])
    }

    // MARK: - Failure

    func test_request_withNon2xx_throwsBadStatusCode() async {
        stubResponse(statusCode: 404, body: "{}")

        await assertThrows(NetworkError.badStatusCode(404))
    }

    func test_request_withServerError_throwsBadStatusCode() async {
        stubResponse(statusCode: 500, body: "{}")

        await assertThrows(NetworkError.badStatusCode(500))
    }

    func test_request_withMalformedJSON_throwsDecodingFailed() async {
        stubResponse(statusCode: 200, body: #"{"results": "not an array"}"#)

        do {
            let _: CitySearchResponseDTO = try await sut.request(GeocodingEndpoint.searchCities(name: "Berlin"))
            XCTFail("Expected decodingFailed")
        } catch NetworkError.decodingFailed(let description) {
            XCTAssertFalse(description.isEmpty)
        } catch {
            XCTFail("Expected decodingFailed, got \(error)")
        }
    }

    func test_request_whenOffline_throwsTransportError() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        await assertThrows(NetworkError.transport(.notConnectedToInternet))
    }

    func test_request_whenURLRequestCancelled_throwsCancellationError() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.cancelled) }

        do {
            let _: CitySearchResponseDTO = try await sut.request(GeocodingEndpoint.searchCities(name: "Berlin"))
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
            // Expected
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    // MARK: - Helpers

    private static let validJSON = """
    {"results": [{"id": 2950159, "name": "Berlin", "latitude": 52.52437, "longitude": 13.41053}]}
    """

    private func stubResponse(statusCode: Int, body: String) {
        MockURLProtocol.requestHandler = { request in
            (.stub(url: request.url, statusCode: statusCode), Data(body.utf8))
        }
    }

    private func assertThrows(
        _ expected: NetworkError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            let _: CitySearchResponseDTO = try await sut.request(GeocodingEndpoint.searchCities(name: "Berlin"))
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch let error as NetworkError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected \(expected), got \(error)", file: file, line: line)
        }
    }
}
