//
//  DerivablePath.swift
//  SolanaSwift
//
//  Created by Chung Tran on 06/05/2021.
//

import Foundation

extension SolanaSDK {
    public struct DerivablePath: Hashable {
        // MARK: - Nested type
        public enum DerivableType: String, CaseIterable {
            case deprecated
            case bip44
            case bip44Change
            
            var prefix: String {
                switch self {
                case .deprecated:
                    return "m/501'"
                case .bip44, .bip44Change:
                    return "m/44'/501'"
                }
            }
        }
        
        // MARK: - Properties
        public let type: DerivableType
        public let walletIndex: Int
        public let accountIndex: Int?
        
        public init(type: SolanaSDK.DerivablePath.DerivableType, walletIndex: Int, accountIndex: Int? = nil) {
            self.type = type
            self.walletIndex = walletIndex
            self.accountIndex = accountIndex
        }
        
        public static var `default`: Self {
            .init(
                type: .bip44Change,
                walletIndex: 0,
                accountIndex: 0
            )
        }
        
        public var rawValue: String {
            var value = type.prefix
            switch type {
            case .deprecated:
                value += "/\(walletIndex)'/0/\(accountIndex ?? 0)"
            case .bip44:
                value += "/\(walletIndex)'"
            case .bip44Change:
                value += "/\(walletIndex)'/0'"
            }
            return value
        }
    }
}