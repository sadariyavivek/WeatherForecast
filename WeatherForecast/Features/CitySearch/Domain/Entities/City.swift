//
//  City.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Domain entity. Independent of the API's JSON shape.
struct City: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    /// State or province, such as "California". Not every place has one.
    let region: String?
    let country: String?
    /// IANA identifier, such as "Europe/Berlin". The forecast API needs it for local times.
    let timezone: String?
}
