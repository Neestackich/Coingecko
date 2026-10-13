//
//  CGAPIConfig.swift
//  Coingecko
//
//  Created by Vittcal Neestackich on 13.10.26.
//

import Foundation

nonisolated final class CGAPIConfig: CGAPIConfigType {

    // MARK: Properties

    let baseBackend: String
    let apiKey: String?

    private struct Constants {
        static let configFileName = "APIConfig"
        static let configFileType = "plist"
        static let developmentKey = "Development"
        static let productionKey = "Production"
        static let baseBackendKey = "BaseBackend"
        static let apiKeyInfoPlistKey = "COINGECKO_API_KEY"
    }

    // MARK: Initialization

    init(bundle: Bundle = .main) {
        let config = Self.loadEnvironmentConfig(from: bundle)
        let baseBackend = config[Constants.baseBackendKey] as? String ?? ""
        let apiKey = Self.loadAPIKey(from: bundle)

        self.baseBackend = baseBackend
        self.apiKey = apiKey
    }

}

// MARK: - Private

private nonisolated extension CGAPIConfig {

    static func loadEnvironmentConfig(from bundle: Bundle) -> [String: Any] {
        guard let path = bundle.path(forResource: Constants.configFileName, ofType: Constants.configFileType),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return [:]
        }

        #if DEBUG
        return config[Constants.developmentKey] as? [String: Any] ?? [:]
        #else
        return config[Constants.productionKey] as? [String: Any] ?? [:]
        #endif
    }

    static func loadAPIKey(from bundle: Bundle) -> String? {
        guard let key = bundle.object(forInfoDictionaryKey: Constants.apiKeyInfoPlistKey) as? String else {
            return nil
        }

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedKey.isEmpty ? nil : trimmedKey
    }

}
