//
//  ActivityRankingServiceTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

final class ActivityRankingServiceTests: XCTestCase {
    private let location = ForecastLocation(
        name: "Lisbon",
        latitude: 38.7,
        longitude: -9.1,
        timezone: "Europe/Lisbon"
    )

    func test_marineFailure_leavesSurfingUnavailable_andRanksTheRest() async throws {
        let sut = ActivityRankingService(
            weatherRepository: FixedWeatherRepository(result: .success([.stub()])),
            marineRepository: FixedMarineRepository(result: .failure(NetworkError.badStatusCode(500)))
        )

        let forecast = try await sut.rankActivities(for: location)

        let day = try XCTUnwrap(forecast.days.first)
        XCTAssertEqual(day.score(for: .surfing)?.availability, .unavailable)
        XCTAssertEqual(day.rankedActivities.count, 3)
    }

    func test_weatherFailure_throws() async {
        let sut = ActivityRankingService(
            weatherRepository: FixedWeatherRepository(result: .failure(NetworkError.transport(.timedOut))),
            marineRepository: FixedMarineRepository(result: .success([]))
        )

        do {
            _ = try await sut.rankActivities(for: location)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .transport(.timedOut))
        }
    }
}

private struct FixedWeatherRepository: WeatherForecastRepository {
    let result: Result<[DailyWeatherInput], Error>

    func weatherForecast(for location: ForecastLocation) async throws -> WeatherForecast {
        WeatherForecast(timeZone: TimeZone(identifier: "Europe/Lisbon")!, days: try result.get())
    }
}

private struct FixedMarineRepository: MarineForecastRepository {
    let result: Result<[DailyMarineInput], Error>

    func marineForecast(for location: ForecastLocation) async throws -> [DailyMarineInput] {
        try result.get()
    }
}
