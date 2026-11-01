//
//  ForecastNormalizerTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

final class ForecastNormalizerTests: XCTestCase {

    private func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    private func localMidnight(_ year: Int, _ month: Int, _ day: Int, in identifier: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Weather

    func test_forecastShorterThanSevenDays_returnsOnlyReturnedDates() throws {
        let response: ForecastResponseDTO = try decode("""
        {
          "timezone": "Europe/Berlin",
          "daily": {
            "time": ["2026-11-01", "2026-11-02", "2026-11-03"],
            "weather_code": [0, 61, 3],
            "temperature_2m_max": [10.4, 9.4, 8.0]
          }
        }
        """)

        let forecast = try ForecastNormalizer.weatherForecast(from: response)

        XCTAssertEqual(forecast.days.count, 3)
        XCTAssertEqual(forecast.timeZone.identifier, "Europe/Berlin")
        XCTAssertEqual(forecast.days.map(\.condition), [.clearSky, .slightRain, .overcast])
    }

    func test_incompleteArrays_doNotCrash_andLeaveMissingValuesNil() throws {
        let response: ForecastResponseDTO = try decode("""
        {
          "timezone": "Europe/Berlin",
          "daily": {
            "time": ["2026-11-01", "2026-11-02"],
            "temperature_2m_max": [10.4],
            "precipitation_sum": [null, 0.0]
          },
          "hourly": {
            "time": ["2026-11-01T12:00"],
            "cloud_cover": []
          }
        }
        """)

        let days = try ForecastNormalizer.weatherForecast(from: response).days

        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].temperatureMax, 10.4)
        XCTAssertNil(days[1].temperatureMax)
        XCTAssertNil(days[0].precipitationSum, "null must stay missing, not become zero")
        XCTAssertEqual(days[1].precipitationSum, 0)
        XCTAssertNil(days[0].daytimeCloudCoverAverage)
        XCTAssertNil(days[0].condition)
    }

    func test_unknownWeatherCode_becomesNilCondition() throws {
        let response: ForecastResponseDTO = try decode("""
        { "timezone": "UTC", "daily": { "time": ["2026-11-01"], "weather_code": [42] } }
        """)

        XCTAssertNil(try ForecastNormalizer.weatherForecast(from: response).days[0].condition)
    }

    func test_hourlyValues_groupByLocalDate_notUTC() throws {
        // Auckland is UTC+13 in November: 23:00 local on Nov 1 is 10:00 UTC on Nov 1,
        // and 00:00 local on Nov 2 is 11:00 UTC on Nov 1. Grouping by UTC would merge them.
        let response: ForecastResponseDTO = try decode("""
        {
          "timezone": "Pacific/Auckland",
          "daily": { "time": ["2026-11-01", "2026-11-02"] },
          "hourly": {
            "time": ["2026-11-01T22:00", "2026-11-01T23:00", "2026-11-02T00:00", "2026-11-02T01:00"],
            "snowfall": [1.0, 2.0, 4.0, 8.0]
          }
        }
        """)

        let days = try ForecastNormalizer.weatherForecast(from: response).days

        XCTAssertEqual(days[0].date, localMidnight(2026, 11, 1, in: "Pacific/Auckland"))
        XCTAssertEqual(days[1].date, localMidnight(2026, 11, 2, in: "Pacific/Auckland"))
        XCTAssertEqual(days[0].hourlySnowfallSum, 3)
        XCTAssertEqual(days[1].hourlySnowfallSum, 12)
    }

    func test_daytimeAggregates_ignoreNightHours() throws {
        let response: ForecastResponseDTO = try decode("""
        {
          "timezone": "Europe/Berlin",
          "daily": { "time": ["2026-11-01"] },
          "hourly": {
            "time": ["2026-11-01T03:00", "2026-11-01T10:00", "2026-11-01T14:00"],
            "cloud_cover": [100, 20, 40],
            "wind_gusts_10m": [90, 30, 45],
            "snow_depth": [0.3, 0.2, 0.1]
          }
        }
        """)

        let day = try ForecastNormalizer.weatherForecast(from: response).days[0]

        XCTAssertEqual(day.daytimeCloudCoverAverage, 30)
        XCTAssertEqual(day.daytimeWindGustsMax, 45)
        XCTAssertEqual(day.snowDepthMax, 0.3, "snow depth uses every hour of the day")
    }

    func test_missingTimezoneName_fallsBackToUTCOffset() throws {
        let response: ForecastResponseDTO = try decode("""
        { "utc_offset_seconds": 3600, "daily": { "time": ["2026-11-01"] } }
        """)

        let forecast = try ForecastNormalizer.weatherForecast(from: response)

        XCTAssertEqual(forecast.timeZone.secondsFromGMT(), 3600)
    }

    func test_noTimezoneAtAll_throwsInsteadOfMixingUTCAndLocalDates() throws {
        let response: ForecastResponseDTO = try decode("""
        { "daily": { "time": ["2026-11-01"] } }
        """)

        XCTAssertThrowsError(try ForecastNormalizer.weatherForecast(from: response))
    }

    // MARK: - Marine

    func test_marine_usesDaytimeMedianWaveHeight_notTheLargestReading() throws {
        let response: MarineResponseDTO = try decode("""
        {
          "timezone": "Europe/Lisbon",
          "hourly": {
            "time": ["2026-11-01T02:00", "2026-11-01T08:00", "2026-11-01T12:00", "2026-11-01T16:00"],
            "wave_height": [6.0, 1.0, 1.4, 1.2],
            "wave_period": [15, 10, 12, 11],
            "sea_surface_temperature": [17, 16, 17, 18]
          }
        }
        """)

        let day = try XCTUnwrap(ForecastNormalizer.marineForecast(from: response).first)

        XCTAssertEqual(day.waveHeight, 1.2)
        XCTAssertEqual(day.wavePeriod, 11)
        XCTAssertEqual(day.seaSurfaceTemperature, 17)
        XCTAssertEqual(day.hourlyCoverage, 1)
    }

    func test_marine_inlandNulls_giveNoWaveHeight() throws {
        let response: MarineResponseDTO = try decode("""
        {
          "timezone": "Europe/Berlin",
          "hourly": {
            "time": ["2026-11-01T10:00", "2026-11-01T11:00"],
            "wave_height": [null, null],
            "wave_period": [null, null]
          }
        }
        """)

        let day = try XCTUnwrap(ForecastNormalizer.marineForecast(from: response).first)

        XCTAssertNil(day.waveHeight)
        XCTAssertNil(day.wavePeriod)
        XCTAssertEqual(day.hourlyCoverage, 0)
    }

    func test_marine_fallsBackToSwellPeriod() throws {
        let response: MarineResponseDTO = try decode("""
        {
          "timezone": "Europe/Lisbon",
          "hourly": {
            "time": ["2026-11-01T10:00", "2026-11-01T11:00"],
            "wave_height": [1.5, 1.5],
            "swell_wave_period": [13, 13]
          }
        }
        """)

        XCTAssertEqual(try ForecastNormalizer.marineForecast(from: response).first?.wavePeriod, 13)
    }
}
