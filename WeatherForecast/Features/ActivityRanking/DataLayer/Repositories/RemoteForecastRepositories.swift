//
//  RemoteForecastRepositories.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

/// Talks to the Forecast API. Give it a `NetworkManager` built with `APIBaseURL.forecast`.
final class RemoteWeatherForecastRepository: WeatherForecastRepository {
    private let api: NetworkManagerProtocol

    init(api: NetworkManagerProtocol) {
        self.api = api
    }

    func weatherForecast(for location: ForecastLocation) async throws -> WeatherForecast {
        let response: ForecastResponseDTO = try await api.request(
            ForecastEndpoint.sevenDayForecast(
                latitude: location.latitude,
                longitude: location.longitude,
                timezone: location.timezone
            )
        )
        return try ForecastNormalizer.weatherForecast(from: response)
    }
}

/// Talks to the Marine API. Give it a `NetworkManager` built with `APIBaseURL.marine`.
final class RemoteMarineForecastRepository: MarineForecastRepository {
    private let api: NetworkManagerProtocol

    init(api: NetworkManagerProtocol) {
        self.api = api
    }

    func marineForecast(for location: ForecastLocation) async throws -> [DailyMarineInput] {
        let response: MarineResponseDTO = try await api.request(
            MarineEndpoint.sevenDayForecast(
                latitude: location.latitude,
                longitude: location.longitude,
                timezone: location.timezone
            )
        )
        return try ForecastNormalizer.marineForecast(from: response)
    }
}
