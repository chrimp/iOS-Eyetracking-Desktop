//
//  EyeTransform.swift
//  eyeTracker
//
//  Created by 김태우 on 6/23/24.
//

import SwiftUI
import os.log
import ARKit

struct CalibrationView: View {
    let eyeTracking = EyeTracking(configuration: Configuration(appID: "chrimp.eyeTracker"))
    @State private var calibratedPoints = 0
    @State private var isEyeTrackerReady: Bool = false
    var onCompletion: (EyeTracking) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            
            let calibrationPoints = [
                CGPoint(x: geometry.safeAreaInsets.leading + 10, y: geometry.safeAreaInsets.top),
                CGPoint(x: geometry.size.width - 10, y: geometry.safeAreaInsets.top),
                CGPoint(x: geometry.safeAreaInsets.leading + 10, y: geometry.size.height - geometry.safeAreaInsets.bottom),
                CGPoint(x: geometry.size.width - 10, y: geometry.size.height - geometry.safeAreaInsets.bottom),
                //CGPoint(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top),
                //CGPoint(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom),
                //CGPoint(x: geometry.safeAreaInsets.leading + 10, y: geometry.size.height / 2),
                //CGPoint(x: geometry.size.width - 10, y: geometry.size.height / 2),
                CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            ]
            
            ZStack {
                VStack {
                    if calibratedPoints < calibrationPoints.count {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .position(calibrationPoints[calibratedPoints])
                    }
                }
                .containerRelativeFrame([.horizontal, .vertical])
                .allowsHitTesting(false)
                
                VStack {
                    if calibratedPoints < calibrationPoints.count && isEyeTrackerReady {
                        Spacer()
                        Text("Look at the Blue dot then tap the screen.")
                            .font(.system(size: 15, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding(.bottom,
                                     geometry.safeAreaInsets.bottom == 0 ?
                                     geometry.safeAreaInsets.bottom + 16 : 0)
                    }
                }
                .containerRelativeFrame([.horizontal, .vertical])
                .allowsHitTesting(false)
            }
            .containerRelativeFrame([.horizontal, .vertical])
            .contentShape(Rectangle())
            .onAppear {
                if ARFaceTrackingConfiguration.isSupported {
                    startNewSession()
                    eyeTracking.showPointer()
                    isEyeTrackerReady = true
                } else {
                    onCompletion(eyeTracking)
                }
            }
            .onTapGesture {
                eyeTracking.collectGazePoint()
                calibratedPoints += 1
                if calibratedPoints == calibrationPoints.count {
                    eyeTracking.createTPSObject(dynamicCalibrationPoints: calibrationPoints)
                    onCompletion(eyeTracking)
                }
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
        //eyeTracking.loggingEnabled = true
    }
}

#Preview {
    CalibrationView(onCompletion: {_ in return})
}
