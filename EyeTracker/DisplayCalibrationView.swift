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

struct DisplayCalibrationView: View {
    let eyeTracking = EyeTracking(configuration: Configuration(appID: "chrimp.eyeTracker"))
    @State private var calibratedPoints = 0
    @State private var isEyeTrackerReady: Bool = false
    @State private var bgColor: Color = Color.black
    var onCompletion: (EyeTracking) -> Void
    let calibrationPoints = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 1440),
                             CGPoint(x: 2560, y: 0), CGPoint(x: 2560, y: 1440),
                             CGPoint(x: 1280, y: 0), CGPoint(x: 1280, y: 1440),
                             CGPoint(x: 0, y: 720), CGPoint(x: 2560, y: 720),
                             CGPoint(x: 1280, y: 720)]
    let pointInstruction = ["Left Top", "Left Bottom", "Right Top", "Right Bottom", "Middle Top", "Middle Bottom", "Left Middle", "Right Middle", "Middle"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if calibratedPoints < calibrationPoints.count && isEyeTrackerReady {
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
                    startNewSession()
                    await waitForStart()
                } else {
                    onCompletion(eyeTracking)
                }
            }
            .onTapGesture {
                eyeTracking.collectGazePoint()
                bgColor = Color.indigo
                calibratedPoints += 1
                if calibratedPoints == calibrationPoints.count {
                    eyeTracking.createTPSObject(dynamicCalibrationPoints: calibrationPoints)
                    onCompletion(eyeTracking)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    bgColor = Color.black
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
}

#Preview {
    DisplayCalibrationView(onCompletion: {_ in return})
}
