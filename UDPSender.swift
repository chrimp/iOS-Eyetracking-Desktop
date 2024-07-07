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
    var stateUpdateHandler: (NWConnection.State) -> Void
    let nwHost: NWEndpoint.Host!
    let nwPort: NWEndpoint.Port!
    @Published var connectionState: NWConnection.State = .setup

    init(host: String, port: UInt16, stateUpdateHandler: @escaping (NWConnection.State) -> Void) {
        nwHost = NWEndpoint.Host(host)
        nwPort = NWEndpoint.Port(rawValue: port)
        connection = NWConnection(host: nwHost, port: nwPort, using: .udp)
        self.stateUpdateHandler = stateUpdateHandler
    }
    
    private func setupConnection() {
        connection = NWConnection(host: nwHost, port: nwPort, using: .udp)
    }

    func start() {
        connection!.stateUpdateHandler = { state in
            self.stateUpdateHandler(state)
            switch state {
            case .failed(let error):
                print("Failed to connect: \(error)")
            case .waiting(let error):
                print("Timeout: \(error)")
            default:
                break
            }
        }
        connection!.start(queue: queue)
    }

    func sendData(_ message: String) {
        let data = message.data(using: .utf8)!
        connection!.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send data: \(error)")
            }
        })
    }
    
    public func getRemoteEndpoint() -> (NWEndpoint.Port, NWEndpoint.Host)? {
        guard let port = self.nwPort else { return nil }
        let addr = self.nwHost!
        return (port, addr)
    }

    func stop() {
        connection!.cancel()
    }
}
