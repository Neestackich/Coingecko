//
//  CGPriceRowView.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI

struct CGPriceRowView: View {
    private let data: CGPriceRowBindableData

    private struct Constants {
        static let badgeHorizontalPadding: CGFloat = 6
        static let badgeVerticalPadding: CGFloat = 2
        static let badgeBackgroundOpacity = 0.15
    }

    init(data: CGPriceRowBindableData) {
        self.data = data
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(data.date)

                    if data.isLive {
                        makeBadge(text: Text(.priceListLiveBadge), color: .green)
                    }

                    if data.isStale {
                        makeBadge(text: Text(.priceListStaleBadge), color: .orange)
                    }
                }

                if let updatedTime = data.updatedTime {
                    Text(updatedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            price
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Private

private extension CGPriceRowView {
    func makeBadge(text: Text, color: Color) -> some View {
        text
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, Constants.badgeHorizontalPadding)
            .padding(.vertical, Constants.badgeVerticalPadding)
            .background(color.opacity(Constants.badgeBackgroundOpacity), in: Capsule())
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
        CGPriceRowView(data: CGPriceRowBindableData(id: .now, date: "Tue, 13 Oct", price: "€96,412.08", isLive: true, isStale: false, updatedTime: "as of 22:29"))
        CGPriceRowView(data: CGPriceRowBindableData(id: .distantFuture, date: "Tue, 13 Oct", price: "€96,412.08", isLive: false, isStale: true, updatedTime: "as of 02:00"))
        CGPriceRowView(data: CGPriceRowBindableData(id: .distantPast, date: "Mon, 12 Oct", price: "€95,870.51", isLive: false, isStale: false, updatedTime: nil))
    }
}
