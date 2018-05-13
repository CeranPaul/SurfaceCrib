//
//  PointSurf.swift
//  SurfaceCrib
//
//  Created by Paul on 12/14/17.
//  Copyright © 2017 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// Simple representation of a position on a parametric surface.
/// u and v are the equivalent of s and t.
/// No range checks are made to keep u and v between 0.0 and 1.0.
/// The default initializer suffices.
public struct PointSurf   {
    
    var u: Double
    var v: Double
    
    
    public func isInRange() -> Bool   {
        let flagU = self.u >= 0.0  &&  self.u <= 1.0
        let flagV = self.v >= 0.0  &&  self.v <= 1.0
        
        return flagU && flagV
    }
    
    /// Generate a new point
    /// - Returns: Point if parameters are within range, nil if out of range.
    public func offsetNil(jump: VectorSurf) -> PointSurf?   {
        
        let freshPoint = PointSurf(u: self.u + jump.i, v: self.v + jump.j)
        
        let goodU = freshPoint.u >= 0.0  &&  freshPoint.u <= 1.0
        let goodV = freshPoint.v >= 0.0  &&  freshPoint.v <= 1.0
        
        let valid = goodU  &&  goodV
        
        if !valid   { return nil }
        
        return freshPoint
    }
    
    
    public static func splitSpan(pointA: PointSurf, pointB: PointSurf, chunks: Int = 5) -> [PointSurf]   {
        
        /// The array to be returned
        var stairs = [PointSurf]()
        
        stairs.append(pointA)
        
        let deltaU = pointB.u - pointA.u
        let deltaV = pointB.v - pointA.v
        
        let stepU = deltaU / Double(chunks)
        let stepV = deltaV / Double(chunks)

        for g in 1..<chunks   {
            
            let freshU = pointA.u + Double(g) * stepU
            let freshV = pointA.v + Double(g) * stepV
            
            let waypoint = PointSurf(u: freshU, v: freshV)
            
            stairs.append(waypoint)
        }
        
        stairs.append(pointB)
        
        return stairs
    }
    
}
