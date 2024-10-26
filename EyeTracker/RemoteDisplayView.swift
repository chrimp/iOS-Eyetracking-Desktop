//
//  socketTestView.swift
//  eyeTracker
//
//  Created by 김태우 on 6/26/24.
//

import Network
import SwiftUI
import ARKit
import os
import Combine
import UIKit

struct RemoteDisplayView: View {
    let eyeTracking: EyeTracking
    let udpLogger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "udp")
    @StateObject var udpSender = UDPSender(host: "192.168.1.121", sendPort: 24135)
    @State var transformValue: CGFloat = 0.9
    @State var maValue: CGFloat = 1.0
    @State var offScreen: Bool = false
    @State var timer = Timer.publish(every: 1/60, tolerance: 1/180, on: .main, in: .common).autoconnect()
    @StateObject var udpListener: UDPListener
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    if !offScreen {
                        VStack {
                            Button("Start socket") {
                                timer = timer.upstream.autoconnect()
                                udpSender.start()
                                UIApplication.shared.isIdleTimerDisabled = true
                            }
                            .padding()
                            .frame(width: geometry.size.width * 0.5)
                            .background(
                                RoundedRectangle(cornerRadius: 40)
                                    .fill(Color("ButtonBG"))
                            )
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(Color("TextColor"))
                            
                            Button("Stop socket") {
                                udpSender.stop()
                                UIApplication.shared.isIdleTimerDisabled = false
                            }
                            .padding()
                            .frame(width: geometry.size.width * 0.5)
                            .background(RoundedRectangle(cornerRadius: 40).fill(Color("ButtonBG")))
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(Color("TextColor"))
                            
                            Button("Dim Screen") {
                                withAnimation {
                                    offScreen = true
                                }
                            }
                            .padding()
                            .frame(width: geometry.size.width * 0.5)
                            .background(RoundedRectangle(cornerRadius: 40).fill(Color("ButtonBG")))
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(Color("TextColor"))
                            
                            Text(String(format: "MA Blend: %.2f", maValue))
                                .font(.system(size: 15, weight: .medium)).foregroundStyle(Color("TextColor"))
                                .padding(.top)
                            Slider(value: $maValue, in: 0...1, step: 0.01)
                                .onChange(of: maValue) {
                                    eyeTracking.updateMABlend(newBlend: maValue)
                                }
                                .frame(width: geometry.size.width * 0.7)
                            Text(String(format: "Transform Blend: %.2f", transformValue))
                                .font(.system(size: 15, weight: .medium)).foregroundStyle(Color("TextColor"))
                            Slider(value: $transformValue, in: 0...1, step: 0.01)
                                .onChange(of: transformValue) {
                                    eyeTracking.updateBlend(newBlend: transformValue)
                                }
                                .padding(.bottom)
                                .frame(width: geometry.size.width * 0.7)
                        }
                        .containerRelativeFrame([.horizontal])
                        
                        VStack {
                            Spacer()
                            if !ARFaceTrackingConfiguration.isSupported {
                                Text("FaceID is not supported on this device")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color("TextColor"))
                                    .padding(.bottom,
                                             geometry.safeAreaInsets.bottom == 0 ?
                                             geometry.safeAreaInsets.bottom + 16 : 0)
                            }
                            
                            Text(connectionStateDescription(udpSender.connectionState))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color("TextColor"))
                                .padding(.bottom,
                                         geometry.safeAreaInsets.bottom == 0 ?
                                         geometry.safeAreaInsets.bottom + 16 : 0)
                        }
                    }
                }
            }
            .onReceive(timer) { _ in
                let point = eyeTracking.publishedLookPoint
                let blendShape = eyeTracking.puiblishedBlendShapes ?? (0.0, 0.0)
                udpSender.sendData(String(format: "%.3f, %.3f;%.3f, %.3f", point?.x ?? 0.0, point?.y ?? 0.0, blendShape.0, blendShape.1))
            }
            .containerRelativeFrame([.horizontal, .vertical])
            .background(offScreen ? Color.black : Color.background)
            .onTapGesture {
                if offScreen {
                    withAnimation {
                        offScreen = false
                    }
                }
            }
            .onChange(of: udpListener.data) {
                let data = udpListener.data!
                
                if data == "CfgRQ" {
                    udpSender.sendData(String(format: "AB%.2f", maValue))
                    udpSender.sendData(String(format: "TB%.2f", transformValue))
                    return
                }
                
                let typeStr = data.prefix(2)
                let valueStr = data.suffix(4)
                
                switch typeStr {
                case "AB": maValue = CGFloat((valueStr as NSString).floatValue)
                case "TB": transformValue = CGFloat((valueStr as NSString).floatValue)
                case "SC":
                    timer = timer.upstream.autoconnect()
                    udpSender.start()
                    UIApplication.shared.isIdleTimerDisabled = true
                default: print("Found unknown packet: \(data)")
                }
            }
        }
    }
    
    private func connectionStateDescription(_ state: NWConnection.State) -> String {
        switch state{
        case .setup: return "No socket currently alive"
        case .waiting(let error):
            udpLogger.error("Waiting error: \(error)")
            return "Waiting for connection accept..."
        case .preparing: return "Connection is being prepared"
        case .failed(let error):
            udpLogger.error("Connection Failed: \(error)")
            return "Connection Failed. Check log for details"
        case .cancelled:
            timer.upstream.connect().cancel()
            return "Socket is invalidated"
        case .ready:
            let port: NWEndpoint.Port = udpSender.getRemoteEndpoint()!.0
            let host: NWEndpoint.Host = udpSender.getRemoteEndpoint()!.1
            return "Socket is alive. \(host):\(port)"
        @unknown default: return "?"
        }
    }
}

extension UDPListener {
    static let mock = UDPListener(port: 0)
}

#Preview {
    RemoteDisplayView(eyeTracking: EyeTracking.mock, udpListener: UDPListener.mock)
}
