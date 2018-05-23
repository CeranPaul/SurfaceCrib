//
//  VectorSurf.swift
//  SurfaceCrib
//
//  Created by Paul on 4/16/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// Simple representation of a direction on a parametric surface.
/// The default initializer suffices.
public struct VectorSurf   {
    
    var i: Double
    var j: Double
    
    
    /// Destructively make this a unit vector
    public mutating func normalize()   {
        
        if !self.isZero()   {
            
            let denom = self.length()
            
            i = self.i / denom
            j = self.j / denom
        }
    }
    
    
    /// Figure the combined length of both components.
    /// - Returns: Size from base to tip.
    public func length() -> Double {        
        return sqrt(self.i * self.i + self.j * self.j)
    }
    
    
    /// Create vector between two points
    /// - Parameters:
    ///   - from: Tail point
    ///   - to: Head point
    /// - Returns: New VectorSurf
    public static func build(from: PointSurf, to: PointSurf, unit: Bool = false) -> VectorSurf   {
        
        let deltaU = to.u - from.u
        let deltaV = to.v - from.v
        
        var fresh = VectorSurf(i: deltaU, j: deltaV)
        
        if unit   { fresh.normalize() }
        
        return fresh
    }
    
    /// Check to see if the vector has zero length
    /// - Returns: A simple flag
    public func isZero() -> Bool   {
        
        let flagI = abs(self.i)  < Vector3D.EpsilonV
        let flagJ = abs(self.j)  < Vector3D.EpsilonV
        
        return flagI && flagJ
    }
    
    
    /// Standard definition of dot product
    /// - Returns: Scalar magnitude
    public static func dotProduct(lhs: VectorSurf, rhs: VectorSurf) -> Double   {
        
        return lhs.i * rhs.i + lhs.j * rhs.j
    }
    

    public static func sumBundle(bin: [VectorSurf]) -> VectorSurf   {
        
        let compI = bin.map{$0.i}
        let compJ = bin.map{$0.j}
        let sumI = compI.reduce(0.0, { $0 + $1 })
        let sumJ = compJ.reduce(0.0, { $0 + $1 })
        
        return VectorSurf(i: sumI, j: sumJ)
    }

}


/// Construct a vector by scaling the VectorSurf by the Double argument.
public func * (lhs: VectorSurf, scalar: Double) -> VectorSurf   {
    
    let scaledI = lhs.i * scalar
    let scaledJ = lhs.j * scalar
    
    return VectorSurf(i: scaledI, j: scaledJ)
}


/// Construct a vector that is the difference between the two input vectors
public func - (lhs: VectorSurf, rhs: VectorSurf) -> VectorSurf   {
    
    return VectorSurf(i: lhs.i - rhs.i, j: lhs.j - rhs.j)
}


