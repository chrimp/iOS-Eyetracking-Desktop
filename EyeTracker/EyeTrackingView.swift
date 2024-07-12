//
//  ContentView.swift
//  eyeTracker
//
//  Created by 김태우 on 6/23/24.
//

import SwiftUI
import ARKit
import os.log

struct EyeTrackingView: View {
    let eyeTracking: EyeTracking
    @State var sessionID: String?
    @State var sessionTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Button("Start a New Session") {
                        startNewSession()
                    }
                    .padding()
                    .frame(width: geometry.size.width * 0.5)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color("ButtonBG"))
                    )
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Color("TextColor"))
                    
                    Button("Start Data Session for 5s") {
                        startDataSession()
                    }
                    .padding()
                    .frame(width: geometry.size.width * 0.5)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color("ButtonBG"))
                    )
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Color("TextColor"))
                }
                .containerRelativeFrame([.horizontal, .vertical])
                .background(Color("Background"))
                .padding(.horizontal, 100.0)
                .onAppear {
                    if ARFaceTrackingConfiguration.isSupported {
                        os_log("Width: %f, Height: %f",
                               type: .info,
                               geometry.size.width, geometry.size.height)
                        startNewSession()
                        //eyeTracking.showPointer()
                    } else {}
                }
                
                if !(ARFaceTrackingConfiguration.isSupported) {
                    VStack {
                        Spacer()
                        Text("FaceID is not supported on this device")
                            .font(.system(size: 11, weight: .regular))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color("TextColor"))
                            .padding(.bottom,
                                     geometry.safeAreaInsets.bottom == 0 ?
                                     geometry.safeAreaInsets.bottom + 16 : 0)
                    }
                }
            }
            .containerRelativeFrame([.horizontal, .vertical])
        }
    }
    
    func startNewSession() {
        if eyeTracking.currentSession != nil {
            let session = self.eyeTracking.currentSession
            eyeTracking.endSession()
            try? EyeTracking.delete(session!)
        }
        
        eyeTracking.startSession()
        eyeTracking.showPointer()
        eyeTracking.loggingEnabled = true
        sessionID = eyeTracking.currentSession?.id
    }
    
    func startDataSession() {
        startNewSession()
        
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            self.eyeTracking.loggingEnabled = false
            let session = self.eyeTracking.currentSession
            self.eyeTracking.endSession()
            guard let jsonData = try? EyeTracking.exportAll() else { return }
            let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
            print(jsonDict ?? "")
            try? EyeTracking.delete(session!)
            self.eyeTracking.startSession()
        }
    }
    
    func startScanpathSession() {
        startNewSession()
        
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            let session = self.eyeTracking.currentSession
            self.eyeTracking.endSession()
            self.eyeTracking.displayScanpath(for: self.sessionID ?? "", animated: false)
            try? EyeTracking.delete(session!)
        }
    }
    
    func hideScanpath() {
        eyeTracking.hideVisualization()
    }
}

extension EyeTracking {
    static let mock = EyeTracking(configuration: Configuration(appID: "chrimp.eyeTracker"))
}

#Preview {
    EyeTrackingView(eyeTracking: EyeTracking.mock)
}
