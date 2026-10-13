//
//  CGAppDependencies.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

final class CGAppDependencies {

    // MARK: Properties

    private let priceService: CGBitcoinPriceServiceType
    private let dateProvider: CGDateProviderType

    private struct Constants {
        static let uiTestingArgument = "-ui-testing"
        static let uiTestingNow = Date(timeIntervalSince1970: 1_791_892_800)
    }

    // MARK: Initialization

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(Constants.uiTestingArgument) {
            let dateProvider = CGFixedDateProvider(now: Constants.uiTestingNow)

            self.dateProvider = dateProvider
            self.priceService = CGPreviewBitcoinPriceService(behavior: .success, dateProvider: dateProvider)
            return
        }
        #endif

        let apiClient = CGAPIClient(config: CGAPIConfig())
        let dateProvider = CGDateProvider()

        self.dateProvider = dateProvider
        self.priceService = CGBitcoinPriceService(
            apiClient: apiClient,
            dateProvider: dateProvider,
            cache: CGCache()
        )
    }

}

// MARK: - Public

extension CGAppDependencies {

    func makePriceListViewModel() -> CGPriceListViewModel {
        return CGPriceListViewModel(priceService: priceService, dateProvider: dateProvider)
    }

}
