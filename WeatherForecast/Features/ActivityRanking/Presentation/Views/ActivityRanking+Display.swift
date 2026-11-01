//
//  ActivityRanking+Display.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

// Display text and SF Symbols, kept out of the domain types.

extension Activity {
    var title: String {
        switch self {
        case .skiing: return "Skiing"
        case .surfing: return "Surfing"
        case .outdoorSightseeing: return "Outdoor sightseeing"
        case .indoorSightseeing: return "Indoor sightseeing"
        }
    }

    var systemImage: String {
        switch self {
        case .skiing: return "figure.skiing.downhill"
        case .surfing: return "figure.surfing"
        case .outdoorSightseeing: return "binoculars.fill"
        case .indoorSightseeing: return "building.columns.fill"
        }
    }
}

extension ScoreConfidence {
    var title: String {
        switch self {
        case .high: return "High confidence"
        case .moderate: return "Moderate confidence"
        case .low: return "Low confidence"
        }
    }
}

extension WeatherCondition {
    var systemImage: String {
        switch kind {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .fog: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .freezing: return "cloud.sleet.fill"
        case .snow, .heavySnow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        }
    }
}
