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
}

enum view {
    case remote
    case local
    case socketTest
}

@main
struct eyeTrackerApp: App {
    @StateObject private var appState = AppState()
    let testSocket = true
    let testEyeTrackingView = false
    let testDisplayView = true
    let viewSelec = view.remote
    
    var body: some Scene {
        WindowGroup {
            if testSocket { SocketTestView() } // Socket Test
            
            else if testEyeTrackingView{ EyeTrackingView(eyeTracking: EyeTracking(configuration: Configuration(appID: "chrimp.eyeTracker"))) } // EyeTrackingView (Old view, no socket)
            else if !appState.showEyeTrackingView { // Primary entry - Calibration
                if viewSelec == view.remote { // For remote display
                    DisplayCalibrationView(onCompletion: { session in
                        self.appState.calibratedSession = session
                        self.appState.showEyeTrackingView = true
                    })
                } else { // For device display
                    CalibrationView(onCompletion: { session in
                        self.appState.calibratedSession = session
                        self.appState.showEyeTrackingView = true
                    })
                }
            } else {
                if viewSelec == view.remote {
                    RemoteDisplayView(eyeTracking: appState.calibratedSession!)
                } else if viewSelec == view.local {
                    EyeTrackingView(eyeTracking: appState.calibratedSession!)
                }
            } // Primary entry - Calibrated EyeTracker with socket
        }
    }
}
