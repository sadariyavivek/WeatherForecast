//
//  ActivityScoreRow.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import SwiftUI

struct ActivityScoreRow: View {
    let score: ActivityScore
    /// `nil` for unavailable activities, which are never ranked.
    let rank: Int?

    private var scoreColor: Color {
        switch score.score ?? 0 {
        case 70...: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(rank.map(String.init) ?? "–")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(rank == 1 ? Color.white : Color.primary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(rank == 1 ? Color.accentColor : Color.secondary.opacity(0.15)))

            Image(systemName: score.activity.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(score.activity.title)
                    .font(.headline)
                Text(score.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if let value = score.score {
                    Text("\(value)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(scoreColor)
                    Text(score.confidence.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(score.availability == .unavailable ? 0.6 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let rank, let value = score.score else {
            return "\(score.activity.title), unavailable. \(score.reason)"
        }
        return "Rank \(rank), \(score.activity.title), score \(value) out of 100, \(score.confidence.title). \(score.reason)"
    }
}

#Preview {
    let date = Date.now
    List {
        ActivityScoreRow(
            score: ActivityScore(
                date: date,
                activity: .outdoorSightseeing,
                score: 88,
                reason: "A dry forecast and light wind.",
                confidence: .high
            ),
            rank: 1
        )
        ActivityScoreRow(
            score: .unavailable(.surfing, date: date, reason: "No wave data here; the location may be inland."),
            rank: nil
        )
    }
}
