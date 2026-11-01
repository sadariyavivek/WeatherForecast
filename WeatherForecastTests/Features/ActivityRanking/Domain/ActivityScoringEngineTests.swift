//
//  ActivityScoringEngineTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

final class ActivityScoringEngineTests: XCTestCase {
    private let sut = ActivityScoringEngine()

    private func rank(_ weather: DailyWeatherInput, marine: DailyMarineInput? = nil) -> DailyActivityRanking {
        let rankings = sut.rankActivities(forecasts: [weather], marineForecasts: marine.map { [$0] } ?? [])
        return rankings[0]
    }

    // MARK: - Sightseeing

    func test_dryComfortableDay_outdoorSightseeingScoresWellAndRanksFirst() {
        let day = rank(.stub())

        let outdoor = day.score(for: .outdoorSightseeing)
        XCTAssertGreaterThanOrEqual(outdoor?.score ?? 0, 80)
        XCTAssertEqual(outdoor?.confidence, .high)
        XCTAssertEqual(day.rankedOrder.first, .outdoorSightseeing)
    }

    func test_rainyDay_indoorRanksAboveOutdoor() {
        let day = rank(.rainyStub())

        let indoor = day.score(for: .indoorSightseeing)?.score ?? 0
        let outdoor = day.score(for: .outdoorSightseeing)?.score ?? 0
        XCTAssertGreaterThan(indoor, outdoor)
        XCTAssertEqual(day.rankedOrder.first, .indoorSightseeing)
    }

    func test_indoorSightseeing_hasNonzeroBaselineOnPerfectDay() {
        let indoor = rank(.stub()).score(for: .indoorSightseeing)

        XCTAssertEqual(indoor?.availability, .available)
        XCTAssertGreaterThanOrEqual(indoor?.score ?? 0, Int(ActivityScoringConfiguration.default.indoorSightseeing.baseline))
    }

    func test_strongGusts_lowerOutdoorScore() {
        let calm = rank(.stub()).score(for: .outdoorSightseeing)?.score ?? 0
        let windy = rank(.stub(windSpeedMax: 55, windGustsMax: 90)).score(for: .outdoorSightseeing)

        XCTAssertLessThan(windy?.score ?? 100, calm)
        XCTAssertTrue(windy?.reason.contains("gusts up to 90 km/h") ?? false, windy?.reason ?? "")
    }

    func test_thunderstorm_capsOutdoorActivitiesAndExplainsWhy() {
        let day = rank(.stub(condition: .thunderstorm), marine: .stub())
        let cap = Int(ActivityScoringConfiguration.default.hazardScoreCap)

        for activity in [Activity.outdoorSightseeing, .surfing] {
            let score = day.score(for: activity)
            XCTAssertLessThanOrEqual(score?.score ?? 100, cap, "\(activity)")
            XCTAssertTrue(score?.reason.contains("Thunderstorm") ?? false, "\(activity)")
        }
        XCTAssertEqual(day.rankedOrder.first, .indoorSightseeing)
    }

    func test_missingTemperature_outdoorUnavailable_indoorScoredWithLowerConfidence() {
        let day = rank(.stub(temperatureMax: nil, temperatureMin: nil, apparentTemperatureMax: nil))

        XCTAssertEqual(day.score(for: .outdoorSightseeing)?.availability, .unavailable)
        let indoor = day.score(for: .indoorSightseeing)
        XCTAssertEqual(indoor?.availability, .available)
        XCTAssertLessThan(indoor?.confidence ?? .high, .high)
    }

    func test_unknownWeatherCode_isNotTreatedAsClear() {
        let clear = rank(.stub()).score(for: .outdoorSightseeing)
        let unknown = rank(.stub(condition: nil)).score(for: .outdoorSightseeing)

        XCTAssertEqual(unknown?.availability, .available)
        XCTAssertLessThan(unknown?.confidence ?? .high, clear?.confidence ?? .low)
    }

    // MARK: - Skiing

    func test_noSnow_skiingScoresZeroWithoutHighConfidence() {
        let skiing = rank(.stub()).score(for: .skiing)

        XCTAssertEqual(skiing?.score, 0)
        XCTAssertNotEqual(skiing?.confidence, .high)
        XCTAssertEqual(skiing?.reason, "No snow on the ground or in the forecast.")
    }

    func test_snowyColdDay_skiingRanksFirstButNeverHighConfidence() {
        let snowy = DailyWeatherInput.stub(
            condition: .moderateSnowfall,
            temperatureMax: -3,
            temperatureMin: -9,
            apparentTemperatureMax: -7,
            precipitationProbabilityMax: 60,
            precipitationSum: 4,
            snowfallSum: 8,
            sunshineDuration: 3 * 3600,
            windSpeedMax: 15,
            windGustsMax: 30,
            snowDepthMax: 0.6
        )

        let day = rank(snowy)

        XCTAssertEqual(day.rankedOrder.first, .skiing)
        XCTAssertEqual(day.score(for: .skiing)?.confidence, .moderate)
    }

