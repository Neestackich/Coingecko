//
//  CoingeckoApp.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI

@main
struct CoingeckoApp: App {

    // MARK: Properties

    private let dependencies = CGAppDependencies()

    // MARK: Body

    var body: some Scene {
        WindowGroup {
            CGPriceListView(viewModel: dependencies.makePriceListViewModel())
        }
    }

}
