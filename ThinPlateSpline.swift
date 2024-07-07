//
//  ThinPlateSpline.swift
//  eyeTracker
//
//  Created by 김태우 on 6/25/24.
//

import Foundation
import Accelerate

// MARK: - TPS
public struct ThinPlateSpline {
   
    let sourceX: [CGFloat]
    let sourceY: [CGFloat]
    let targetX: [CGFloat]
    let targetY: [CGFloat]
    
    var weightsX: [CGFloat] = []
    var weightsY: [CGFloat] = []
    
    public init(source: [CGPoint], target: [CGPoint]) {
        self.sourceX = source.map{ $0.x }
        self.sourceY = source.map{ $0.y }
        self.targetX = target.map{ $0.x }
        self.targetY = target.map{ $0.y }
        
        let (wx, wy) = solveWeights()
        self.weightsX = wx
        self.weightsY = wy
    }
    
    private func solveWeights() -> ([CGFloat], [CGFloat]) {
        let n = sourceX.count
        var K: [[CGFloat]] = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        var P: [[CGFloat]] = Array(repeating: Array(repeating: 0.0, count: 3), count: n)
        var L: [[CGFloat]] = Array(repeating: Array(repeating: 0.0, count: n + 3), count: n + 3)
        var Yx: [CGFloat] = Array(repeating: 0.0, count: n + 3)
        var Yy: [CGFloat] = Array(repeating: 0.0, count: n + 3)
        
        for i in 0..<n {
            for j in 0..<n {
                if i != j {
                    let r = sqrt(pow(sourceX[i] - sourceX[j], 2) + pow(sourceY[i] - sourceY[j] , 2))
                    K[i][j] = tpsRadialBasis(r: r)
                }
            }
        }
            
        for i in 0..<n {
            P[i][0] = 1
            P[i][1] = sourceX[i]
            P[i][2] = sourceY[i]
        }
        
        for i in 0..<n {
            for j in 0..<n {
                L[i][j] = K[i][j]
            }
            for j in 0..<3 {
                L[i][n + j] = P[i][j]
                L[n + j][i] = P[i][j]
            }
        }
        
        for _ in 0..<n {
            for j in 0..<3 {
                L[n + j][n + j] = 0.0
            }
        }
        
        for i in 0..<n {
            Yx[i] = targetX[i]
            Yy[i] = targetY[i]
        }
        
        let weightsX = solveLinearSystem(L: L, Y: Yx)
        let weightsY = solveLinearSystem(L: L, Y: Yy)
        
        return (weightsX, weightsY)
    }
    
    private func tpsRadialBasis(r: CGFloat) -> CGFloat {
        if r == 0.0 { return 0.0 }
        else { return r * r * log(r) }
    }
    
    func interpolate(x: CGFloat, y: CGFloat, rawPoint: CGPoint, blend: CGFloat!) -> CGPoint {
        var newX = weightsX[weightsX.count - 3] + weightsX[weightsX.count - 2] * x + weightsX[weightsX.count - 1] * y
        var newY = weightsY[weightsY.count - 3] + weightsY[weightsY.count - 2] * x + weightsY[weightsY.count - 1] * y
        
        for i in 0..<sourceX.count {
            let r = sqrt(pow(x - sourceX[i], 2) + pow(y - sourceY[i], 2))
            let basis = tpsRadialBasis(r: r)
            newX += weightsX[i] * basis
            newY += weightsY[i] * basis
        }
        let blendedX = rawPoint.x * (1 - blend) + newX * blend
        let blendedY = rawPoint.y * (1 - blend) + newY * blend
        
        return CGPoint(x: blendedX, y: blendedY)
        //return CGPoint(x: newX, y: newY)
    }
    
    func interpolate(x: Float, y: Float, rawPoint: CGPoint, blend: CGFloat!) -> CGPoint {
        let x = CGFloat(x)
        let y = CGFloat(y)
        var newX = weightsX[weightsX.count - 3] + weightsX[weightsX.count - 2] * x + weightsX[weightsX.count - 1] * y
        var newY = weightsY[weightsY.count - 3] + weightsY[weightsY.count - 2] * x + weightsY[weightsY.count - 1] * y
        
        for i in 0..<sourceX.count {
            let r = sqrt(pow(x - sourceX[i], 2) + pow(y - sourceY[i], 2))
            let basis = tpsRadialBasis(r: r)
            newX += weightsX[i] * basis
            newY += weightsY[i] * basis
        }
        let blendedX = rawPoint.x * (1 - blend) + newX * blend
        let blendedY = rawPoint.y * (1 - blend) + newY * blend
        
        return CGPoint(x: blendedX, y: blendedY)
        //return CGPoint(x: newX, y: newY)
    }
    
    private func solveLinearSystem(L: [[CGFloat]], Y: [CGFloat]) -> [CGFloat] {
        let numCounts = L.count
        let flatL = L.flatMap { $0.map { Double($0) } }
        let flatY = Y.map { Double($0) }
        
        var a = flatL
        var b = flatY
        
        var info = Int32(0)
        
        // 1: Specify transpose.
        var trans = Int8("N".utf8.first!)
        
        // 2: Define constants.
        var m = __CLPK_integer(numCounts)
        var n = __CLPK_integer(numCounts)
        var lda = __CLPK_integer(numCounts)
        var nrhs = __CLPK_integer(1) // assumes `b` is a column matrix
        var ldb = __CLPK_integer(flatY.count)
        
        // 3: Workspace query.
        var workDimension = Double(0)
        var minusOne = Int32(-1)
        
        dgels_(&trans, &m, &n,
               &nrhs,
               &a, &lda,
               &b, &ldb,
               &workDimension, &minusOne,
               &info)
        
        if info != 0 {
            print("Error during workspace query: \(info)")
            return []
        }
        
        // 4: Create workspace.
        var lwork = Int32(workDimension)
        var workspace = [Double](repeating: 0, count: Int(workDimension))
        
        // 5: Solve linear system.
        dgels_(&trans, &m, &n,
               &nrhs,
               &a, &lda,
               &b, &ldb,
               &workspace, &lwork,
               &info)
        
        if info < 0 {
            print("Error: parameter has illegal value at index \(abs(Int(info)))")
            return []
        } else if info > 0 {
            print("Error: diagonal element of triangular factor is zero at index \(Int(info))")
            return []
        }

        return b.map { CGFloat($0) }
    }
}
