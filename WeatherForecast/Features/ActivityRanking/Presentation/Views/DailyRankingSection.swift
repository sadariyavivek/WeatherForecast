//
//  DailyRankingSection.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import SwiftUI

/// One forecast date: a weather summary, ranked activities, then unavailable ones without a rank.
struct DailyRankingSection: View {
    let day: DailyActivityRanking
    /// Position in the forecast, 0 for the first day. Keeps row identifiers unique across days for UI tests.
    let dayIndex: Int
    /// The forecast's timezone. Dates are local midnights there, so they must be formatted with it.
    let timeZone: TimeZone

    private var title: String {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        if calendar.isDateInToday(day.date) { return "Today" }
        if calendar.isDateInTomorrow(day.date) { return "Tomorrow" }

        var format = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
        format.timeZone = timeZone
        return day.date.formatted(format)
    }

    var body: some View {
        Section {
            DailyWeatherSummaryView(weather: day.weather)
            ForEach(Array(day.rankedActivities.enumerated()), id: \.element.id) { index, score in
                ActivityScoreRow(score: score, rank: index + 1)
                    .accessibilityIdentifier(rowIdentifier(for: score))
            }
            ForEach(day.unavailableActivities) { score in
                ActivityScoreRow(score: score, rank: nil)
                    .accessibilityIdentifier(rowIdentifier(for: score))
            }
        } header: {
            Text(title)
        }
    }

    /// For example "activityRow_0_surfing" for surfing on the first day.
    private func rowIdentifier(for score: ActivityScore) -> String {
        "activityRow_\(dayIndex)_\(score.activity.rawValue)"
    }
}

struct DailyWeatherSummaryView: View {
    let weather: DailyWeatherInput

    private var details: String {
        var parts: [String] = []
        if let max = weather.temperatureMax, let min = weather.temperatureMin {
            parts.append("H \(Int(max.rounded()))°  L \(Int(min.rounded()))°")
        }
        if let probability = weather.precipitationProbabilityMax {
            parts.append("\(Int(probability.rounded()))% rain")
        }
        if let wind = weather.windSpeedMax {
            parts.append("Wind \(Int(wind.rounded())) km/h")
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: weather.condition?.systemImage ?? "questionmark.circle")
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(weather.condition?.description ?? "Unknown conditions")
                    .font(.subheadline.weight(.semibold))
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
