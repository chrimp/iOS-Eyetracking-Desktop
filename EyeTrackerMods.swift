//
//  EyeTrackerCalibration.swift
//  eyeTracker
//
//  Created by 김태우 on 6/25/24.
//

import ARKit
import UIKit
import os.log

// MARK: - Calibration

extension EyeTracking {
    public func collectGazePoint() {
        let session: Session! = currentSession
        let x = session.scanPath.last!.x
        let y = session.scanPath.last!.y
        collectedGazePoints.append(CGPoint(x: x, y: y))
    }
    
    func createTPSObject(dynamicCalibrationPoints: [CGPoint]) -> Void {
        calibrationPoints = dynamicCalibrationPoints
        tps = ThinPlateSpline(source: collectedGazePoints, target: calibrationPoints)
    }
    
    func updateBlend(newBlend: CGFloat) {
        self.transformBlend = newBlend
    }
    
    func updateMABlend(newBlend: CGFloat) {
        self.averageBlend = newBlend
    }
}

class MovingAverage {
    private var pointsArray: [CGPoint] = []
    private var count = 0
    private let window: Int
    private var prevVal: CGPoint?
    init(window: Int) {
        self.window = window
    }
    
    func update(with newPoint: CGPoint, blend: CGFloat) -> CGPoint {
        if count < window {
            pointsArray.append(newPoint)
            count += 1
        } else {
            pointsArray.removeFirst()
            pointsArray.append(newPoint)
        }
        
        let pointsX: [CGFloat] = pointsArray.map{ $0.x }
        let pointsY: [CGFloat] = pointsArray.map{ $0.y }
        
        let averageX: CGFloat = pointsX.reduce(0, +) / CGFloat(count)
        let averageY: CGFloat = pointsY.reduce(0, +) / CGFloat(count)
        
        let blendX: CGFloat = ((1 - blend) * newPoint.x) + (blend * averageX)
        let blendY: CGFloat = ((1 - blend) * newPoint.y) + (blend * averageY)
        
        return CGPoint(x: blendX, y: blendY)
    }
}
