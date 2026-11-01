//
//  ActivityRankingViewModel.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation
import Observation

@MainActor
@Observable
final class ActivityRankingViewModel: StatefulViewModel {
    private(set) var state: ViewState<ActivityForecast> = .idle

    /// Set when a pull-to-refresh fails while rankings are on screen.
    /// The rankings stay visible; the view shows this as a dismissible alert.
    private(set) var refreshErrorMessage: String?

    let location: ForecastLocation

    @ObservationIgnored private let service: ActivityRankingServiceProtocol

    /// Covers both `load()` and `refresh()`, so only one request runs at a time.
    @ObservationIgnored private var isFetching = false

    init(location: ForecastLocation, service: ActivityRankingServiceProtocol) {
        self.location = location
        self.service = service
    }

    /// First appearance: fetches only if nothing has been loaded yet,
    /// so returning to the screen doesn't flash a spinner or refetch.
    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    /// Initial load and retry: shows the loading state while fetching.
    func load() async {
        // Ignore a second call while a request is already in flight.
        guard !isFetching else { return }

        let previousState = state
        state = .loading
        await fetchRankings(restoringOnCancel: previousState)
    }

    /// Pull-to-refresh: keeps the current rankings on screen while fetching.
    func refresh() async {
        guard !isFetching else { return }

        await fetchRankings(restoringOnCancel: state)
    }

    func dismissRefreshError() {
        refreshErrorMessage = nil
    }

    private func fetchRankings(restoringOnCancel previousState: ViewState<ActivityForecast>) async {
        isFetching = true
        defer { isFetching = false }
        refreshErrorMessage = nil

        do {
            let forecast = try await service.rankActivities(for: location)
            state = forecast.days.isEmpty ? .empty : .loaded(forecast)
        } catch is CancellationError {
            // The view went away mid-request. Restore the old state so the next load can run.
            state = previousState
        } catch {
            let message = error.userMessage
            if case .loaded = previousState {
                // A failed refresh keeps the rankings on screen.
                state = previousState
                refreshErrorMessage = message
            } else {
                state = .failed(message: message)
            }
        }
    }
}
