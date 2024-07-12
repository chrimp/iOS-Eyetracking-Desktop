//
//  UDPlistener.swift
//  eyeTracker
//
//  Created by 김태우 on 7/6/24.
//

import Foundation
import Network
import Combine

func isPortOpen(port: in_port_t) -> Bool {

    let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
    if socketFileDescriptor == -1 {
        return false
    }

    var addr = sockaddr_in()
    let sizeOfSockkAddr = MemoryLayout<sockaddr_in>.size
    addr.sin_len = __uint8_t(sizeOfSockkAddr)
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(port) : port
    addr.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
    addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
    var bind_addr = sockaddr()
    memcpy(&bind_addr, &addr, Int(sizeOfSockkAddr))

    if Darwin.bind(socketFileDescriptor, &bind_addr, socklen_t(sizeOfSockkAddr)) == -1 {
        return false
    }
    let isOpen = listen(socketFileDescriptor, SOMAXCONN ) != -1
    Darwin.close(socketFileDescriptor)
    return isOpen
}

class UDPListener: ObservableObject {
    var listener: NWListener?
    var connection: NWConnection?
    var queue = DispatchQueue(label: "UDP receiver queue")
    var listening: Bool = false
    let nwPort: NWEndpoint.Port!
    @Published var data: String?
    @Published var connectionState: NWConnection.State = .setup
    
    init(port: UInt16) {
        nwPort = NWEndpoint.Port(rawValue: port)
        listener = try? NWListener(using: .udp, on: nwPort)
    }
    
    func start() {
        listener!.stateUpdateHandler = { state in
            switch state {
            case .failed(let error): print("Failed to connect: \(error)")
            case .waiting(let error): print("Timeout: \(error)")
            default: break
            }
        }
        listener?.newConnectionHandler = { connection in
            print("newconnection: \(connection.endpoint)")
            if let localport = connection.currentPath?.localEndpoint {
                print("localport: \(localport)")
                print("port aval: \(isPortOpen(port: 24135))")
                print("remoteport: \(connection.currentPath?.remoteEndpoint)")
            } else {
                fatalError("local port missing")
            }
            self.createConnection(connection)
        }
        listener?.start(queue: queue)
    }
    
    func createConnection(_ connection: NWConnection) {
        self.connection = connection
        self.connection?.stateUpdateHandler = { state in
            DispatchQueue.main.async { self.connectionState = state }
            switch state {
            case .ready:
                self.listening = true
                self.receiveMessage()
            case .failed(let error): print("Failed to connect: \(error)")
            case .waiting(let error): print("Timeout: \(error)")
            default: break
            }
        }
        self.connection?.start(queue: queue)
    }
    
    func receiveMessage() {
        connection!.receiveMessage { [weak self] data, context, isComplete, error in
            
            if let error = error {
                print(error)
                fatalError("Error in receivemessage")
                DispatchQueue.main.async {
                    self?.connectionState = .failed(error)
                }
                return
            }
            
            if let data = data {
                let dataString = String(data: data, encoding: .ascii)
                DispatchQueue.main.async {
                    self?.data = dataString
                }
            }
            self?.receiveMessage()
        }
    }
}
