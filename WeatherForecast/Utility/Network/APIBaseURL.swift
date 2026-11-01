//
//  APIBaseURL.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

/// Base URL for each backend module. Open-Meteo serves each API from its own host,
/// so `AppContainer` gives each module a `NetworkManager` built with its own URL.
///
/// The values live in the app target's Build Settings › User-Defined
/// (`GEOCODING_API_BASE_URL`, `FORECAST_API_BASE_URL`, `MARINE_API_BASE_URL`),
/// so each build configuration can point somewhere else. `Info.plist` passes them through.
enum APIBaseURL {
    /// City search, e.g. `/search?name=Berlin`.
    static let geocoding = url(forInfoKey: "GeocodingAPIBaseURL")
    /// Weather forecast, e.g. `/forecast?latitude=52.52&longitude=13.41`.
    static let forecast = url(forInfoKey: "ForecastAPIBaseURL")
    /// Waves and sea temperature, e.g. `/marine?latitude=38.7&longitude=-9.2`.
    static let marine = url(forInfoKey: "MarineAPIBaseURL")

    /// A missing or malformed value is a build configuration mistake, so it stops the app
    /// right away instead of failing every request later.
    private static func url(forInfoKey key: String, in bundle: Bundle = .main) -> URL {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: value),
              url.scheme == "https",
              url.host != nil else {
            fatalError("\(key) is missing or invalid in Info.plist. Set it in Build Settings › User-Defined.")
        }
        return url
    }
}
