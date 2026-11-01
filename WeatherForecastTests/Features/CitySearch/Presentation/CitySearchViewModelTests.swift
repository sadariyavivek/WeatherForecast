//
//  CitySearchViewModelTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

@MainActor
final class CitySearchViewModelTests: XCTestCase {

    private func makeSUT(
        _ repository: MockCityRepository = MockCityRepository(result: .success([.stub()]))
    ) -> CitySearchViewModel {
        CitySearchViewModel(
            repository: repository,
            activityRankingService: MockActivityRankingService(result: .success(.stub())),
            debounce: .zero
        )
    }

    // MARK: - Initial state

    func test_init_stateIsIdle_andDoesNotSearch() {
        let repository = MockCityRepository(result: .success([]))
        let sut = makeSUT(repository)

        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(repository.searchedNames.isEmpty)
    }

    // MARK: - Query length

    func test_search_withQueryShorterThanMinimum_staysIdle_andDoesNotSearch() async {
        let repository = MockCityRepository(result: .success([.stub()]))
        let sut = makeSUT(repository)
        sut.query = "B"

        await sut.search()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(repository.searchedNames.isEmpty)
    }

    func test_search_trimsWhitespaceBeforeSearching() async {
        let repository = MockCityRepository(result: .success([.stub()]))
        let sut = makeSUT(repository)
        sut.query = "  Berlin \n"

        await sut.search()

        XCTAssertEqual(repository.searchedNames, ["Berlin"])
    }

    func test_search_afterClearingQuery_returnsToIdle() async {
        let sut = makeSUT()
        sut.query = "Berlin"
        await sut.search()

        sut.query = ""
        await sut.search()

        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Results

    func test_search_withCities_setsLoadedState() async {
        let cities = [City.stub(), .stub(id: 5083330, region: "New Hampshire", country: "United States")]
        let sut = makeSUT(MockCityRepository(result: .success(cities)))
        sut.query = "Berlin"

        await sut.search()

        XCTAssertEqual(sut.state, .loaded(cities))
    }

    func test_search_withNoCities_setsEmptyState() async {
        let sut = makeSUT(MockCityRepository(result: .success([])))
        sut.query = "Nowhere"

        await sut.search()

        XCTAssertEqual(sut.state, .empty)
    }

    func test_search_setsLoadingStateWhileFetching() async {
        let repository = MockCityRepository(result: .success([]))
        let sut = makeSUT(repository)
        var stateDuringFetch: ViewState<[City]>?
        repository.searchHandler = { _ in
            stateDuringFetch = sut.state
            return [.stub()]
        }
        sut.query = "Berlin"

        await sut.search()

        XCTAssertEqual(stateDuringFetch, .loading)
    }

    func test_search_whenFails_setsFailedStateWithUserMessage() async {
        let sut = makeSUT(MockCityRepository(result: .failure(NetworkError.transport(.notConnectedToInternet))))
        sut.query = "Berlin"

        await sut.search()

        XCTAssertEqual(sut.state, .failed(message: "You're offline. Check your connection and try again."))
    }

    func test_search_afterFailure_retrySucceeds() async {
        let repository = MockCityRepository(result: .failure(NetworkError.transport(.timedOut)))
        let sut = makeSUT(repository)
        sut.query = "Berlin"
        await sut.search()

        repository.searchHandler = { _ in [.stub()] }
        await sut.search()

        XCTAssertEqual(sut.state, .loaded([.stub()]))
    }

    // MARK: - Debounce and cancellation

    func test_queryDidChange_searchesAfterDebounce() async {
        let repository = MockCityRepository(result: .success([.stub()]))
        let sut = makeSUT(repository)
        sut.query = "Berlin"

        await sut.queryDidChange()

        XCTAssertEqual(repository.searchedNames, ["Berlin"])
        XCTAssertEqual(sut.state, .loaded([.stub()]))
    }

    func test_queryDidChange_cancelledDuringDebounce_doesNotSearch() async {
        let repository = MockCityRepository(result: .success([.stub()]))
        let sut = CitySearchViewModel(
            repository: repository,
            activityRankingService: MockActivityRankingService(result: .success(.stub())),
            debounce: .seconds(60)
        )
        sut.query = "Berlin"

        let typing = Task { await sut.queryDidChange() }
        typing.cancel()
        await typing.value

        XCTAssertTrue(repository.searchedNames.isEmpty)
        XCTAssertEqual(sut.state, .idle)
    }

    func test_search_whenReplacedByNewerQuery_keepsLoadingInsteadOfFailing() async {
        let repository = MockCityRepository(result: .failure(CancellationError()))
        let sut = makeSUT(repository)
        sut.query = "Ber"

        await sut.search()

        // The newer query's search sets the final state, so a cancelled one leaves it alone.
        XCTAssertEqual(sut.state, .loading)
    }

    // MARK: - Navigation

    func test_makeActivityRankingViewModel_passesCityAsForecastLocation() {
        let sut = makeSUT()

        let rankingViewModel = sut.makeActivityRankingViewModel(for: .stub())

        XCTAssertEqual(rankingViewModel.location, .berlin)
        XCTAssertEqual(rankingViewModel.state, .idle)
    }
}
