//
//  CGAPIClientError.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated enum CGAPIClientError: Error, Equatable {
    case urlCreateError
    case invalidResponse
    case httpStatus(Int)
    case transportError(URLError.Code)
}

// MARK: - LocalizedError

nonisolated extension CGAPIClientError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .httpStatus(429):
            return String(localized: .errorTooManyRequests)
        case .transportError(.notConnectedToInternet),
             .transportError(.networkConnectionLost),
             .transportError(.dataNotAllowed),
             .transportError(.internationalRoamingOff):
            return String(localized: .errorNoInternetConnection)
        default:
            return String(localized: .errorGeneric)
        }
    }

}
