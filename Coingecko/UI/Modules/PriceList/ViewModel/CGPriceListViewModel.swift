//
//  CGPriceListViewModel.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class CGPriceListViewModel {

    // MARK: Properties

    private(set) var state: CGViewState = .loading
    private(set) var rows = CGPriceRowBindableData.placeholders(count: Constants.days)
    private(set) var lastUpdated: String?
    private(set) var isRefreshFailing = false

    @ObservationIgnored private(set) var loadDataTask: Task<Void, Never>?

    @ObservationIgnored private var dailyPrices: [CGDailyPrice] = []

    private let priceService: CGBitcoinPriceServiceType
    private let dateProvider: CGDateProviderType
    private let refreshInterval: Duration

    private struct Constants {
        static let days = 14
        static let currency: CGCurrency = .eur
        static let refreshInterval: Duration = .seconds(60)
        static let maxLivePriceAge: TimeInterval = 5 * 60
    }

    // MARK: Initialization

    init(
        priceService: CGBitcoinPriceServiceType,
        dateProvider: CGDateProviderType,
        refreshInterval: Duration = Constants.refreshInterval
    ) {
        self.priceService = priceService
        self.dateProvider = dateProvider
        self.refreshInterval = refreshInterval
    }

}

// MARK: - Public

extension CGPriceListViewModel {

    func handleScenePhase(_ phase: ScenePhase) {
        if phase == .active {
            startLiveDataUpdates()
        } else {
            stopLiveDataUpdates()
        }
    }

    func refresh() async {
        loadDataTask?.cancel()

        let refreshTask = Task<Void, Never> { [weak self] in
            await self?.loadHistory()
        }

        loadDataTask = refreshTask

        await withTaskCancellationHandler {
            await refreshTask.value
        } onCancel: {
            refreshTask.cancel()
        }

        guard loadDataTask == refreshTask, !refreshTask.isCancelled else {
            return
        }

        startLiveUpdatesLoop(updatingImmediately: false)
    }

    func retry() {
        if dailyPrices.isEmpty {
            rows = CGPriceRowBindableData.placeholders(count: Constants.days)
            state = .loading
        } else {
            state = .loaded
        }

        startLiveDataUpdates()
    }

    func getSectionHeader() -> String {
        return String(localized: .priceListSectionHeader(Constants.days, Constants.currency.code))
    }

    func makeDetailViewModel(for date: Date) -> CGPriceDetailViewModel {
        return CGPriceDetailViewModel(date: date, priceService: priceService, dateProvider: dateProvider)
    }

}

// MARK: - Private

private extension CGPriceListViewModel {

    func startLiveDataUpdates() {
        if !dailyPrices.isEmpty {
            updateRows()
        }

        startLiveUpdatesLoop(updatingImmediately: true)
    }

    func stopLiveDataUpdates() {
        loadDataTask?.cancel()
        loadDataTask = nil
    }

    func startLiveUpdatesLoop(updatingImmediately: Bool) {
        loadDataTask?.cancel()

        loadDataTask = Task { [weak self, refreshInterval] in
            if updatingImmediately {
                await self?.loadLatestPrices()
            }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: refreshInterval)
                } catch {
                    return
                }

                guard let self else {
                    return
                }

                await self.loadLatestPrices()
            }
        }
    }

    func loadLatestPrices() async {
        if let newestDay = dailyPrices.first?.date,
           dateProvider.isDateSameAsToday(newestDay) {
            await refreshTodaysPrice(on: newestDay)
        } else {
            await loadHistory()
        }
    }

    func loadHistory() async {
        do {
            let prices = try await priceService.fetchDailyPricesList(days: Constants.days, currency: Constants.currency)

            try Task.checkCancellation()

            dailyPrices = prices

            showPrices()
        } catch {
            handleError(error)
        }
    }

    func refreshTodaysPrice(on day: Date) async {
        do {
            let todaysPrice = try await priceService.fetchCurrentDayPrice(currency: Constants.currency)

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
