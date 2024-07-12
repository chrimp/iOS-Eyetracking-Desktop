//
//  EyeTransform.swift
//  eyeTracker
//
//  Created by 김태우 on 6/23/24.
//

import SwiftUI
import os.log
import ARKit
import Foundation
import Combine

struct DisplayCalibrationView: View {
    let eyeTracking = EyeTracking(configuration: Configuration(appID: "chrimp.eyeTracker"))
    @State private var calibratedPoints = 0
    @State private var isEyeTrackerReady: Bool = false
    @State private var foundRemote = false
    @State private var bgColor: Color = Color.black
    @State var timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    @StateObject var udpSender: UDPSender = UDPSender(host: "192.168.1.121", sendPort: 24135)
    @StateObject var udpListener: UDPListener = UDPListener(port: 24135)
    var onCompletion: (EyeTracking, UDPListener) -> Void
    let calibrationPoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 1440),
                             CGPoint(x: 2560, y: 0), CGPoint(x: 2560, y: 1440),
                             CGPoint(x: 1280, y: 0), CGPoint(x: 1280, y: 1440),
                             CGPoint(x: 0, y: 720), CGPoint(x: 2560, y: 720),
                             CGPoint(x: 1280, y: 720)]
    let pointInstruction = ["Left Top", "Left Bottom", "Right Top", "Right Bottom", "Middle Top", "Middle Bottom", "Left Middle", "Right Middle", "Middle"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if calibratedPoints < calibrationPoints.count && (isEyeTrackerReady && foundRemote) {
                    VStack {
                        VStack {
                            Text("Look at \(pointInstruction[calibratedPoints]) then Tap the screen")
                                .font(.system(size: 20, weight: .semibold)).padding(.top, geometry.safeAreaInsets.top)
                        }
                        .containerRelativeFrame([.horizontal])
                        .allowsHitTesting(false)
                        
                        VStack(alignment: .center) {
                            Spacer()
                            Text("Current Point:").font(.system(size: 15, weight: .medium))
                            Text("\(calibratedPoints + 1) / \(calibrationPoints.count)").font(.system(size: 80, weight: .bold))
                            Spacer()
                        }
                        .containerRelativeFrame([.horizontal, .vertical])
                        .allowsHitTesting(false)
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                    .allowsHitTesting(false)
                }
            }
            .background(bgColor)
            .containerRelativeFrame([.horizontal, .vertical])
            .contentShape(Rectangle())
            .task {
                if ARFaceTrackingConfiguration.isSupported {
                    udpSender.start()
                    udpListener.start()
                    startNewSession()
                    await waitForStart()
                    await waitForUDP()
                } else {
                    onCompletion(eyeTracking, udpListener)
                }
            }
            .onTapGesture {
                eyeTracking.collectGazePoint()
                udpSender.sendData("TC")
                bgColor = Color.indigo
                calibratedPoints += 1
                if calibratedPoints == calibrationPoints.count {
                    eyeTracking.createTPSObject(dynamicCalibrationPoints: calibrationPoints)
                    onCompletion(eyeTracking, udpListener)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    bgColor = Color.black
                }
            }
            .onChange(of: udpListener.data) {
                if udpListener.data == "CC" {
                    udpListener.data = nil
                    eyeTracking.collectGazePoint()
                    calibratedPoints += 1
                    bgColor = Color.indigo
                    if calibratedPoints == calibrationPoints.count {
                        eyeTracking.createTPSObject(dynamicCalibrationPoints: calibrationPoints)
                        onCompletion(eyeTracking, udpListener)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        bgColor = Color.black
                    }
                }
            }
            .onReceive(timer) { _ in
                udpSender.sendData("EyeTracker broadcast")
            }
        }
    }
    
    func startNewSession() {
        if eyeTracking.currentSession != nil {
            let session = self.eyeTracking.currentSession
            eyeTracking.endSession()
            try? EyeTracking.delete(session!)
        }
        eyeTracking.startSession()
    }
    
    func waitForStart() async {
        while true {
            do { try await Task.sleep(nanoseconds: 100000000) } catch {}
            guard let _ = eyeTracking.currentSession?.scanPath.last?.x else { continue }
            withAnimation {
                isEyeTrackerReady = true
            }
            return
        }
    }
    
    func waitForUDP() async {
        let entryTime = Int(Date().timeIntervalSince1970)
        print("start")
        while true {
            do { try await Task.sleep(nanoseconds: 100000000) } catch {}
            if udpListener.data == "Device Found" {
                timer.upstream.connect().cancel()
                withAnimation {
                    self.foundRemote = true
                }
                return
            }
            if Int(Date().timeIntervalSince1970) - entryTime > 100 {
                guard let _ = udpListener.connection else {
                    fatalError("connection is nil")
                }
                fatalError("100 seconds elapsed, potential lock")
            }
        }
    }
}

#Preview {
    DisplayCalibrationView(onCompletion: {_, _ in return})
}
