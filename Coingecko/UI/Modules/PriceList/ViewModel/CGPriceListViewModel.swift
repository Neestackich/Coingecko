//
//  CGPriceListViewModel.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
import Observation

@Observable
final class CGPriceListViewModel {

    // MARK: Properties

    private(set) var state: CGViewState = .loading
    private(set) var rows = CGPriceRowBindableData.placeholders(count: Constants.days)
    private(set) var lastUpdated: String?
    private(set) var isRefreshFailing = false

    @ObservationIgnored private var dailyPrices: [CGDailyPrice] = []
    @ObservationIgnored private var liveUpdatesTask: Task<Void, Never>?

    private let priceService: CGBitcoinPriceServiceType
    private let dateProvider: CGDateProviderType

    private struct Constants {
        static let days = 14
        static let currency: CGCurrency = .eur
        static let refreshInterval: Duration = .seconds(60)
        static let maxLivePriceAge: TimeInterval = 5 * 60
    }

    // MARK: Initialization

    init(
        priceService: CGBitcoinPriceServiceType,
        dateProvider: CGDateProviderType
    ) {
        self.priceService = priceService
        self.dateProvider = dateProvider
    }

}

// MARK: - Public

extension CGPriceListViewModel {

    func startLiveUpdates() {
        liveUpdatesTask?.cancel()

        liveUpdatesTask = Task { [weak self] in
            while !Task.isCancelled {
                if let newestDay = self?.dailyPrices.first?.date,
                   self?.dateProvider.isDateSameAsToday(newestDay) == true {
                    await self?.refreshTodaysPrice(on: newestDay)
                } else {
                    await self?.loadHistory()
                }

                try? await Task.sleep(for: Constants.refreshInterval)
            }
        }
    }

    func stopLiveUpdates() {
        liveUpdatesTask?.cancel()
        liveUpdatesTask = nil
    }

    func refresh() async {
        stopLiveUpdates()

        await loadHistory()

        startLiveUpdates()
    }

    func retry() {
        startLiveUpdates()
    }

    func makeDetailViewModel(for date: Date) -> CGPriceDetailViewModel {
        return CGPriceDetailViewModel(date: date, priceService: priceService, dateProvider: dateProvider)
    }

}

// MARK: - Private

private extension CGPriceListViewModel {

    func loadHistory() async {
        if dailyPrices.isEmpty {
            rows = CGPriceRowBindableData.placeholders(count: Constants.days)
            state = .loading
        }

        do {
            let prices = try await priceService.fetchDailyPrices(days: Constants.days, currency: Constants.currency)

            try Task.checkCancellation()

            dailyPrices = prices

            showPrices()
        } catch {
            handleError(error)
        }
    }

    func refreshTodaysPrice(on day: Date) async {
        do {
            let todaysPrice = try await priceService.fetchCurrentPrice(currency: Constants.currency)

            try Task.checkCancellation()

            guard todaysPrice.date == day,
                  dailyPrices.first?.date == day else {
                return
            }

            dailyPrices[0] = todaysPrice

            showPrices()
        } catch {
            handleError(error)
        }
    }

    func showPrices() {
        isRefreshFailing = false

        updateRows()

        state = rows.isEmpty ? .empty : .loaded
        lastUpdated = String(localized: .priceListLastUpdated(dateProvider.now.formatted(date: .omitted, time: .shortened)))
    }

    func updateRows() {
        rows = dailyPrices.map { dailyPrice in
            return makeRow(from: dailyPrice)
        }
    }

    func handleError(_ error: Error) {
        guard !(error is CancellationError),
              !Task.isCancelled else {
            return
        }

        guard dailyPrices.isEmpty else {
            isRefreshFailing = true
            updateRows()
            return
        }

        state = .failed(error.localizedDescription)
    }

    func makeRow(from dailyPrice: CGDailyPrice) -> CGPriceRowBindableData {
        let isToday = dateProvider.isDateSameAsToday(dailyPrice.date)
        let priceAge = dateProvider.now.timeIntervalSince(dailyPrice.updatedAt)
        let isStale = isToday && (isRefreshFailing || priceAge > Constants.maxLivePriceAge)

        var updatedTime: String?

        if isToday {
            let time = dailyPrice.updatedAt.formatted(date: .omitted, time: .shortened)
            updatedTime = String(localized: .priceListPriceTime(time))
        }

        let dateStyle = Date.FormatStyle(timeZone: dateProvider.calendar.timeZone)
            .weekday(.abbreviated)
            .day()
            .month(.abbreviated)

        return CGPriceRowBindableData(
            id: dailyPrice.date,
            date: dailyPrice.date.formatted(dateStyle),
            price: dailyPrice.price.formatted(.currency(code: dailyPrice.currency.code)),
            isLive: isToday && !isStale,
            isStale: isStale,
            updatedTime: updatedTime
        )
    }

}
