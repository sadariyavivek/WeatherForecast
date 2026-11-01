//
//  Activity.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

enum Activity: String, Codable, CaseIterable, Identifiable, Sendable {
    case skiing
    case surfing
    case outdoorSightseeing
    case indoorSightseeing

    var id: String { rawValue }
}
