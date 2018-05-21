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
public struct PointSurf: Hashable   {
    
    var u: Double
    var v: Double
    
    /// Threshhold of separation for equality checks
    public static let Epsilon: Double = 0.001

    
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
    
    // TODO: Offset, but shorten the vector in case of going out of bounds.
    
    /// Calculate the distance between two of 'em
    /// - Parameters:
    ///   - pt1:  One point
    ///   - pt2:  Another point
    public static func dist(pt1: PointSurf, pt2: PointSurf) -> Double   {
        
        let deltaU = pt2.u - pt1.u
        let deltaV = pt2.v - pt1.v
        
        let sum = deltaU * deltaU + deltaV * deltaV
        
        return sqrt(sum)
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
    
    /// Generate a grid of points on a portion of the surface.
    /// No range checking.
    public static func genGrid(portionU: ClosedRange<Double>, portionV: ClosedRange<Double>, countU: Int, countV: Int ) -> [PointSurf]   {
        
        let stepU = (portionU.upperBound - portionU.lowerBound) / Double(countU - 1)
        let stepV = (portionV.upperBound - portionV.lowerBound) / Double(countV - 1)
        
        
        /// Values for U across the range without numeric problems at the upper end
        var ewes = [Double]()
        
        ewes.append(portionU.lowerBound)
        
        
        for g in 1...countU - 2   {
            let middle = portionU.lowerBound + Double(g) * stepU
            ewes.append(middle)
        }
        
        ewes.append(portionU.upperBound)
        
        
        /// Values for U across the range without numeric problems at the upper end
        var vees = [Double]()
        
        vees.append(portionV.lowerBound)
        
        
        for g in 1...countV - 2   {
            let middle = portionV.lowerBound + Double(g) * stepV
            vees.append(middle)
        }
        
        vees.append(portionV.upperBound)
        
        
        /// Points to be returned
        var pips = [PointSurf]()
        
        for myU in ewes   {
            for myV in vees   {
                let spot = PointSurf(u: myU, v: myV)
                pips.append(spot)
            }
        }
        
        return pips
    }
    
    
    /// Generate the unique value
    public var hashValue: Int   {
        
        get  {
            
            let divX = u / PointSurf.Epsilon
            let myX = Int(round(divX))
            
            let divY = v / PointSurf.Epsilon
            let myY = Int(round(divY))
            
            return myX.hashValue + myY.hashValue
        }
    }
    

    
}


public func == (lhs: PointSurf, rhs: PointSurf) -> Bool   {
    
    let deltaU = abs(lhs.u - rhs.u)
    let flagU = deltaU < PointSurf.Epsilon
    
    let deltaV = abs(lhs.v - rhs.v)
    let flagV = deltaV < PointSurf.Epsilon
    
    return flagU && flagV
}


public func != (lhs: PointSurf, rhs: PointSurf) -> Bool   {
    
    let deltaU = abs(lhs.u - rhs.u)
    let flagU = deltaU > PointSurf.Epsilon
    
    let deltaV = abs(lhs.v - rhs.v)
    let flagV = deltaV > PointSurf.Epsilon
    
    return flagU || flagV
}


/// Tool for finding nearby points.
public struct Neighborhood   {
    
    var rangeU: ClosedRange<Double>
    var rangeV: ClosedRange<Double>
    
    
    /// Build a rectangle from opposite corners.
    init(cornerA: PointSurf, cornerB: PointSurf)   {
        
        var minU = cornerA.u
        if cornerB.u < cornerA.u   { minU = cornerB.u }
        
        var maxU = cornerB.u
        if cornerA.u > cornerB.u   { maxU = cornerA.u }
        
        self.rangeU = ClosedRange<Double>(uncheckedBounds: (lower: minU, upper: maxU))
        
        
        var minV = cornerA.v
        if cornerB.v < cornerA.v   { minV = cornerB.v }
        
        var maxV = cornerB.v
        if cornerA.v > cornerB.v   { maxV = cornerA.v }
        
        self.rangeV = ClosedRange<Double>(uncheckedBounds: (lower: minV, upper: maxV))

    }
    
    
    /// See if a trial point is in the neighborhood.
    public func isIn(trial: PointSurf) -> Bool   {
        
        let flagU = rangeU.contains(trial.u)
        let flagV = rangeV.contains(trial.v)
        
        return flagU && flagV
    }
    
}
