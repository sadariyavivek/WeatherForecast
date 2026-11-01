//
//  ActivityRankingViewModelTests.swift
//  WeatherForecastTests
//
//  Created by Vivek Sadariya on 01/11/26.
//
import XCTest
@testable import WeatherForecast

@MainActor
final class ActivityRankingViewModelTests: XCTestCase {

    private func makeSUT(_ service: MockActivityRankingService) -> ActivityRankingViewModel {
        ActivityRankingViewModel(location: .berlin, service: service)
    }

    // MARK: - Initial state

    func test_init_stateIsIdle_andDoesNotFetch() {
        let service = MockActivityRankingService(result: .success(.stub()))
        let sut = makeSUT(service)

        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(service.requestedLocations.isEmpty)
    }

    // MARK: - Load

    func test_load_withDays_setsLoadedStateForItsLocation() async {
        let service = MockActivityRankingService(result: .success(.stub(dayCount: 3)))
        let sut = makeSUT(service)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded(.stub(dayCount: 3)))
        XCTAssertEqual(service.requestedLocations, [.berlin])
    }

    func test_load_withNoDays_setsEmptyState() async {
        let sut = makeSUT(MockActivityRankingService(result: .success(.stub(dayCount: 0))))

        await sut.load()

        XCTAssertEqual(sut.state, .empty)
    }

    func test_load_setsLoadingStateWhileFetching() async {
        let service = MockActivityRankingService(result: .success(.stub()))
        let sut = makeSUT(service)
        var stateDuringFetch: ViewState<ActivityForecast>?
        service.handler = {
            stateDuringFetch = sut.state
            return .stub()
        }

        await sut.load()

        XCTAssertEqual(stateDuringFetch, .loading)
    }

    func test_load_whenFails_setsFailedStateWithUserMessage() async {
        let sut = makeSUT(MockActivityRankingService(result: .failure(NetworkError.badStatusCode(503))))

        await sut.load()

        XCTAssertEqual(sut.state, .failed(message: "The server couldn't complete the request. Please try again later."))
        XCTAssertNil(sut.refreshErrorMessage)
    }

    func test_load_withStaleForecast_showsIt() async {
        let sut = makeSUT(MockActivityRankingService(result: .success(.stub(isStale: true))))

        await sut.load()

        XCTAssertEqual(sut.state, .loaded(.stub(isStale: true)))
    }

    // MARK: - Cancellation

    func test_load_whenCancelled_restoresPreviousState_insteadOfFailing() async {
        let sut = makeSUT(MockActivityRankingService(result: .failure(CancellationError())))

        await sut.load()

        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Load if needed

    func test_loadIfNeeded_fetchesOnlyOnce() async {
        let service = MockActivityRankingService(result: .success(.stub()))
        let sut = makeSUT(service)

        await sut.loadIfNeeded()
        await sut.loadIfNeeded()

        XCTAssertEqual(service.requestedLocations.count, 1)
    }

    // MARK: - Refresh

    func test_refresh_whenFails_keepsRankingsAndSetsRefreshError() async {
        let service = MockActivityRankingService(result: .success(.stub()))
        let sut = makeSUT(service)
        await sut.load()

        service.handler = { throw NetworkError.transport(.timedOut) }
        await sut.refresh()

        XCTAssertEqual(sut.state, .loaded(.stub()))
        XCTAssertEqual(sut.refreshErrorMessage, "The request timed out. Please try again.")
    }

    func test_refresh_success_replacesRankingsAndClearsError() async {
        let service = MockActivityRankingService(result: .success(.stub()))
        let sut = makeSUT(service)
        await sut.load()
        service.handler = { throw NetworkError.transport(.timedOut) }
        await sut.refresh()

        service.handler = { .stub(dayCount: 2) }
        await sut.refresh()

        XCTAssertEqual(sut.state, .loaded(.stub(dayCount: 2)))
        XCTAssertNil(sut.refreshErrorMessage)
    }

    func test_dismissRefreshError_clearsMessage() async {
        let service = MockActivityRankingService(result: .success(.stub()))
        let sut = makeSUT(service)
        await sut.load()
        service.handler = { throw NetworkError.transport(.timedOut) }
        await sut.refresh()

        sut.dismissRefreshError()

        XCTAssertNil(sut.refreshErrorMessage)
    }
}
