//
//  CitySearchView.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import SwiftUI

struct CitySearchView: View {
    @State private var viewModel: CitySearchViewModel

    init(viewModel: CitySearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Weather")
                .searchable(text: $viewModel.query, prompt: "Search for a city")
                .autocorrectionDisabled()
                .task(id: viewModel.query) {
                    await viewModel.queryDidChange()
                }
                .navigationDestination(for: City.self) { city in
                    ActivityRankingView(viewModel: viewModel.makeActivityRankingViewModel(for: city))
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if case .idle = viewModel.state {
            // StateView shows a spinner for `.idle`; here it means "nothing typed yet".
            ContentUnavailableView(
                "Search for a City",
                systemImage: "magnifyingglass",
                description: Text("Enter at least \(CitySearchViewModel.minimumQueryLength) letters of a city name.")
            )
        } else {
            StateView(
                viewModel: viewModel,
                emptyTitle: "No Cities Found",
                emptySystemImage: "mappin.slash",
                emptyDescription: "Check the spelling or try another name.",
                failureTitle: "Couldn't Search Cities",
                onRetry: { await viewModel.search() }
            ) { cities in
                List(cities) { city in
                    NavigationLink(value: city) {
                        CityRowView(city: city)
                    }
                }
            }
        }
    }
}

#if DEBUG
@MainActor
private func previewViewModel(_ scenario: StubCityRepository.Scenario) -> CitySearchViewModel {
    CitySearchViewModel(
        repository: StubCityRepository(scenario: scenario),
        activityRankingService: ActivityRankingService(
            weatherRepository: StubWeatherForecastRepository(scenario: .success),
            marineRepository: StubMarineForecastRepository()
        )
    )
}

#Preview("Loaded") {
    CitySearchView(viewModel: previewViewModel(.success))
}

#Preview("Empty") {
    CitySearchView(viewModel: previewViewModel(.empty))
}

#Preview("Failed") {
    CitySearchView(viewModel: previewViewModel(.failure))
}
#endif
