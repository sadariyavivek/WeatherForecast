//
//  WeatherCondition.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Every WMO weather code Open-Meteo returns. `init(rawValue:)` is `nil` for an unknown code,
/// which callers treat as missing data, never as clear weather.
enum WeatherCondition: Int, CaseIterable, Sendable {
    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case lightDrizzle = 51
    case moderateDrizzle = 53
    case denseDrizzle = 55
    case lightFreezingDrizzle = 56
    case denseFreezingDrizzle = 57
    case slightRain = 61
    case moderateRain = 63
    case heavyRain = 65
    case lightFreezingRain = 66
    case heavyFreezingRain = 67
    case slightSnowfall = 71
    case moderateSnowfall = 73
    case heavySnowfall = 75
    case snowGrains = 77
    case slightRainShowers = 80
    case moderateRainShowers = 81
    case violentRainShowers = 82
    case slightSnowShowers = 85
    case heavySnowShowers = 86
    case thunderstorm = 95
    case thunderstormWithSlightHail = 96
    case thunderstormWithHeavyHail = 99

    /// Groups codes that affect activities the same way. Scoring tables are keyed by this.
    enum Kind: CaseIterable, Sendable {
        case clear
        case partlyCloudy
        case overcast
        case fog
        case drizzle
        case rain
        case heavyRain
        case freezing
        case snow
        case heavySnow
        case thunderstorm
    }

    var kind: Kind {
        switch self {
        case .clearSky, .mainlyClear:
            return .clear
        case .partlyCloudy:
            return .partlyCloudy
        case .overcast:
            return .overcast
        case .fog, .depositingRimeFog:
            return .fog
        case .lightDrizzle, .moderateDrizzle, .denseDrizzle:
            return .drizzle
        case .slightRain, .moderateRain, .slightRainShowers, .moderateRainShowers:
            return .rain
        case .heavyRain, .violentRainShowers:
            return .heavyRain
        case .lightFreezingDrizzle, .denseFreezingDrizzle, .lightFreezingRain, .heavyFreezingRain:
            return .freezing
        case .slightSnowfall, .moderateSnowfall, .snowGrains, .slightSnowShowers:
            return .snow
        case .heavySnowfall, .heavySnowShowers:
            return .heavySnow
        case .thunderstorm, .thunderstormWithSlightHail, .thunderstormWithHeavyHail:
            return .thunderstorm
        }
    }

    /// Conditions where outdoor activities may be unsafe, whatever the other factors say.
    var isHazardous: Bool {
        kind == .freezing || kind == .thunderstorm
    }

    var description: String {
        switch self {
        case .clearSky: return "Clear sky"
        case .mainlyClear: return "Mainly clear"
        case .partlyCloudy: return "Partly cloudy"
        case .overcast: return "Overcast"
        case .fog: return "Fog"
        case .depositingRimeFog: return "Rime fog"
        case .lightDrizzle: return "Light drizzle"
        case .moderateDrizzle: return "Drizzle"
        case .denseDrizzle: return "Dense drizzle"
        case .lightFreezingDrizzle: return "Light freezing drizzle"
        case .denseFreezingDrizzle: return "Freezing drizzle"
        case .slightRain: return "Light rain"
        case .moderateRain: return "Rain"
        case .heavyRain: return "Heavy rain"
        case .lightFreezingRain: return "Light freezing rain"
        case .heavyFreezingRain: return "Freezing rain"
        case .slightSnowfall: return "Light snow"
        case .moderateSnowfall: return "Snow"
        case .heavySnowfall: return "Heavy snow"
        case .snowGrains: return "Snow grains"
        case .slightRainShowers: return "Light showers"
        case .moderateRainShowers: return "Rain showers"
        case .violentRainShowers: return "Violent rain showers"
        case .slightSnowShowers: return "Snow showers"
        case .heavySnowShowers: return "Heavy snow showers"
        case .thunderstorm: return "Thunderstorm"
        case .thunderstormWithSlightHail: return "Thunderstorm with hail"
        case .thunderstormWithHeavyHail: return "Thunderstorm with heavy hail"
        }
    }
}
