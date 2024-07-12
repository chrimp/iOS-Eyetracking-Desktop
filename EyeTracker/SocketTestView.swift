//
//  SocketTestView.swift
//  eyeTracker
//
//  Created by 김태우 on 7/6/24.
//

import SwiftUI
import os
import Network

struct SocketTestView: View {
    let udpLogger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "udp")
    @StateObject var udpListener = UDPListener(port: 24135)
    @State var lstState: NWConnection.State = .setup
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Button("Start listening") {
                        udpListener.start()
                    }
                    .padding()
                    .frame(width: geometry.size.width * 0.5)
                    .background(RoundedRectangle(cornerRadius: 40)
                        .fill(Color.buttonBG)
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("TextColor"))
                }
                
                VStack {
                    Spacer()
                    Text("\(udpListener.connectionState)")
                    Text("\(String(describing: udpListener.data!))")
                }
            }
            .containerRelativeFrame([.horizontal, .vertical])
            .background(Color.background)
        }
    }
}

#Preview {
    SocketTestView()
}
