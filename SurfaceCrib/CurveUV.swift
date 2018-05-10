//
//  CurveUV.swift
//  SurfaceCrib
//
//  Created by Paul on 5/9/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// Curve used on a parametric surface
public class CubicUV   {
    
    var au: Double
    var bu: Double
    var cu: Double
    var du: Double
    
    var av: Double
    var bv: Double
    var cv: Double
    var dv: Double
    
    /// Acceptable values of t
    var range: ClosedRange<Double>
    
    /// The surface that holds this curve
    var residentSurf: Bicubic
    
    
    /// The direct constructor
    init(au: Double, bu: Double, cu: Double, du: Double, av: Double, bv: Double, cv: Double, dv: Double, surf: Bicubic)   {
        
        self.au = au
        self.bu = bu
        self.cu = cu
        self.du = du
        
        self.av = av
        self.bv = bv
        self.cv = cv
        self.dv = dv
        
        self.range = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
        self.residentSurf = surf
    }
    
    
    /// Build from end points and end slopes
    init(ptA: PointSurf, slopeA: VectorSurf, ptB: PointSurf, slopeB: VectorSurf, surf: Bicubic)   {
        
        self.au = 2.0 * ptA.u + slopeA.i - 2.0 * ptB.u + slopeB.i
        self.bu = -3.0 * ptA.u - 2.0 * slopeA.i + 3.0 * ptB.u - slopeB.i
        self.cu = slopeA.i
        self.du = ptA.u
        
        self.av = 2.0 * ptA.v + slopeA.j - 2.0 * ptB.v + slopeB.j
        self.bv = -3.0 * ptA.v - 2.0 * slopeA.j + 3.0 * ptB.v - slopeB.j
        self.cv = slopeA.j
        self.dv = ptA.v
        

        self.range = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
        self.residentSurf = surf
    }
    
    
    /// Modifies the range
    public func changeUpperBound(freshUpper: Double) throws -> Void   {
        
        guard freshUpper <= 1.0  &&  freshUpper > self.range.lowerBound  else  { throw ParameterRangeErrorUno(parA: freshUpper)}
        
        self.range = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: freshUpper))
    }
    
    
    /// Modifies the range
    public func changeLowerBound(freshLower: Double) throws -> Void   {
        
        guard freshLower >= 0.0  &&  freshLower < self.range.upperBound  else  { throw ParameterRangeErrorUno(parA: freshLower)}
        
        self.range = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: freshLower))
    }
    
    
    
    /// - Throws: ParameterRangeErrorUno if the input is out of range
    /// - Returns: PointSurf at parameter value
    public func pointAt(t: Double) throws -> PointSurf   {
        
        guard self.range.contains(t) else { throw ParameterRangeErrorUno(parA: t) }
        
        let t2 = t * t
        let t3 = t2 * t
        
        let myU = self.au * t3 + self.bu * t2 + self.cu * t + self.du
        let myV = self.av * t3 + self.bv * t2 + self.cv * t + self.dv
        
        return PointSurf(u: myU, v: myV)
    }
    
    
    /// Divide the curve while maintaining a maximum allowable crown
    /// - Returns: Array of Point3D
    public func split(allowableCrown: Double) -> [Point3D]   {
        
        let slices = 200
        
        var pips = [Point3D]()
        
        let low = self.range.lowerBound
        let high = self.range.upperBound

        let step = (high - low) / Double(slices)
        
        var curvePoint = try! self.pointAt(t: low)
        pips.append( try! residentSurf.pointAt(spot: curvePoint))
        
        
        let indices = [Int](0...slices)
        let tees = indices.map( { Double($0) * step} )
        let spots = tees.map( { try! self.pointAt(t: $0) } )
        
        /// Points along the curve
        let dots = spots.map( { try! residentSurf.pointAt(spot: $0) } )
        
        
        /// Initial boundaries for array slice
        var head = 0
        var tail = 2
        
        repeat   {
            
            /// The slice for the crown calculation
            let chunk = dots[head...tail]
            let hops = chunk.map( {$0} )
            
            let foundCrown = CubicUV.crownCalcs(dots: hops)
            
            if foundCrown > allowableCrown   {
                
                pips.append(hops[hops.count - 2])   // Capture the last acceptable point
                
                head = tail
                tail += 1   // Always have three points to use in calculation
                
            }
            
               // Prepare for the next iteration
            tail += 1
            
        } while tail < (slices + 1)
        
        
        curvePoint = try! self.pointAt(t: high)
        let caboose = try! residentSurf.pointAt(spot: curvePoint)
        
        if pips.last! != caboose   {   // Avoid a duplicate final point
            pips.append(caboose)
        }
        
        return pips
    }
    
    
    /// Caluclate deviation from a LineSeg
    public static func crownCalcs(dots: [Point3D]) -> Double   {
        
        let bar = try! LineSeg(end1: dots.first!, end2: dots.last!)
        
        let seps = dots.map( { bar.resolveRelative(speck: $0).perp.length() } )
        let curCrown = seps.max()!
        
        return curCrown
    }
    
    

}
