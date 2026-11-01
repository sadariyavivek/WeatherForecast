//
//  CitySearchViewModel.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation
import Observation

@MainActor
@Observable
final class CitySearchViewModel: StatefulViewModel {
    /// Open-Meteo returns nothing for one character and fuzzy matches from two.
    static let minimumQueryLength = 2

    /// `.idle` means there's no query long enough to search yet.
    private(set) var state: ViewState<[City]> = .idle

    var query = ""

    @ObservationIgnored private let repository: CityRepository
    @ObservationIgnored private let activityRankingService: ActivityRankingServiceProtocol
    @ObservationIgnored private let debounce: Duration

    init(
        repository: CityRepository,
        activityRankingService: ActivityRankingServiceProtocol,
        debounce: Duration = .milliseconds(500)
    ) {
        self.repository = repository
        self.activityRankingService = activityRankingService
        self.debounce = debounce
    }

    /// The screen pushed when a city is tapped.
    func makeActivityRankingViewModel(for city: City) -> ActivityRankingViewModel {
        let location = ForecastLocation(
            name: city.name,
            latitude: city.latitude,
            longitude: city.longitude,
            timezone: city.timezone
        )
        return ActivityRankingViewModel(location: location, service: activityRankingService)
    }

    /// Called on every keystroke. Waits for typing to pause before searching.
    /// The view runs this in `.task(id: query)`, which cancels the previous call when the query changes.
    func queryDidChange() async {
        do {
            try await Task.sleep(for: debounce)
        } catch {
            return
        }
        await search()
    }

    /// Searches right away. Also used by Retry.
    func search() async {
        let name = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= Self.minimumQueryLength else {
            state = .idle
            return
        }

        state = .loading
        do {
            let cities = try await repository.searchCities(name: name)
            // A newer query took over while this one was in flight; its results win.
            guard !Task.isCancelled else { return }
            state = cities.isEmpty ? .empty : .loaded(cities)
        } catch is CancellationError {
            // Replaced by a newer query, which sets the state itself.
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(message: error.userMessage)
        }
    }
}
