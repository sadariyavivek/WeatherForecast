//
//  RemoteCityRepository.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

final class RemoteCityRepository: CityRepository {
    private let api: NetworkManagerProtocol

    init(api: NetworkManagerProtocol) {
        self.api = api
    }

    func searchCities(name: String) async throws -> [City] {
        let response: CitySearchResponseDTO = try await api.request(GeocodingEndpoint.searchCities(name: name))
        return response.results.map { $0.toDomain() }
    }
}
