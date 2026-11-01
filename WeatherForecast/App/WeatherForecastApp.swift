//
//  WeatherForecastApp.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//

import SwiftUI

@main
struct WeatherForecastApp: App {
    private let container = AppContainer.make()

    var body: some Scene {
        WindowGroup {
            CitySearchView(viewModel: container.makeCitySearchViewModel())
        }
    }
}
