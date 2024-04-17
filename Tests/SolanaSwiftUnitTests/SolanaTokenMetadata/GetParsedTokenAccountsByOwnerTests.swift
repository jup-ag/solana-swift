import OSLog
import SolanaSwift
import XCTest

final class GetParsedTokenAccountsByOwnerTests: XCTestCase {
    var rpcClient: JSONRPCAPIClient!

    override func setUp() async throws {
        rpcClient = JSONRPCAPIClient(
            endpoint: .init(
                address: "https://example.com",
                network: .mainnetBeta
            ),
            networkManager: MockSolanaAPINetworkManager()
        )
    }

    func testGetParsedTokenAccountsByOwner() async throws {
        let result = try await rpcClient.getParsedTokenAccountsByOwner(
            pubkey: "abc", 
            params: .init(mint: nil, programId: "xyz")
        )

        XCTAssertEqual(result.count, 1)

        let account = result[0]
        XCTAssertEqual(account.pubkey, "C2gJg6tKpQs41PRS1nC8aw3ZKNZK3HQQZGVrDFDup5nx")
        XCTAssertEqual(account.account.data.parsed.info.tokenAmount.uiAmount, 0.1)
        XCTAssertEqual(account.account.data.parsed.info.mint, "3wyAj7Rt1TWVPZVteFJPLa26JmLvdb1CAKEFZm3NY75E")
    }

    // MARK: -

    final class MockSolanaAPINetworkManager: NetworkManager {
       func requestData(request: URLRequest) async throws -> Data {
           let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8)!
           if bodyString.contains("getTokenAccountsByOwner") {
               return """
{
  "jsonrpc": "2.0",
  "result": {
    "context": {
      "slot": 1114
    },
    "value": [
      {
        "account": {
          "data": {
            "program": "spl-token",
            "parsed": {
              "accountType": "account",
              "info": {
                "tokenAmount": {
                  "amount": "1",
                  "decimals": 1,
                  "uiAmount": 0.1,
                  "uiAmountString": "0.1"
                },
                "delegate": "4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T",
                "delegatedAmount": {
                  "amount": "1",
                  "decimals": 1,
                  "uiAmount": 0.1,
                  "uiAmountString": "0.1"
                },
                "state": "initialized",
                "isNative": false,
                "mint": "3wyAj7Rt1TWVPZVteFJPLa26JmLvdb1CAKEFZm3NY75E",
                "owner": "4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F"
              },
              "type": "account"
            },
            "space": 165
          },
          "executable": false,
          "lamports": 1726080,
          "owner": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
          "rentEpoch": 4,
          "space": 165
        },
        "pubkey": "C2gJg6tKpQs41PRS1nC8aw3ZKNZK3HQQZGVrDFDup5nx"
      }
    ]
  },
  "id": 1
}
"""
.data(using: .utf8)!
           }

           fatalError()
       }
   }

}
