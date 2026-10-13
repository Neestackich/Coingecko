//
//  CGPreviewBitcoinPriceService.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

#if DEBUG

import Foundation

nonisolated final class CGPreviewBitcoinPriceService: CGBitcoinPriceServiceType {

    // MARK: Properties

    enum Behavior: Sendable {
        case success
        case loading
        case failure
        case empty
    }

    private let behavior: Behavior
    private let dateProvider: CGDateProviderType

    private struct Constants {
        static let basePrice = 96412.08
        static let dailyPriceStep = 312.5
        static let loadingDuration: Duration = .seconds(3600)
        static let pricesByCurrency: [CGCurrency: Double] = [
            .eur: 96412.08,
            .usd: 112305.44,
            .gbp: 83190.17
        ]
    }

    // MARK: Initialization

    init(behavior: Behavior, dateProvider: CGDateProviderType = CGDateProvider()) {
        self.behavior = behavior
        self.dateProvider = dateProvider
    }

}

// MARK: - CGBitcoinPriceServiceType

nonisolated extension CGPreviewBitcoinPriceService {

    func fetchDailyPricesList(days: Int, currency: CGCurrency) async throws -> [CGDailyPrice] {
        try await simulateBehavior()

        guard behavior == .success else {
            return []
        }

        let today = dateProvider.today

        return (0..<days).compactMap { offset in
            guard let date = dateProvider.calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }

            return CGDailyPrice(
                date: date,
                price: Constants.basePrice - Double(offset) * Constants.dailyPriceStep,
                currency: currency,
                updatedAt: offset == 0 ? dateProvider.now : date
            )
        }
    }

    func fetchCurrentDayPrice(currency: CGCurrency) async throws -> CGDailyPrice {
        try await simulateBehavior()

        return CGDailyPrice(
            date: dateProvider.today,
            price: Constants.pricesByCurrency[currency] ?? Constants.basePrice,
            currency: currency,
            updatedAt: dateProvider.now
        )
    }

    func fetchMultipleCurrenciesPrices(on date: Date, currencies: [CGCurrency]) async throws -> [CGCurrency: Double] {
        try await simulateBehavior()

        return Constants.pricesByCurrency.filter { currencies.contains($0.key) }
    }

}

// MARK: - Private

private nonisolated extension CGPreviewBitcoinPriceService {

    func simulateBehavior() async throws {
        switch behavior {
        case .success, .empty:
            return
        case .loading:
            try await Task.sleep(for: Constants.loadingDuration)
        case .failure:
            throw CGAPIClientError.transportError(.notConnectedToInternet)
        }
    }

}

#endif
