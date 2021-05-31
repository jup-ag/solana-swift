//
//  Socket.swift
//  SolanaSwift
//
//  Created by Chung Tran on 03/12/2020.
//

import Foundation
import RxSwift
import Starscream
import RxCocoa

extension SolanaSDK {
    public class Socket {
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let socket: WebSocket
        var wsHeartBeat: Timer!
        
        // MARK: - Subscriptions
        private var accounts = [String]()
        private var accountSubscriptions = [Subscription]()
        
        // MARK: - Subjects
        let status = BehaviorRelay<Status>(value: .initializing)
        let dataSubject = PublishSubject<Data>()
        var socketDidConnect: Completable {
            status.filter{$0 == .connected}.take(1).asSingle().asCompletable()
        }

        // MARK: - Initializer
        public init(endpoint: String) {
            var request = URLRequest(url: URL(string: endpoint)!)
            request.timeoutInterval = 5
            socket = WebSocket(request: request)
            defer {socket.delegate = self}
        }
        
        deinit {
            disconnect()
        }
        
        // MARK: - Socket actions
        /// Connect to Solana's websocket
        public func connect() {
            // connecting
            status.accept(.connecting)
            
            // connect
            socket.connect()
        }
        
        /// Disconnect from Solana's websocket
        public func disconnect() {
            unsubscribeToAllSubscriptions()
            status.accept(.disconnected)
            socket.disconnect()
        }
        
        // MARK: - Account notifications
        public func subscribeAccountNotification(account: String) {
            // check if subscriptions exists
            guard !accountSubscriptions.contains(where: {$0.account == account })
            else {
                // already registered
                return
            }
            
            // if account was not registered, add account to self.accounts
            if !accounts.contains(account) {
                accounts.append(account)
            }
            
            // add subscriptions
            let id = write(method: .init(.account, .subscribe), params: [account])
            subscribe(id: id)
                .subscribe(onSuccess: {[weak self] subscriptionId in
                    guard let strongSelf = self else {return}
                    if strongSelf.accountSubscriptions.contains(where: {$0.account == account})
                    {
                        strongSelf.accountSubscriptions.removeAll(where: {$0.account == account})
                    }
                    strongSelf.accountSubscriptions.append(.init(entity: .account, id: subscriptionId, account: account))
                })
                .disposed(by: disposeBag)
        }
        
        
        
        // MARK: - Signature notifications
        public func observeSignatureNotification(signature: String) -> Completable
        {
            let id = write(
                method: .init(.signature, .subscribe),
                params: [signature/*, ["commitment": "max"]*/]
            )
            
            return subscribe(id: id)
                .flatMap {
                    self.observeNotification(
                        .signature,
                        decodedTo: Rpc<SignatureNotification>.self,
                        subscription: $0
                    )
                        .take(1)
                        .asSingle()
                }
                .asCompletable()
        }
        
        @discardableResult
        public func write(method: Method, params: [Encodable]) -> String {
            let requestAPI = RequestAPI(
                method: method.rawValue,
                params: params
            )
            write(requestAPI: requestAPI)
            return requestAPI.id
        }
        
        // MARK: - Helpers
        /// Subscribe to accountNotification from all accounts in the queue
        func subscribeToAllAccounts() {
            accounts.forEach {subscribeAccountNotification(account: $0)}
        }
        
        /// Unsubscribe to all current subscriptions
        func unsubscribeToAllSubscriptions() {
            for subscription in accountSubscriptions {
                write(method: .init(subscription.entity, .unsubscribe), params: [subscription.id])
            }
            accountSubscriptions = []
        }
        
        private func subscribe(id: String) -> Single<UInt64> {
            dataSubject
                .filter { data in
                    guard let json = (try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as? [String: Any]
                        else {
                            return false
                    }
                    return (json["id"] as? String) == id
                }
                .map { data in
                    guard let subscription = try JSONDecoder().decode(Response<UInt64>.self, from: data).result
                    else {
                        throw Error.other("Subscription is not valid")
                    }
                    return subscription
                }
                .take(1)
                .asSingle()
        }
        
        private func observeNotification<T: Decodable>(_ entity: Entity, decodedTo type: T.Type, subscription: UInt64? = nil) -> Observable<T> {
            dataSubject
                .filter { data in
                    guard let json = (try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as? [String: Any]
                        else {
                            return false
                    }
                    var condition = (json["method"] as? String) == entity.notificationMethodName
                    if let subscription = subscription {
                        condition = condition && (((json["params"] as? [String: Any])?["subscription"] as? UInt64) == subscription)
                    }
                    return condition
                }
                .map { data in
                    guard let result = try JSONDecoder().decode(Response<T>.self, from: data).params?.result
                    else {
                        throw Error.other("The response is empty")
                    }
                    return result
                }
        }
        
        private func write(requestAPI: RequestAPI, completion: (() -> ())? = nil) {
            // closure for writing
            let writeAndLog: () -> Void = { [weak self] in
                do {
                    let data = try JSONEncoder().encode(requestAPI)
                    guard let string = String(data: data, encoding: .utf8) else {
                        throw Error.other("Request is invalid \(requestAPI)")
                    }
                    self?.socket.write(string: string, completion: {
                        Logger.log(message: "\(requestAPI.method) success", event: .event)
                        completion?()
                    })
                } catch {
                    Logger.log(message: "\(requestAPI.method) failed: \(error)", event: .event)
                }
            }
            
            // auto reconnect
            if status.value != .connected {
                socket.connect()
                status.filter {$0 == .connected}
                    .take(1).asSingle()
                    .subscribe(onSuccess: { _ in
                        writeAndLog()
                    })
                    .disposed(by: disposeBag)
            } else {
                writeAndLog()
            }
        }
    }
}
