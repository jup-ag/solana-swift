import Foundation

public struct ParsedTokenAccount: Decodable {
    public let pubkey: String
    public let account: Account

    public init(pubkey: String, account: Account) {
        self.pubkey = pubkey
        self.account = account
    }

    // MARK: - Inner Types

    public struct Account: Decodable {
        public let data: DataClass
        public let executable: Bool
        public let lamports: Int
        public let owner: String
        public let rentEpoch, space: Int
    }

    public struct DataClass: Decodable {
        public let program: String
        public let parsed: Parsed
        public let space: Int
    }

    public struct Parsed: Decodable {
        public let accountType: String
        public let info: Info
        public let type: String
    }

    public struct Info: Decodable {
        public let tokenAmount: Amount
        public let delegate: String
        public let delegatedAmount: Amount
        public let state: String
        public let isNative: Bool
        public let mint, owner: String
    }

    public struct Amount: Decodable {
        public let amount: String
        public let decimals: Int
        public let uiAmount: Float64
        public let uiAmountString: String
    }

}
