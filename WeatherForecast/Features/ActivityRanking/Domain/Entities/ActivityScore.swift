//
//  ActivityScore.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

enum ScoreAvailability: Sendable {
    case available
    /// A critical input is missing. Different from a score of zero.
    case unavailable
}

/// How complete and trustworthy the inputs were. Kept separate from suitability.
/// Declared lowest first, so `min(_:_:)` picks the weaker confidence.
enum ScoreConfidence: Comparable, Sendable {
    case low
    case moderate
    case high
}

struct ActivityScore: Identifiable, Equatable, Sendable {
    let date: Date
    let activity: Activity
    /// 0–100, or `nil` when unavailable.
    let score: Int?
    let reason: String
    let confidence: ScoreConfidence

    var id: String { "\(activity.rawValue)-\(date.timeIntervalSince1970)" }

    /// Derived from `score`, so the two can never disagree.
    var availability: ScoreAvailability { score == nil ? .unavailable : .available }

    static func unavailable(_ activity: Activity, date: Date, reason: String) -> ActivityScore {
        ActivityScore(date: date, activity: activity, score: nil, reason: reason, confidence: .low)
    }
}

/// Every activity's result for one local forecast date.
struct DailyActivityRanking: Identifiable, Equatable, Sendable {
    let date: Date
    let weather: DailyWeatherInput
    /// Available activities, best first. An activity's rank is its position plus one.
    let rankedActivities: [ActivityScore]
    /// Kept apart so they never receive a rank.
    let unavailableActivities: [ActivityScore]

    var id: Date { date }

    init(date: Date, weather: DailyWeatherInput, scores: [ActivityScore]) {
        self.date = date
        self.weather = weather
        rankedActivities = scores
            .filter { $0.availability == .available }
            .sorted { first, second in
                let firstScore = first.score ?? -1
                let secondScore = second.score ?? -1
                if firstScore != secondScore {
                    return firstScore > secondScore
                }
                // Equal scores use ordinal positions, ordered by name so the result never changes between runs.
                return first.activity.rawValue < second.activity.rawValue
            }
        unavailableActivities = scores.filter { $0.availability == .unavailable }
    }
}

/// The whole screen's data: up to seven ranked days in the location's timezone.
struct ActivityForecast: Equatable, Sendable {
    /// Dates are local midnights in this timezone, so format them with it too.
    let timeZone: TimeZone
    let days: [DailyActivityRanking]
    /// When the underlying weather forecast came from the API.
    let fetchedAt: Date
    /// `true` when a refresh failed and an older cached forecast is shown instead.
    let isStale: Bool
}
