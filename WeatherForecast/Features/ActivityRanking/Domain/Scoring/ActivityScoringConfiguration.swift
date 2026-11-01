//
//  ActivityScoringConfiguration.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// 100 at `best`, 0 at `worst`, linear in between and clamped outside. Works in either direction.
struct ScoreRamp: Equatable, Sendable {
    let best: Double
    let worst: Double

    func score(_ value: Double) -> Double {
        guard best != worst else { return value == best ? 100 : 0 }
        let fraction = (value - worst) / (best - worst)
        return min(max(fraction, 0), 1) * 100
    }
}

/// 100 inside `ideal`, falling linearly to 0 at `lowerLimit` and `upperLimit`.
struct ScoreBand: Equatable, Sendable {
    let ideal: ClosedRange<Double>
    let lowerLimit: Double
    let upperLimit: Double

    func score(_ value: Double) -> Double {
        if ideal.contains(value) { return 100 }
        if value < ideal.lowerBound {
            return ScoreRamp(best: ideal.lowerBound, worst: lowerLimit).score(value)
        }
        return ScoreRamp(best: ideal.upperBound, worst: upperLimit).score(value)
    }
}

/// Every weight and threshold the scoring engine uses.
/// These are starting product heuristics, not official weather or safety standards; tune them through testing.
/// Weights within an activity are fractions that add up to 1.
struct ActivityScoringConfiguration: Equatable, Sendable {
    var skiing = Skiing()
    var surfing = Surfing()
    var outdoorSightseeing = OutdoorSightseeing()
    var indoorSightseeing = IndoorSightseeing()

    /// Below this share of an activity's weights having data, the activity is unavailable.
    var minimumCoverage = 0.5
    var highConfidenceCoverage = 0.9
    var moderateConfidenceCoverage = 0.7
    /// Thunderstorms and freezing rain cap every outdoor activity at this score.
    var hazardScoreCap = 15.0

    static let `default` = ActivityScoringConfiguration()

    struct Skiing: Equatable, Sendable {
        var snowWeight = 0.40
        var temperatureWeight = 0.20
        var windWeight = 0.20
        var precipitationWeight = 0.10
        var weatherWeight = 0.10

        /// Below both of these there's no snow evidence, and skiing scores 0.
        var minimumSnowDepth = 0.05     // m
        var minimumSnowfall = 1.0       // cm
        var snowDepth = ScoreRamp(best: 0.5, worst: 0.05)   // m
        var freshSnow = ScoreRamp(best: 20, worst: 0)       // cm in a day
        /// How much fresh snow adds on top of the existing cover.
        var freshSnowBonus = 0.3
        /// Fresh snow with no snow-depth data counts for this much of a full snow score.
        var freshSnowOnlyFactor = 0.6
        var temperatureMax = ScoreBand(ideal: -12...2, lowerLimit: -25, upperLimit: 8)
        var windSpeed = ScoreRamp(best: 20, worst: 60)
        var windGusts = ScoreRamp(best: 35, worst: 80)
        var precipitationProbability = ScoreRamp(best: 20, worst: 90)
        /// Daytime visibility below this caps the weather score, since flat light hides the terrain.
        var poorVisibility = 1_000.0    // m
        var poorVisibilityWeatherCap = 30.0
        var weatherScores: [WeatherCondition.Kind: Double] = [
            .clear: 100, .partlyCloudy: 95, .overcast: 75, .fog: 30, .drizzle: 20, .rain: 5,
            .heavyRain: 0, .freezing: 0, .snow: 85, .heavySnow: 60, .thunderstorm: 0
        ]
    }

    struct Surfing: Equatable, Sendable {
        var waveHeightWeight = 0.35
        var wavePeriodWeight = 0.25
        var windWeight = 0.25
        var weatherWeight = 0.10
        var seaTemperatureWeight = 0.05

        var waveHeight = ScoreBand(ideal: 0.9...2.5, lowerLimit: 0.3, upperLimit: 4.5)  // m
        var wavePeriod = ScoreRamp(best: 12, worst: 6)          // s
        var windSpeed = ScoreRamp(best: 10, worst: 35)          // km/h, daytime average
        var windGusts = ScoreRamp(best: 20, worst: 55)          // km/h, daytime maximum
        var seaTemperature = ScoreRamp(best: 18, worst: 6)      // °C
        /// Below this share of daytime hours with wave readings, confidence drops to low.
        var lowCoverage = 0.75
        var weatherScores: [WeatherCondition.Kind: Double] = [
            .clear: 100, .partlyCloudy: 95, .overcast: 85, .fog: 50, .drizzle: 75, .rain: 60,
            .heavyRain: 40, .freezing: 10, .snow: 40, .heavySnow: 20, .thunderstorm: 0
        ]
    }

    struct OutdoorSightseeing: Equatable, Sendable {
        var precipitationWeight = 0.30
        var temperatureWeight = 0.25
        var windWeight = 0.15
        var sunshineWeight = 0.20
        var weatherWeight = 0.10

        var precipitationProbability = ScoreRamp(best: 10, worst: 70)  // %
        var precipitationSum = ScoreRamp(best: 0.2, worst: 8)          // mm
        /// Applied to the "feels like" maximum when present, else the actual maximum.
        var temperature = ScoreBand(ideal: 17...26, lowerLimit: -5, upperLimit: 38)
        var windSpeed = ScoreRamp(best: 15, worst: 50)
        var windGusts = ScoreRamp(best: 30, worst: 75)
        var sunshineHours = ScoreRamp(best: 8, worst: 0)
        /// Rain is already scored under precipitation, so wet codes are only mildly penalized here.
        var weatherScores: [WeatherCondition.Kind: Double] = [
            .clear: 100, .partlyCloudy: 95, .overcast: 80, .fog: 45, .drizzle: 60, .rain: 50,
            .heavyRain: 35, .freezing: 0, .snow: 50, .heavySnow: 25, .thunderstorm: 0
        ]
    }

    struct IndoorSightseeing: Equatable, Sendable {
        var precipitationWeight = 0.30
        var temperatureWeight = 0.25
        var weatherWeight = 0.25
        var windWeight = 0.10
        var cloudCoverWeight = 0.10

        /// Indoor sights are always an option, so the score starts here and the weather adds to it.
        var baseline = 30.0
        var precipitationProbability = ScoreRamp(best: 80, worst: 0)   // %
        var precipitationSum = ScoreRamp(best: 10, worst: 0)           // mm
        var heat = ScoreRamp(best: 34, worst: 26)                      // °C, daily maximum
        var cold = ScoreRamp(best: -10, worst: 2)                      // °C, daily minimum
        var windSpeed = ScoreRamp(best: 50, worst: 15)
        var cloudCover = ScoreRamp(best: 100, worst: 0)                // %
        var weatherScores: [WeatherCondition.Kind: Double] = [
            .clear: 10, .partlyCloudy: 20, .overcast: 40, .fog: 60, .drizzle: 60, .rain: 80,
            .heavyRain: 95, .freezing: 100, .snow: 70, .heavySnow: 90, .thunderstorm: 100
        ]
    }
}