    func test_noSnowData_skiingUnavailable() {
        let skiing = rank(.stub(snowfallSum: nil, snowDepthMax: nil, hourlySnowfallSum: nil)).score(for: .skiing)

        XCTAssertEqual(skiing?.availability, .unavailable)
        XCTAssertNil(skiing?.score)
    }

    // MARK: - Surfing

    func test_favorableWaves_surfingRanksHighly() {
        let surfing = rank(.stub(), marine: .stub()).score(for: .surfing)

        XCTAssertGreaterThanOrEqual(surfing?.score ?? 0, 70)
        XCTAssertEqual(surfing?.availability, .available)
    }

    func test_missingMarineForecast_surfingUnavailableAndNotRanked() {
        let day = rank(.stub(), marine: nil)

        XCTAssertEqual(day.score(for: .surfing)?.availability, .unavailable)
        XCTAssertFalse(day.rankedOrder.contains(.surfing))
        XCTAssertEqual(day.unavailableActivities.map(\.activity), [.surfing])
    }

    func test_inlandLocationWithoutWaveData_surfingUnavailable() {
        let surfing = rank(.stub(), marine: .stub(waveHeight: nil, wavePeriod: nil, seaSurfaceTemperature: nil, hourlyCoverage: 0))
            .score(for: .surfing)

        XCTAssertEqual(surfing?.availability, .unavailable)
        XCTAssertTrue(surfing?.reason.contains("inland") ?? false)
    }

    func test_missingWavePeriod_doesNotAssumeIdealPeriod() {
        let withPeriod = rank(.stub(), marine: .stub()).score(for: .surfing)
        let withoutPeriod = rank(.stub(), marine: .stub(wavePeriod: nil)).score(for: .surfing)

        XCTAssertEqual(withoutPeriod?.availability, .available)
        XCTAssertLessThan(withoutPeriod?.confidence ?? .high, withPeriod?.confidence ?? .low)
    }

    func test_incompleteHourlyMarineData_lowersConfidence() {
        let surfing = rank(.stub(), marine: .stub(hourlyCoverage: 0.5)).score(for: .surfing)

        XCTAssertEqual(surfing?.confidence, .low)
    }

    // MARK: - Ranking

    func test_allFourActivitiesAvailable_producesFourRankedResults() {
        let day = rank(.stub(snowfallSum: 10, snowDepthMax: 0.4), marine: .stub())

        XCTAssertEqual(Set(day.rankedOrder), Set(Activity.allCases))
        XCTAssertTrue(day.unavailableActivities.isEmpty)
    }

    func test_scoresStayWithinZeroToHundred() {
        let days = [DailyWeatherInput.stub(), .rainyStub(), .stub(condition: .thunderstorm, windGustsMax: 150)]

        for day in sut.rankActivities(forecasts: days, marineForecasts: [.stub(waveHeight: 9)]) {
            for score in day.rankedActivities {
                XCTAssertTrue((0...100).contains(score.score ?? -1), "\(score.activity): \(score.score ?? -1)")
            }
        }
    }

    func test_equalScores_sortDeterministically() {
        let date = DailyWeatherInput.stubDate
        let surfing = ActivityScore(date: date, activity: .surfing, score: 50, reason: "", confidence: .high)
        let skiing = ActivityScore(date: date, activity: .skiing, score: 50, reason: "", confidence: .high)

        let first = DailyActivityRanking(date: date, weather: .stub(), scores: [surfing, skiing])
        let second = DailyActivityRanking(date: date, weather: .stub(), scores: [skiing, surfing])

        XCTAssertEqual(first.rankedOrder, [.skiing, .surfing])
        XCTAssertEqual(second.rankedOrder, [.skiing, .surfing])
    }

    func test_sameInputs_giveIdenticalRankings() {
        let days = [DailyWeatherInput.stub(), .rainyStub(date: DailyWeatherInput.stubDate.addingTimeInterval(86_400))]

        XCTAssertEqual(
            sut.rankActivities(forecasts: days, marineForecasts: [.stub()]),
            sut.rankActivities(forecasts: days, marineForecasts: [.stub()])
        )
    }

    func test_eachDateIsRankedIndependently() {
        let tomorrow = DailyWeatherInput.stubDate.addingTimeInterval(86_400)

        let rankings = sut.rankActivities(forecasts: [.stub(), .rainyStub(date: tomorrow)], marineForecasts: [])

        XCTAssertEqual(rankings.map(\.date), [DailyWeatherInput.stubDate, tomorrow])
        XCTAssertEqual(rankings[0].rankedOrder.first, .outdoorSightseeing)
        XCTAssertEqual(rankings[1].rankedOrder.first, .indoorSightseeing)
    }
}
