//
//  CGErrorStateView.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import SwiftUI

struct CGErrorStateView {
    let message: String
    let retry: () -> Void

    private struct Constants {
        static let iconName = "exclamationmark.triangle"
    }
}

extension CGErrorStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label {
                Text(.errorTitle)
            } icon: {
                Image(systemName: Constants.iconName)
            }
        } description: {
            Text(message)
        } actions: {
            Button(action: retry) {
                Text(.buttonRetry)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    CGErrorStateView(message: String(localized: .errorNoInternetConnection)) {}
}
