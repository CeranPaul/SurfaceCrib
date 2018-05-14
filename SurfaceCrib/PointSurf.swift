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
    
    // Replacing the default initializer with something that does range checking might be good.
    
    
    /// Squeal if not 0 < u < 1 or not 0 < v < 1
    /// - Returns: Simple flag
    public func isInRange() -> Bool   {
        let flagU = self.u >= 0.0  &&  self.u <= 1.0
        let flagV = self.v >= 0.0  &&  self.v <= 1.0
        
        return flagU && flagV
    }
    
    /// Generate a new point if it is within range.
    /// - Parameters:
    ///   - jump: Vector to translate the point
    /// - Returns: Point if parameters are within range, nil if out of range.
    public func offsetNil(jump: VectorSurf) -> PointSurf?   {
        
        let freshPoint = PointSurf(u: self.u + jump.i, v: self.v + jump.j)
        
        if !freshPoint.isInRange()   { return nil }
        
        return freshPoint
    }
    
    /// Generate a new point that doesn't fall off the surface.
    /// - Parameters:
    ///   - jump: Vector to translate the point
    /// - Returns: Point while forcing parameters to be within range.
    public func offsetLimit(jump: VectorSurf) -> PointSurf   {
        
        var freshU = self.u + jump.i
        
        if freshU > 1.0   { freshU = 1.0 }
        if freshU < 0.0   { freshU = 0.0 }
        
        var freshV = self.v + jump.j
        
        if freshV > 1.0   { freshV = 1.0 }
        if freshV < 0.0   { freshV = 0.0 }
        
        return PointSurf(u: freshU, v: freshV)
    }
    
    
    /// Subdivide the interval between two points
    /// - Parameters:
    ///   - pointA: One end
    ///   - pointB: Other end
    ///   - chunks: Optional number of intervals.  Defaults to 5.
    /// - Returns: Array of points
    public static func splitSpan(pointA: PointSurf, pointB: PointSurf, chunks: Int = 5) -> [PointSurf]   {
        
        /// The array to be returned
        var stairs = [PointSurf]()
        
        stairs.append(pointA)   // Start with one end
        
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
        
        stairs.append(pointB)   // Close with the other end
        
        return stairs
    }
    
}
