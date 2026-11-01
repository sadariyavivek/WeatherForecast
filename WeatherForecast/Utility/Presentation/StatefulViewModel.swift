//
//  StatefulViewModel.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//
import Observation

/// A view model that exposes a single `ViewState`.
/// How it loads is up to each view model, so no load method is required here.
@MainActor
protocol StatefulViewModel: AnyObject, Observable {
    associatedtype Value

    var state: ViewState<Value> { get }
}
