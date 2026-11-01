//
//  CityRowView.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import SwiftUI

struct CityRowView: View {
    let city: City

    /// "State of Berlin, Germany". Several cities share a name, so this tells them apart.
    private var location: String? {
        let parts = [city.region, city.country].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(city.name)
                .font(.headline)
            if let location {
                Text(location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("cityRow_\(city.id)")
    }
}

#Preview {
    List {
        CityRowView(city: City(
            id: 2950159,
            name: "Berlin",
            latitude: 52.52437,
            longitude: 13.41053,
            region: "State of Berlin",
            country: "Germany",
            timezone: "Europe/Berlin"
        ))
        CityRowView(city: City(
            id: 1,
            name: "Atlantis",
            latitude: 0,
            longitude: 0,
            region: nil,
            country: nil,
            timezone: nil
        ))
    }
}
