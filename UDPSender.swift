//
//  TCP.swift
//  eyeTracker
//
//  Created by 김태우 on 6/26/24.
//

import Network
import Combine
import SwiftUI

class UDPSender: ObservableObject {
    var connection: NWConnection?
    let queue = DispatchQueue(label: "UDP sender Queue")
    let sendEndpoint: NWEndpoint
    @Published var connectionState: NWConnection.State = .setup

    init(host: String, sendPort: UInt16) {
        sendEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: sendPort)!)
    }

    func start() {
        connection = NWConnection(to: sendEndpoint, using: .udp)
        connection!.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                self?.connectionState = state
                switch state {
                case .failed(let error):
                    print("Failed to connect: \(error)")
                case .waiting(let error):
                    print("Timeout: \(error)")
                default:
                    break
                }
            }
        }
        connection!.start(queue: queue)
    }
    
    func sendData(_ message: String) {
        if connectionState == .setup { return }
        let data = message.data(using: .utf8)!
        connection!.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send data: \(error)")
            }
        })
    }
    
    public func getRemoteEndpoint() -> (NWEndpoint.Port, NWEndpoint.Host)? {
        switch(connection?.endpoint) {
        case .hostPort(let nwHost, let nwPort):
            return (nwPort, nwHost)
        default:
            return nil
        }
    }

    func stop() {
        connection!.cancel()
    }
}
