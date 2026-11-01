//
//  CachedForecastRepositoriesTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

final class CachedForecastRepositoriesTests: XCTestCase {
    private let lisbon = ForecastLocation(
        name: "Lisbon",
        latitude: 38.71667,
        longitude: -9.13333,
        timezone: "Europe/Lisbon"
    )
    private let timeZone = TimeZone(identifier: "Europe/Lisbon")!
    private let start = Date(timeIntervalSince1970: 1_793_534_400)  // Nov 1 2026, 12:00 in Lisbon

    private var clock: TestClock!
    private var base: CountingWeatherRepository!
    private var sut: CachedWeatherForecastRepository!

    override func setUp() {
        super.setUp()
        clock = TestClock(now: start)
        base = CountingWeatherRepository()
        base.handler = { [timeZone, start] in
            WeatherForecast(timeZone: timeZone, days: Self.days(from: start, in: timeZone), fetchedAt: start)
        }
        sut = CachedWeatherForecastRepository(wrapping: base, now: { [clock] in clock!.now })
    }

    private static func days(from date: Date, in timeZone: TimeZone) -> [DailyWeatherInput] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: date)
        return (0..<3).map { .stub(date: calendar.date(byAdding: .day, value: $0, to: today)!) }
    }

    // MARK: - Fresh

    func test_secondRequestWithinFreshness_usesCache() async throws {
        _ = try await sut.weatherForecast(for: lisbon)
        clock.advance(by: 29 * 60)

        let forecast = try await sut.weatherForecast(for: lisbon)

        XCTAssertEqual(base.callCount, 1)
        XCTAssertFalse(forecast.isStale)
    }

    func test_requestAfterFreshness_fetchesAgain() async throws {
        _ = try await sut.weatherForecast(for: lisbon)
        clock.advance(by: 31 * 60)

        _ = try await sut.weatherForecast(for: lisbon)

        XCTAssertEqual(base.callCount, 2)
    }

    func test_nearlyIdenticalCoordinates_shareAnEntry_butOtherPlacesDont() async throws {
        let sameCity = ForecastLocation(name: "Lisbon", latitude: 38.7171, longitude: -9.1329, timezone: "Europe/Lisbon")
        let porto = ForecastLocation(name: "Porto", latitude: 41.14961, longitude: -8.61099, timezone: "Europe/Lisbon")

        _ = try await sut.weatherForecast(for: lisbon)
        _ = try await sut.weatherForecast(for: sameCity)
        XCTAssertEqual(base.callCount, 1)

        _ = try await sut.weatherForecast(for: porto)
        XCTAssertEqual(base.callCount, 2)
    }

    // MARK: - Failure fallback

    func test_failedRefresh_returnsCachedForecastMarkedStale() async throws {
        let original = try await sut.weatherForecast(for: lisbon)
        clock.advance(by: 2 * 60 * 60)
        base.handler = { throw NetworkError.transport(.notConnectedToInternet) }

        let forecast = try await sut.weatherForecast(for: lisbon)

        XCTAssertTrue(forecast.isStale)
        XCTAssertEqual(forecast.days, original.days)
        XCTAssertEqual(forecast.fetchedAt, original.fetchedAt)
    }

    func test_staleFallback_afterMidnight_dropsDaysThatHavePassed() async throws {
        clock.advance(by: 10 * 60 * 60)
        _ = try await sut.weatherForecast(for: lisbon)                // Nov 1, 22:00 in Lisbon
        clock.advance(by: 3 * 60 * 60)                                 // Nov 2, 01:00, within the 6-hour fallback
        base.handler = { throw NetworkError.badStatusCode(503) }

        let forecast = try await sut.weatherForecast(for: lisbon)

        let original = Self.days(from: start, in: timeZone)
        XCTAssertTrue(forecast.isStale)
        XCTAssertEqual(forecast.days.map(\.date), original.dropFirst().map(\.date))
    }

    func test_failureWithoutCache_throws() async {
        base.handler = { throw NetworkError.transport(.timedOut) }

        do {
            _ = try await sut.weatherForecast(for: lisbon)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .transport(.timedOut))
        }
    }

    func test_failureAfterCacheIsTooOld_throws() async throws {
        _ = try await sut.weatherForecast(for: lisbon)
        clock.advance(by: 7 * 60 * 60)
        base.handler = { throw NetworkError.transport(.timedOut) }

        do {
            _ = try await sut.weatherForecast(for: lisbon)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .transport(.timedOut))
        }
    }

    func test_cancellation_isNotAnsweredWithStaleData() async throws {
        _ = try await sut.weatherForecast(for: lisbon)
        clock.advance(by: 2 * 60 * 60)
        base.handler = { throw CancellationError() }

        do {
            _ = try await sut.weatherForecast(for: lisbon)
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    // MARK: - Marine

    func test_marine_cachesForAnHour_andFallsBackAfterError() async throws {
        let marineBase = CountingMarineRepository()
        marineBase.handler = { [start] in [.stub(date: start)] }
        let marine = CachedMarineForecastRepository(wrapping: marineBase, now: { [clock] in clock!.now })

        _ = try await marine.marineForecast(for: lisbon)
        clock.advance(by: 59 * 60)
        _ = try await marine.marineForecast(for: lisbon)
        XCTAssertEqual(marineBase.callCount, 1)

        clock.advance(by: 2 * 60)
        marineBase.handler = { throw NetworkError.badStatusCode(500) }
        let fallback = try await marine.marineForecast(for: lisbon)

        XCTAssertEqual(marineBase.callCount, 2)
        XCTAssertEqual(fallback, [.stub(date: start)])
    }
}

// Tests touch these only from one test at a time, so unchecked Sendable is safe.

private final class TestClock: @unchecked Sendable {
    var now: Date

    init(now: Date) {
        self.now = now
    }

    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }
}

private final class CountingWeatherRepository: WeatherForecastRepository, @unchecked Sendable {
    var handler: () throws -> WeatherForecast = { throw NetworkError.invalidURL }
    private(set) var callCount = 0

    func weatherForecast(for location: ForecastLocation) async throws -> WeatherForecast {
        callCount += 1
        return try handler()
    }
}

private final class CountingMarineRepository: MarineForecastRepository, @unchecked Sendable {
    var handler: () throws -> [DailyMarineInput] = { [] }
    private(set) var callCount = 0

    func marineForecast(for location: ForecastLocation) async throws -> [DailyMarineInput] {
        callCount += 1
        return try handler()
    }
}
