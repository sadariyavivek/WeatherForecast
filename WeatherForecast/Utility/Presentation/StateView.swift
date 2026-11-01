//
//  StateView.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 31/10/26.
//
import SwiftUI

/// Renders the loading, empty and failed states for any `ViewState`,
/// and hands the loaded value to `content`.
struct StateView<Value, Content: View>: View {
    let state: ViewState<Value>
    let emptyTitle: String
    let emptySystemImage: String
    let emptyDescription: String
    let failureTitle: String
    let onRetry: () async -> Void
    let content: (Value) -> Content

    init(
        state: ViewState<Value>,
        emptyTitle: String = "Nothing Here",
        emptySystemImage: String = "tray",
        emptyDescription: String = "There's nothing to show right now.",
        failureTitle: String = "Something Went Wrong",
        onRetry: @escaping () async -> Void,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptySystemImage = emptySystemImage
        self.emptyDescription = emptyDescription
        self.failureTitle = failureTitle
        self.onRetry = onRetry
        self.content = content
    }

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let value):
            content(value)
        case .empty:
            ContentUnavailableView(
                emptyTitle,
                systemImage: emptySystemImage,
                description: Text(emptyDescription)
            )
        case .failed(let message):
            ContentUnavailableView {
                Label(failureTitle, systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task { await onRetry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

extension StateView {
    /// Binds the view to a `StatefulViewModel`'s state.
    /// `onRetry` calls whichever method that view model uses to load.
    init<ViewModel: StatefulViewModel>(
        viewModel: ViewModel,
        emptyTitle: String = "Nothing Here",
        emptySystemImage: String = "tray",
        emptyDescription: String = "There's nothing to show right now.",
        failureTitle: String = "Something Went Wrong",
        onRetry: @escaping () async -> Void,
        @ViewBuilder content: @escaping (Value) -> Content
    ) where ViewModel.Value == Value {
        self.init(
            state: viewModel.state,
            emptyTitle: emptyTitle,
            emptySystemImage: emptySystemImage,
            emptyDescription: emptyDescription,
            failureTitle: failureTitle,
            onRetry: onRetry,
            content: content
        )
    }
}
