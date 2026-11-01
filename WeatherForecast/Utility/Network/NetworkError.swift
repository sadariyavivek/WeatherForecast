//
//  NetworkError.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//
import Foundation

enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidParameters
    case invalidHTTPResponse
    case badStatusCode(Int)
    case decodingFailed(String)
    case transport(URLError.Code)
}
