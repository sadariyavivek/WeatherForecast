//
//  CitySearchResponseDTO.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//

struct CitySearchResponseDTO: Decodable {
    let results: [CityDTO]

    private enum CodingKeys: String, CodingKey {
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Open-Meteo leaves out `results` entirely when nothing matches, so a missing key means no cities.
        // Malformed cities are dropped instead of failing the whole list.
        results = try container
            .decodeIfPresent([LossyCityDTO].self, forKey: .results)?
            .compactMap(\.city) ?? []
    }
}

/// Decodes one array element, yielding `nil` instead of throwing when it's malformed.
private struct LossyCityDTO: Decodable {
    let city: CityDTO?

    init(from decoder: Decoder) throws {
        city = try? CityDTO(from: decoder)
    }
}
