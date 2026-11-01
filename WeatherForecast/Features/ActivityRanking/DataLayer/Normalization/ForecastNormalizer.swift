//
//  ForecastNormalizer.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

/// Turns Open-Meteo's parallel arrays into one record per local forecast date.
///
/// Requests name a timezone, so every timestamp in a response is already local:
/// "2026-11-01T23:00" belongs to November 1 at the destination whatever the UTC date is.
/// Hours are grouped by that local date string, never by UTC.
enum ForecastNormalizer {
    /// Local hours (07:00–19:59) used for daytime values: sightseeing, surfing, clouds and visibility.
    static let daytimeHours = 7...19

    static func weatherForecast(from response: ForecastResponseDTO) throws -> WeatherForecast {
        let timeZone = try timeZone(identifier: response.timezone, utcOffsetSeconds: response.utcOffsetSeconds)
        guard let daily = response.daily else {
            throw NetworkError.decodingFailed("Forecast response has no daily section")
        }

        let calendar = calendar(in: timeZone)
        let hourly = response.hourly
        let hoursByDate = hourSlotsByDate(hourly?.time ?? [])

        let days = daily.time.indices.compactMap { index -> DailyWeatherInput? in
            let day = daily.time[index]
            guard let date = localDate(day, calendar: calendar) else { return nil }
            let allHours = (hoursByDate[day] ?? []).map(\.index)
            let daytime = (hoursByDate[day] ?? []).filter { daytimeHours.contains($0.hour) }.map(\.index)

            return DailyWeatherInput(
                date: date,
                condition: element(daily.weatherCode, index).flatMap(WeatherCondition.init(rawValue:)),
                temperatureMax: element(daily.temperatureMax, index),
                temperatureMin: element(daily.temperatureMin, index),
                apparentTemperatureMax: element(daily.apparentTemperatureMax, index),
                precipitationProbabilityMax: element(daily.precipitationProbabilityMax, index),
                precipitationSum: element(daily.precipitationSum, index),
                snowfallSum: element(daily.snowfallSum, index),
                sunshineDuration: element(daily.sunshineDuration, index),
                windSpeedMax: element(daily.windSpeedMax, index),
                windGustsMax: element(daily.windGustsMax, index),
                snowDepthMax: mostlyPresent(hourly?.snowDepth, at: allHours).flatMap { $0.max() },
                hourlySnowfallSum: mostlyPresent(hourly?.snowfall, at: allHours).map { $0.reduce(0, +) },
                daytimeCloudCoverAverage: mostlyPresent(hourly?.cloudCover, at: daytime).map(mean),
                daytimeVisibilityMin: mostlyPresent(hourly?.visibility, at: daytime).flatMap { $0.min() },
                daytimeWindSpeedAverage: mostlyPresent(hourly?.windSpeed, at: daytime).map(mean),
                daytimeWindGustsMax: mostlyPresent(hourly?.windGusts, at: daytime).flatMap { $0.max() }
            )
        }

        return WeatherForecast(timeZone: timeZone, days: days)
    }

    static func marineForecast(from response: MarineResponseDTO) throws -> [DailyMarineInput] {
        let timeZone = try timeZone(identifier: response.timezone, utcOffsetSeconds: response.utcOffsetSeconds)
        guard let hourly = response.hourly else { return [] }

        let calendar = calendar(in: timeZone)
        return hourSlotsByDate(hourly.time)
            .sorted { $0.key < $1.key }
            .compactMap { day, slots -> DailyMarineInput? in
                guard let date = localDate(day, calendar: calendar) else { return nil }
                let daytime = slots.filter { daytimeHours.contains($0.hour) }.map(\.index)
                guard !daytime.isEmpty else { return nil }

                let waveHeights = present(hourly.waveHeight, at: daytime)
                // A representative period, not the longest reading. Swell period is the fallback.
                let periods = mostlyPresent(hourly.wavePeriod, at: daytime)
                    ?? mostlyPresent(hourly.swellWavePeriod, at: daytime)

                return DailyMarineInput(
                    date: date,
                    waveHeight: waveHeights.isEmpty ? nil : median(waveHeights),
                    wavePeriod: periods.map(median),
                    seaSurfaceTemperature: mostlyPresent(hourly.seaSurfaceTemperature, at: daytime).map(mean),
                    hourlyCoverage: Double(waveHeights.count) / Double(daytime.count)
                )
            }
    }

    // MARK: - Timezone and dates

    /// Uses the response's named timezone. If it's missing or unknown, falls back to the fixed UTC offset
    /// the API reports, which keeps dates local but ignores a daylight saving change during the week.
    private static func timeZone(identifier: String?, utcOffsetSeconds: Int?) throws -> TimeZone {
        if let identifier, let timeZone = TimeZone(identifier: identifier) {
            return timeZone
        }
        if let utcOffsetSeconds, let timeZone = TimeZone(secondsFromGMT: utcOffsetSeconds) {
            return timeZone
        }
        throw NetworkError.decodingFailed("Forecast response has no timezone")
    }

    private static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// "2026-11-01" → local midnight of that date in `calendar`'s timezone.
    private static func localDate(_ text: String, calendar: Calendar) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private struct HourSlot {
        let index: Int
        let hour: Int
    }

    /// Groups hourly array indices by local date string, such as "2026-11-01".
    private static func hourSlotsByDate(_ times: [String]) -> [String: [HourSlot]] {
        var slots: [String: [HourSlot]] = [:]
        for (index, time) in times.enumerated() {
            let parts = time.split(separator: "T")
            guard parts.count == 2, let hour = Int(parts[1].prefix(2)) else { continue }
            slots[String(parts[0]), default: []].append(HourSlot(index: index, hour: hour))
        }
        return slots
    }

    // MARK: - Arrays

    /// The value at `index`, or `nil` when the array is missing, too short, or holds `null` there.
    private static func element<Value>(_ array: [Value?]?, _ index: Int) -> Value? {
        guard let array, array.indices.contains(index) else { return nil }
        return array[index]
    }

    /// The non-null values at `indices`.
    private static func present(_ array: [Double?]?, at indices: [Int]) -> [Double] {
        indices.compactMap { element(array, $0) }
    }

    /// The non-null values at `indices`, or `nil` when fewer than half are present,
    /// so a few stray readings never stand in for a whole day.
    private static func mostlyPresent(_ array: [Double?]?, at indices: [Int]) -> [Double]? {
        guard !indices.isEmpty else { return nil }
        let values = present(array, at: indices)
        return values.count * 2 >= indices.count && !values.isEmpty ? values : nil
    }

    private static func mean(_ values: [Double]) -> Double {
        values.reduce(0, +) / Double(values.count)
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
