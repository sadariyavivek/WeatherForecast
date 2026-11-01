//
//  ActivityRankingView.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import SwiftUI

/// Pushed from city search, so it lives inside that screen's `NavigationStack`.
struct ActivityRankingView: View {
    @State private var viewModel: ActivityRankingViewModel

    init(viewModel: ActivityRankingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        StateView(
            viewModel: viewModel,
            emptyTitle: "No Forecast",
            emptySystemImage: "calendar.badge.exclamationmark",
            emptyDescription: "There's no forecast for this place right now.",
            failureTitle: "Couldn't Load Forecast",
            onRetry: { await viewModel.load() }
        ) { forecast in
            List {
                if forecast.isStale {
                    Section {
                        Label(
                            "Couldn't get a newer forecast. Showing the one from \(updatedTime(forecast)).",
                            systemImage: "exclamationmark.icloud"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    }
                }
                ForEach(Array(forecast.days.enumerated()), id: \.element.id) { index, day in
                    DailyRankingSection(day: day, dayIndex: index, timeZone: forecast.timeZone)
                }
                Section {
                } footer: {
                    Text("Updated \(updatedTime(forecast)). Scores are estimates from the weather forecast, not safety ratings. Check local weather warnings and surf or snow reports before you go.")
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationTitle(viewModel.location.name)
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert(
            "Couldn't Refresh",
            isPresented: Binding(
                get: { viewModel.refreshErrorMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.dismissRefreshError() }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.refreshErrorMessage ?? "")
        }
    }

    /// In the viewer's own timezone: it's when they got the data, not a time at the destination.
    private func updatedTime(_ forecast: ActivityForecast) -> String {
        forecast.fetchedAt.formatted(date: .omitted, time: .shortened)
    }
}

#if DEBUG
private let previewLocation = ForecastLocation(
    name: "Lisbon",
    latitude: 38.71667,
    longitude: -9.13333,
    timezone: "Europe/Lisbon"
)

@MainActor
private func previewViewModel(_ scenario: StubWeatherForecastRepository.Scenario) -> ActivityRankingViewModel {
    ActivityRankingViewModel(
        location: previewLocation,
        service: ActivityRankingService(
            weatherRepository: StubWeatherForecastRepository(scenario: scenario),
            marineRepository: StubMarineForecastRepository()
        )
    )
}

#Preview("Loaded") {
    NavigationStack {
        ActivityRankingView(viewModel: previewViewModel(.success))
    }
}

#Preview("Empty") {
    NavigationStack {
        ActivityRankingView(viewModel: previewViewModel(.empty))
    }
}

#Preview("Failed") {
    NavigationStack {
        ActivityRankingView(viewModel: previewViewModel(.failure))
    }
}
#endif
