//
//  CGPriceDetailRowView.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI

struct CGPriceDetailRowView: View {
    private let data: CGPriceDetailRowBindableData

    init(data: CGPriceDetailRowBindableData) {
        self.data = data
    }

    var body: some View {
        HStack {
            currency

            Spacer()

            Text(data.price)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Private

private extension CGPriceDetailRowView {
    var currency: some View {
        VStack(alignment: .leading) {
            Text(data.code)
                .font(.headline)

            Text(data.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        CGPriceDetailRowView(data: CGPriceDetailRowBindableData(id: .eur, code: "EUR", name: "Euro", price: "€74,216.00"))
        CGPriceDetailRowView(data: CGPriceDetailRowBindableData(id: .usd, code: "USD", name: "US Dollar", price: "$86,412.35"))
        CGPriceDetailRowView(data: CGPriceDetailRowBindableData(id: .gbp, code: "GBP", name: "British Pound", price: "£64,190.17"))
    }
}
