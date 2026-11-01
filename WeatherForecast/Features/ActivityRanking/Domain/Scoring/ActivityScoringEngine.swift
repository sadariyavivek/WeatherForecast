//
//  ActivityScoringEngine.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

/// Scores every activity from 0 to 100 for each forecast date, then ranks them per date.
/// Pure and deterministic: the same inputs and configuration always give the same rankings.
struct ActivityScoringEngine: Sendable {
    let configuration: ActivityScoringConfiguration

    init(configuration: ActivityScoringConfiguration = .default) {
        self.configuration = configuration
    }

    func rankActivities(
        forecasts: [DailyWeatherInput],
        marineForecasts: [DailyMarineInput]
    ) -> [DailyActivityRanking] {
        let marineByDate = Dictionary(
            marineForecasts.map { ($0.date, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return forecasts.map { weather in
            DailyActivityRanking(
                date: weather.date,
                weather: weather,
                scores: [
                    skiingScore(for: weather),
                    surfingScore(for: weather, marine: marineByDate[weather.date]),
                    outdoorSightseeingScore(for: weather),
                    indoorSightseeingScore(for: weather)
                ]
            )
        }
    }

    // MARK: - Skiing

    func skiingScore(for weather: DailyWeatherInput) -> ActivityScore {
        let config = configuration.skiing
        let snowfall = weather.snowfallSum ?? weather.hourlySnowfallSum

        guard weather.snowDepthMax != nil || snowfall != nil else {
            return .unavailable(.skiing, date: weather.date, reason: "The forecast has no snow data.")
        }

        // Neither value alone proves a resort is open, so skiing is never more than moderately confident.
        let confidenceCap: ScoreConfidence = weather.snowDepthMax == nil ? .low : .moderate

        let hasSnow = (weather.snowDepthMax ?? 0) >= config.minimumSnowDepth
            || (snowfall ?? 0) >= config.minimumSnowfall
        guard hasSnow else {
            return ActivityScore(
                date: weather.date,
                activity: .skiing,
                score: 0,
                reason: "No snow on the ground or in the forecast.",
                confidence: confidenceCap
            )
        }

        let freshScore = snowfall.map(config.freshSnow.score)
        let snowScore: Double
        let snowStrength: String
        if let depth = weather.snowDepthMax {
            snowScore = min(100, config.snowDepth.score(depth) + (freshScore ?? 0) * config.freshSnowBonus)
            snowStrength = "\(whole(depth * 100)) cm of snow cover"
        } else {
            snowScore = (freshScore ?? 0) * config.freshSnowOnlyFactor
            snowStrength = "\(whole(snowfall ?? 0)) cm of fresh snow"
        }

        let factors = [
            Factor(
                weight: config.snowWeight,
                score: snowScore,
                strength: snowStrength,
                weakness: "thin snow cover"
            ),
            Factor(
                weight: config.temperatureWeight,
                score: weather.temperatureMax.map(config.temperatureMax.score),
                strength: "cold enough to keep the snow good",
                weakness: weather.temperatureMax.map { max in
                    max > config.temperatureMax.ideal.upperBound
                        ? "mild (high of \(whole(max))°C), so snow may be slushy"
                        : "bitterly cold (high of \(whole(max))°C)"
                } ?? ""
            ),
            windFactor(
                weight: config.windWeight,
                speed: weather.windSpeedMax,
                gusts: weather.windGustsMax,
                speedRamp: config.windSpeed,
                gustsRamp: config.windGusts
            ),
            Factor(
                weight: config.precipitationWeight,
                score: weather.precipitationProbabilityMax.map(config.precipitationProbability.score),
                strength: "a low chance of precipitation",
                weakness: "a \(whole(weather.precipitationProbabilityMax ?? 0))% chance of precipitation"
            ),
            skiingWeatherFactor(for: weather)
        ]

        return makeScore(
            .skiing,
            date: weather.date,
            factors: factors,
            hazard: weather.condition,
            confidenceCap: confidenceCap
        )
    }

    private func skiingWeatherFactor(for weather: DailyWeatherInput) -> Factor {
        let config = configuration.skiing
        var factor = conditionFactor(
            weight: config.weatherWeight,
            condition: weather.condition,
            table: config.weatherScores
        )
        if let visibility = weather.daytimeVisibilityMin, visibility < config.poorVisibility {
            factor = Factor(
                weight: factor.weight,
                score: min(factor.score ?? config.poorVisibilityWeatherCap, config.poorVisibilityWeatherCap),
                strength: factor.strength,
                weakness: "poor visibility"
            )
        }
        return factor
    }

    // MARK: - Surfing

    func surfingScore(for weather: DailyWeatherInput, marine: DailyMarineInput?) -> ActivityScore {
        let config = configuration.surfing

        guard let marine else {
            return .unavailable(.surfing, date: weather.date, reason: "No marine forecast for this location.")
        }
        guard let waveHeight = marine.waveHeight else {
            return .unavailable(.surfing, date: weather.date, reason: "No wave data here; the location may be inland.")
        }

        let factors = [
            Factor(
                weight: config.waveHeightWeight,
                score: config.waveHeight.score(waveHeight),
                strength: "\(oneDecimal(waveHeight)) m waves",
                weakness: waveHeight < config.waveHeight.ideal.lowerBound
                    ? "small waves (\(oneDecimal(waveHeight)) m)"
                    : "big waves (\(oneDecimal(waveHeight)) m), for experts only"
            ),
            // A missing period stays missing; an ideal period is never assumed.
            Factor(
                weight: config.wavePeriodWeight,
                score: marine.wavePeriod.map(config.wavePeriod.score),
                strength: "a long \(whole(marine.wavePeriod ?? 0)) s wave period",
                weakness: "short, choppy \(whole(marine.wavePeriod ?? 0)) s waves"
            ),
            windFactor(
                weight: config.windWeight,
                speed: weather.daytimeWindSpeedAverage,
                gusts: weather.daytimeWindGustsMax,
                speedRamp: config.windSpeed,
                gustsRamp: config.windGusts
            ),
            conditionFactor(weight: config.weatherWeight, condition: weather.condition, table: config.weatherScores),
            Factor(
                weight: config.seaTemperatureWeight,
                score: marine.seaSurfaceTemperature.map(config.seaTemperature.score),
                strength: "warm water (\(whole(marine.seaSurfaceTemperature ?? 0))°C)",
                weakness: "cold water (\(whole(marine.seaSurfaceTemperature ?? 0))°C)"
            )
        ]

        // Marine models don't know tides, wind direction or local hazards, so never more than moderate.
        // Without a wave period, wave quality can't be judged, so confidence drops to low.
        let confidenceCap: ScoreConfidence = marine.hourlyCoverage < config.lowCoverage || marine.wavePeriod == nil
            ? .low
            : .moderate
        return makeScore(
            .surfing,
            date: weather.date,
            factors: factors,
            hazard: weather.condition,
            confidenceCap: confidenceCap
        )
    }

    // MARK: - Outdoor sightseeing

    func outdoorSightseeingScore(for weather: DailyWeatherInput) -> ActivityScore {
        let config = configuration.outdoorSightseeing
        let feelsLike = weather.apparentTemperatureMax ?? weather.temperatureMax
        let precipitation = mean(
            weather.precipitationProbabilityMax.map(config.precipitationProbability.score),
            weather.precipitationSum.map(config.precipitationSum.score)
        )

        guard let feelsLike, let precipitation else {
            return .unavailable(
                .outdoorSightseeing,
                date: weather.date,
                reason: "The forecast is missing temperature or precipitation."
            )
        }

        let factors = [
            Factor(
                weight: config.precipitationWeight,
                score: precipitation,
                strength: "a dry forecast",
                weakness: precipitationWeakness(for: weather)
            ),
            Factor(
                weight: config.temperatureWeight,
                score: config.temperature.score(feelsLike),
                strength: "comfortable temperatures (around \(whole(feelsLike))°C)",
                weakness: feelsLike < config.temperature.ideal.lowerBound
                    ? "chilly (feels like \(whole(feelsLike))°C)"
                    : "hot (feels like \(whole(feelsLike))°C)"
            ),
            windFactor(
                weight: config.windWeight,
                speed: weather.windSpeedMax,
                gusts: weather.windGustsMax,
                speedRamp: config.windSpeed,
                gustsRamp: config.windGusts
            ),
            Factor(
                weight: config.sunshineWeight,
                score: weather.sunshineHours.map(config.sunshineHours.score),
                strength: "\(whole(weather.sunshineHours ?? 0)) hours of sunshine",
                weakness: "little sunshine"
            ),
            conditionFactor(weight: config.weatherWeight, condition: weather.condition, table: config.weatherScores)
        ]

        return makeScore(
            .outdoorSightseeing,
            date: weather.date,
            factors: factors,
            hazard: weather.condition,
            confidenceCap: .high
        )
    }

    // MARK: - Indoor sightseeing

    /// Measures how much the weather favors being inside, on top of a nonzero baseline.
    /// Scored independently, never as 100 minus the outdoor score.
    func indoorSightseeingScore(for weather: DailyWeatherInput) -> ActivityScore {
        let config = configuration.indoorSightseeing
        let heat = weather.temperatureMax.map(config.heat.score)
        let cold = weather.temperatureMin.map(config.cold.score)
        let temperatureExtremes = [heat, cold].compactMap { $0 }.max()

        let factors = [
            Factor(
                weight: config.precipitationWeight,
                score: mean(
                    weather.precipitationProbabilityMax.map(config.precipitationProbability.score),
                    weather.precipitationSum.map(config.precipitationSum.score)
                ),
                strength: "rain likely outside",
                weakness: ""
            ),
            Factor(
                weight: config.temperatureWeight,
                score: temperatureExtremes,
                strength: (heat ?? 0) >= (cold ?? 0)
                    ? "hot outside (high of \(whole(weather.temperatureMax ?? 0))°C)"
                    : "cold outside (low of \(whole(weather.temperatureMin ?? 0))°C)",
                weakness: ""
            ),
            Factor(
                weight: config.weatherWeight,
                score: weather.condition.flatMap { config.weatherScores[$0.kind] },
                strength: "\(weather.condition?.description.lowercased() ?? "poor weather") outside",
                weakness: ""
            ),
            Factor(
                weight: config.windWeight,
                score: weather.windSpeedMax.map(config.windSpeed.score),
                strength: "windy outside",
                weakness: ""
            ),
            Factor(
                weight: config.cloudCoverWeight,
                score: weather.daytimeCloudCoverAverage.map(config.cloudCover.score),
                strength: "grey skies",
                weakness: ""
            )
        ]

        return makeScore(
            .indoorSightseeing,
            date: weather.date,
            factors: factors,
            hazard: nil,
            confidenceCap: .high,
            adjust: { config.baseline + (100 - config.baseline) * $0 / 100 },
            fallbackReason: "Always an option, though the weather suits being outside."
        )
    }

    // MARK: - Shared factors

    private func windFactor(
        weight: Double,
        speed: Double?,
        gusts: Double?,
        speedRamp: ScoreRamp,
        gustsRamp: ScoreRamp
    ) -> Factor {
        Factor(
            weight: weight,
            score: mean(speed.map(speedRamp.score), gusts.map(gustsRamp.score)),
            strength: "light wind",
            weakness: gusts.map { "gusts up to \(whole($0)) km/h" } ?? "strong wind"
        )
    }

    private func conditionFactor(
        weight: Double,
        condition: WeatherCondition?,
        table: [WeatherCondition.Kind: Double]
    ) -> Factor {
        let description = condition?.description.lowercased() ?? ""
        return Factor(
            weight: weight,
            score: condition.flatMap { table[$0.kind] },
            strength: description,
            weakness: description
        )
    }

    private func precipitationWeakness(for weather: DailyWeatherInput) -> String {
        if let probability = weather.precipitationProbabilityMax, probability >= 50 {
            return "rain likely (\(whole(probability))%)"
        }
        if let sum = weather.precipitationSum, sum > 0 {
            return "\(oneDecimal(sum)) mm of rain expected"
        }
        return "a chance of rain"
    }

    // MARK: - Combining

    private func makeScore(
        _ activity: Activity,
        date: Date,
        factors: [Factor],
        hazard: WeatherCondition?,
        confidenceCap: ScoreConfidence,
        adjust: (Double) -> Double = { $0 },
        fallbackReason: String = "Mixed conditions."
    ) -> ActivityScore {
        // activityScore = sum(subscore × weight) / sum(applicable weights)
        let totalWeight = factors.reduce(0) { $0 + $1.weight }
        let present = factors.compactMap { factor in factor.score.map { (score: $0, weight: factor.weight) } }
        let presentWeight = present.reduce(0) { $0 + $1.weight }
        let coverage = totalWeight > 0 ? presentWeight / totalWeight : 0

        guard presentWeight > 0, coverage >= configuration.minimumCoverage else {
            return .unavailable(activity, date: date, reason: "Not enough forecast data to score this day.")
        }

        var score = adjust(present.reduce(0) { $0 + $1.score * $1.weight } / presentWeight)
        var reason = Self.reason(from: factors, fallback: fallbackReason)
        if let hazard, hazard.isHazardous {
            score = min(score, configuration.hazardScoreCap)
            reason = "\(hazard.description) forecast; not safe to be out."
        }

        return ActivityScore(
            date: date,
            activity: activity,
            score: Int(score.rounded()),
            reason: reason,
            confidence: min(confidence(forCoverage: coverage), confidenceCap)
        )
    }

    private func confidence(forCoverage coverage: Double) -> ScoreConfidence {
        if coverage >= configuration.highConfidenceCoverage { return .high }
        if coverage >= configuration.moderateConfidenceCoverage { return .moderate }
        return .low
    }

    /// Names the two factors that helped most and the one that hurt most, e.g.
    /// "A dry forecast and light wind, but chilly (feels like 8°C)."
    private static func reason(from factors: [Factor], fallback: String) -> String {
        let scored: [(factor: Factor, score: Double)] = factors.compactMap { factor in
            guard let score = factor.score else { return nil }
            return (factor, score)
        }

        let helping = scored.filter { $0.score >= 70 && !$0.factor.strength.isEmpty }
        let strengths: [String] = helping
            .sorted { first, second in
                let firstContribution: Double = first.factor.weight * first.score
                let secondContribution: Double = second.factor.weight * second.score
                return firstContribution > secondContribution
            }
            .prefix(2)
            .map { $0.factor.strength }

        let hurting = scored.filter { $0.score < 40 && !$0.factor.weakness.isEmpty }
        let worst = hurting.max { first, second in
            let firstLoss: Double = first.factor.weight * (100 - first.score)
            let secondLoss: Double = second.factor.weight * (100 - second.score)
            return firstLoss < secondLoss
        }
        let weakness: String? = worst?.factor.weakness

        let sentence: String
        switch (strengths.isEmpty, weakness) {
        case (false, nil):
            sentence = strengths.joined(separator: " and ")
        case (false, let weakness?):
            sentence = strengths.joined(separator: " and ") + ", but " + weakness
        case (true, let weakness?):
            sentence = weakness
        case (true, nil):
            return fallback
        }
        return sentence.prefix(1).uppercased() + sentence.dropFirst() + "."
    }
}

/// One weighted input to an activity score.
private struct Factor {
    let weight: Double
    /// 0–100, or `nil` when the forecast doesn't include this input.
    let score: Double?
    /// Used in the reason when this factor helps, such as "light wind". Empty to never mention it.
    let strength: String
    /// Used in the reason when this factor hurts, such as "gusts up to 70 km/h". Empty to never mention it.
    let weakness: String
}

/// The mean of the values that are present, or `nil` when none are.
private func mean(_ values: Double?...) -> Double? {
    let present = values.compactMap { $0 }
    return present.isEmpty ? nil : present.reduce(0, +) / Double(present.count)
}

private func whole(_ value: Double) -> String {
    String(Int(value.rounded()))
}

private func oneDecimal(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(1)))
}
