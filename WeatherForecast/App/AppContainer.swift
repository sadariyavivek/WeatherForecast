//
//  AppContainer.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

/// Composition root: the one place that picks concrete implementations.
@MainActor
struct AppContainer {
    let cityRepository: CityRepository
    let activityRankingService: ActivityRankingServiceProtocol

    static func make(launchArguments: [String] = ProcessInfo.processInfo.arguments) -> AppContainer {
        #if DEBUG
        if let cityStub = StubCityRepository(launchArguments: launchArguments),
           let weatherStub = StubWeatherForecastRepository(launchArguments: launchArguments) {
            return AppContainer(
                cityRepository: cityStub,
                activityRankingService: ActivityRankingService(
                    weatherRepository: weatherStub,
                    marineRepository: StubMarineForecastRepository()
                )
            )
        }
        #endif
        // Each Open-Meteo API has its own host, so each module gets its own NetworkManager.
        // The cached repositories are created once here, so every ranking screen shares their caches.
        return AppContainer(
            cityRepository: RemoteCityRepository(api: NetworkManager(baseURL: APIBaseURL.geocoding)),
            activityRankingService: ActivityRankingService(
                weatherRepository: CachedWeatherForecastRepository(
                    wrapping: RemoteWeatherForecastRepository(api: NetworkManager(baseURL: APIBaseURL.forecast))
                ),
                marineRepository: CachedMarineForecastRepository(
                    wrapping: RemoteMarineForecastRepository(api: NetworkManager(baseURL: APIBaseURL.marine))
                )
            )
        )
    }

    func makeCitySearchViewModel() -> CitySearchViewModel {
        CitySearchViewModel(repository: cityRepository, activityRankingService: activityRankingService)
    }
}
