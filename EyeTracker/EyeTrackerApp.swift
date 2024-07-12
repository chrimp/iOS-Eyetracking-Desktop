//
//  eyeTrackerApp.swift
//  eyeTracker
//
//  Created by 김태우 on 6/23/24.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var showEyeTrackingView = false
    @Published var calibratedSession: EyeTracking?
    @Published var establishedUDPListener: UDPListener?
}

enum view {
    case remote
    case local
    case socketTest
}

@main
struct eyeTrackerApp: App {
    @StateObject private var appState = AppState()
    let testSocket = false
    let skipCalibration = false
    let viewSelec = view.remote
    
    var body: some Scene {
        WindowGroup {
            if viewSelec == view.socketTest { SocketTestView() } // Socket Test
            
            else if skipCalibration { // No calibration
                if viewSelec == view.remote {
                    RemoteDisplayView(eyeTracking: EyeTracking.mock, udpListener: UDPListener.mock)
                } else if viewSelec == view.local {
                    EyeTrackingView(eyeTracking: EyeTracking.mock)
                }
            }
            
            else if !appState.showEyeTrackingView { // Calibration:
                if viewSelec == view.remote { // For remote display
                    DisplayCalibrationView(onCompletion: { session, listener in
                        self.appState.calibratedSession = session
                        self.appState.establishedUDPListener = listener
                        self.appState.showEyeTrackingView = true
                    })
                }
                
                else  if viewSelec == view.local { // For device display
                    CalibrationView(onCompletion: { session in
                        self.appState.calibratedSession = session
                        self.appState.showEyeTrackingView = true
                    })
                }
            }
            
            else { // After Calibration is done:
                if viewSelec == view.remote {
                    RemoteDisplayView(eyeTracking: appState.calibratedSession!, udpListener: appState.establishedUDPListener!)
                } else if viewSelec == view.local {
                    EyeTrackingView(eyeTracking: appState.calibratedSession!)
                }
            }
        }
    }
}
