//
//  UDPlistener.swift
//  eyeTracker
//
//  Created by 김태우 on 7/6/24.
//

import Foundation
import Network
import Combine

class UDPListener: ObservableObject {
    var listener: NWListener?
    var connection: NWConnection?
    var queue = DispatchQueue(label: "UDP receiver queue")
    //var stateUpdateHandler: (NWListener.State) -> Void
    var listening: Bool = false
    let nwPort: NWEndpoint.Port!
    @Published var data: Data?
    @Published var connectionState: NWConnection.State = .setup
    
    init(port: UInt16) {
        nwPort = NWEndpoint.Port(rawValue: port)
        listener = try? NWListener(using: .udp, on: nwPort)
    }
    
    func start() {
        listener!.stateUpdateHandler = { state in
            //self.stateUpdateHandler(state)
            switch state {
            case .failed(let error): print("Failed to connect: \(error)")
            case .waiting(let error): print("Timeout: \(error)")
            default: break
            }
        }
        listener?.newConnectionHandler = { connection in
            self.createConnection(connection)
        }
        listener?.start(queue: queue)
    }
    
    func createConnection(_ connection: NWConnection) {
        self.connection = connection
        self.connection?.stateUpdateHandler = { state in
            //self.connectionState = state
            print(state)
            switch state {
            case .ready:
                self.listening = true
                self.receive()
            case .failed(let error): print("Failed to connect: \(error)")
            case .waiting(let error): print("Timeout: \(error)")
            default: break
            }
        }
        self.connection?.start(queue: queue)
    }
    
    func receive() {
        queue.async { [self] in
            while listening {
                self.connection?.receiveMessage { data, context, isComplete, error in
                    print("listening")
                    if let error = error {
                        print("receive(): \(error)")
                        self.listening = false
                        return
                    }
                    
                    if let _ = data {
                        print(data)
                    }
                    
                    Thread.sleep(forTimeInterval: 0.01)
                }
            }
        }
    }
}
