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

    // MARK: Initialization

    init() {
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
