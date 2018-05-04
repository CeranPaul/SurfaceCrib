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
    
    
    /// Check to see if the vector has zero length
    /// - Returns: A simple flag
    public func isZero() -> Bool   {
        
        let flagI = abs(self.i)  < Vector3D.EpsilonV
        let flagJ = abs(self.j)  < Vector3D.EpsilonV
        
        return flagI && flagJ
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

