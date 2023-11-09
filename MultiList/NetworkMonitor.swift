//
//  NetworkMonitor.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/11/23.
//

import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let queue = DispatchQueue.global()
    private let monitor: NWPathMonitor
    public private(set) var isConnected: Bool = false
    
    private init() {
        self.monitor = NWPathMonitor()
    }

    public func startMonitoring() {
            print("request Monitoring Start")
            monitor.start(queue: queue)
            monitor.pathUpdateHandler = { [weak self] path in
                self?.isConnected = path.status == .satisfied
            }
        }
    
    public func stopMonitoring() {
            print("request Monitoring Stop")
            monitor.cancel()
        }
}
