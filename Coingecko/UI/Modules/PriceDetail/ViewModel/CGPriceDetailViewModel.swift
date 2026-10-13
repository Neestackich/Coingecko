//
//  CGPriceDetailViewModel.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
import Observation

@Observable
final class CGPriceDetailViewModel {

    // MARK: Properties

    private(set) var state: CGViewState = .loading
    private(set) var rows = CGPriceDetailRowBindableData.placeholders(for: Constants.currencies)

    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    private let date: Date
    private let priceService: CGBitcoinPriceServiceType
    private let dateProvider: CGDateProviderType

    private struct Constants {
        static let currencies: [CGCurrency] = [.eur, .usd, .gbp]
    }

    // MARK: Initialization

    init(
        date: Date,
        priceService: CGBitcoinPriceServiceType,
        dateProvider: CGDateProviderType
    ) {
        self.date = date
        self.priceService = priceService
        self.dateProvider = dateProvider
    }

}

// MARK: - Public

extension CGPriceDetailViewModel {

    func loadData() {
        loadTask?.cancel()

        loadTask = Task { [weak self] in
            await self?.loadPrices()
        }
    }

    func cancelDataLoading() {
        loadTask?.cancel()
        loadTask = nil
    }

    func retryLoading() {
        loadData()
    }

    func getTitle() -> String {
        let dateStyle = Date.FormatStyle(date: .long, time: .omitted, timeZone: dateProvider.calendar.timeZone)

        return date.formatted(dateStyle)
    }

    func getFooter() -> String {
        if dateProvider.isDateSameAsToday(date) {
            return String(localized: .priceDetailFooterToday)
        }

        return String(localized: .priceDetailFooterHistorical)
    }

}

// MARK: - Private

private extension CGPriceDetailViewModel {

    func loadPrices() async {
        rows = CGPriceDetailRowBindableData.placeholders(for: Constants.currencies)
        state = .loading

        do {
            let prices = try await priceService.fetchMultipleCurrenciesPrices(on: date, currencies: Constants.currencies)

            try Task.checkCancellation()

            rows = Constants.currencies.compactMap { currency in
                guard let price = prices[currency] else {
                    return nil
                }

                return makeRow(currency: currency, price: price)
            }

            state = rows.isEmpty ? .empty : .loaded
        } catch {
            handleError(error)
        }
    }

    func handleError(_ error: Error) {
        guard !(error is CancellationError),
              !Task.isCancelled else {
            return
        }

        state = .failed(error.localizedDescription)
    }

    func makeRow(currency: CGCurrency, price: Double) -> CGPriceDetailRowBindableData {
        return CGPriceDetailRowBindableData(
            id: currency,
            code: currency.code,
            name: Locale.current.localizedString(forCurrencyCode: currency.code) ?? currency.code,
            price: price.formatted(.currency(code: currency.code))
        )
    }

}
