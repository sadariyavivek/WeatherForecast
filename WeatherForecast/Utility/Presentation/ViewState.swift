//
//  ViewState.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//

/// Screen state shared by every feature. `Value` is whatever the loaded screen renders.
enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(message: String)
}

extension ViewState: Equatable where Value: Equatable {}
