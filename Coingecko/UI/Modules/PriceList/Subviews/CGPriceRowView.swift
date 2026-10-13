//
//  CGPriceRowView.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI

struct CGPriceRowView {
    private let data: CGPriceRowBindableData

    private struct Constants {
        static let badgeHorizontalPadding: CGFloat = 6
        static let badgeVerticalPadding: CGFloat = 2
        static let badgeBackgroundOpacity = 0.15
    }

    init(data: CGPriceRowBindableData) {
        self.data = data
    }
}

// MARK: - View

extension CGPriceRowView: View {
    var body: some View {
        HStack {
            Text(data.date)

            if data.isLive {
                liveBadge
            }

            Spacer()

            price
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Private

private extension CGPriceRowView {
    var liveBadge: some View {
        Text(.priceListLiveBadge)
            .font(.caption.bold())
            .foregroundStyle(.green)
            .padding(.horizontal, Constants.badgeHorizontalPadding)
            .padding(.vertical, Constants.badgeVerticalPadding)
            .background(.green.opacity(Constants.badgeBackgroundOpacity), in: Capsule())
    }

    var price: some View {
        Text(data.price)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.default, value: data.price)
    }
}

#Preview {
    List {
        CGPriceRowView(data: CGPriceRowBindableData(id: .now, date: "Tue, 13 Oct", price: "€96,412.08", isLive: true))
        CGPriceRowView(data: CGPriceRowBindableData(id: .distantPast, date: "Mon, 12 Oct", price: "€95,870.51", isLive: false))
    }
}
