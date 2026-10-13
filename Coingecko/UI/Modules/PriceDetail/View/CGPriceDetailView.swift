//
//  CGPriceDetailView.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI

struct CGPriceDetailView: View {
    @State private var viewModel: CGPriceDetailViewModel

    private struct Constants {
        static let rowIdentifierPrefix = "priceDetailRow_"
    }

    init(viewModel: CGPriceDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle(viewModel.getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadData()
            }
            .onDisappear {
                viewModel.cancelDataLoading()
            }
    }
}

// MARK: - Private

private extension CGPriceDetailView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .loading, .loaded, .empty:
            pricesList
        case .failed(let message):
            CGErrorStateView(message: message, retry: viewModel.retryLoading)
        }
    }

    var pricesList: some View {
        List {
            Section {
                ForEach(viewModel.rows) { row in
                    CGPriceDetailRowView(data: row)
                        .accessibilityIdentifier(Constants.rowIdentifierPrefix + row.code)
                }
            } header: {
                Text(.priceDetailSectionHeader)
            } footer: {
                Text(viewModel.getFooter())
            }
        }
        .redacted(reason: viewModel.state == .loading ? .placeholder : [])
        .disabled(viewModel.state == .loading)
    }
}

#if DEBUG

#Preview("Loaded") {
    NavigationStack {
        CGPriceDetailView(viewModel: CGPriceDetailViewModel(
            date: .now,
            priceService: CGPreviewBitcoinPriceService(behavior: .success),
            dateProvider: CGDateProvider()
        ))
    }
}

#Preview("Loading") {
    NavigationStack {
        CGPriceDetailView(viewModel: CGPriceDetailViewModel(
            date: .now,
            priceService: CGPreviewBitcoinPriceService(behavior: .loading),
            dateProvider: CGDateProvider()
        ))
    }
}

#Preview("Error") {
    NavigationStack {
        CGPriceDetailView(viewModel: CGPriceDetailViewModel(
            date: .now,
            priceService: CGPreviewBitcoinPriceService(behavior: .failure),
            dateProvider: CGDateProvider()
        ))
    }
}
#endif
