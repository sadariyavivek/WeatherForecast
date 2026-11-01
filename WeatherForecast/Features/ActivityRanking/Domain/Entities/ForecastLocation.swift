//
//  ForecastLocation.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Where to rank activities. Supplied by the app; this feature doesn't search for places.
/// Waves are read at the same coordinates. The Marine API has no data for inland points,
/// so an inland location shows surfing as unavailable.
struct ForecastLocation: Equatable, Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
    /// IANA identifier, such as "Europe/Berlin". `nil` lets the API pick one from the coordinates.
    let timezone: String?
}
