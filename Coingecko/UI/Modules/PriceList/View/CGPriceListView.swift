//
//  CGPriceListView.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI

struct CGPriceListView {
    @State private var viewModel: CGPriceListViewModel
    @Environment(\.scenePhase) private var scenePhase

    private struct Constants {
        static let warningIconName = "exclamationmark.triangle.fill"
        static let emptyIconName = "chart.line.downtrend.xyaxis"
    }

    init(viewModel: CGPriceListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
}

extension CGPriceListView: View {
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text(.priceListTitle))
        }
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            handleScenePhase(newPhase)
        }
    }
}

// MARK: - Private

private extension CGPriceListView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .loading, .loaded:
            pricesList
        case .empty:
            emptyView
        case .failed(let message):
            CGErrorStateView(message: message, retry: viewModel.retry)
        }
    }

    var pricesList: some View {
        List {
            Section {
                ForEach(viewModel.rows) { row in
                    CGPriceRowView(data: row)
                }
            } header: {
                Text(.priceListSectionHeader)
            } footer: {
                footer
            }
        }
        .redacted(reason: viewModel.state == .loading ? .placeholder : [])
        .disabled(viewModel.state == .loading)
        .refreshable {
            await viewModel.refresh()
        }
    }

    var footer: some View {
        VStack(alignment: .leading) {
            if let lastUpdated = viewModel.lastUpdated {
                Text(lastUpdated)
            }

            if viewModel.isRefreshFailing {
                Label {
                    Text(.priceListRefreshFailed)
                } icon: {
                    Image(systemName: Constants.warningIconName)
                }
                .foregroundStyle(.orange)
            }
        }
    }

    var emptyView: some View {
        ContentUnavailableView {
            Label {
                Text(.priceListEmptyTitle)
            } icon: {
                Image(systemName: Constants.emptyIconName)
            }
        } description: {
            Text(.priceListEmptyDescription)
        } actions: {
            Button(action: viewModel.retry) {
                Text(.buttonRetry)
            }
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        if phase == .active {
            viewModel.startLiveUpdates()
        } else {
            viewModel.stopLiveUpdates()
        }
    }
}

#if DEBUG

#Preview("Loaded") {
    CGPriceListView(viewModel: CGPriceListViewModel(
        priceService: CGPreviewBitcoinPriceService(behavior: .success),
        dateProvider: CGDateProvider()
    ))
}

#Preview("Loading") {
    CGPriceListView(viewModel: CGPriceListViewModel(
        priceService: CGPreviewBitcoinPriceService(behavior: .loading),
        dateProvider: CGDateProvider()
    ))
}

#Preview("Error") {
    CGPriceListView(viewModel: CGPriceListViewModel(
        priceService: CGPreviewBitcoinPriceService(behavior: .failure),
        dateProvider: CGDateProvider()
    ))
}

#Preview("Empty") {
    CGPriceListView(viewModel: CGPriceListViewModel(
        priceService: CGPreviewBitcoinPriceService(behavior: .empty),
        dateProvider: CGDateProvider()
    ))
}
#endif
