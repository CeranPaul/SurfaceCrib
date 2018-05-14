//
//  CurveUV.swift
//  SurfaceCrib
//
//  Created by Paul on 5/9/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation
import simd

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
    
    /// Build from four points
    init(alpha: PointSurf, beta: PointSurf, betaFraction: Double, gamma: PointSurf, gammaFraction: Double, delta: PointSurf, surf: Bicubic)   {
        
           // Rearrange coordinates into an array
        let rowU = double4(alpha.u, beta.u, gamma.u, delta.u)
        let rowV = double4(alpha.v, beta.v, gamma.v, delta.v)
        
           // Build a 4x4 of parameter values to various powers
        let row1 = double4(0.0, 0.0, 0.0, 1.0)
        
        let betaFraction2 = betaFraction * betaFraction
        let row2 = double4(betaFraction * betaFraction2, betaFraction2, betaFraction, 1.0)
        
        let gammaFraction2 = gammaFraction * gammaFraction
        let row3 = double4(gammaFraction * gammaFraction2, gammaFraction2, gammaFraction, 1.0)
        
        let row4 = double4(1.0, 1.0, 1.0, 1.0)
        
        
        /// Intermediate collection for building the matrix
        var partial: [double4]
        partial = [row1, row2, row3, row4]
        
        /// Matrix of t from several points raised to various powers
        let tPowers = double4x4(partial)
        
        let trans = tPowers.transpose   // simd representation is different than what I had in college
        
        
        /// Inverse of the above matrix
        let nvers = trans.inverse
        
        let coeffU = nvers * rowU
        let coeffV = nvers * rowV
        
        
        // Set the curve coefficients
        self.au = coeffU[0]
        self.bu = coeffU[1]
        self.cu = coeffU[2]
        self.du = coeffU[3]
        self.av = coeffV[0]
        self.bv = coeffV[1]
        self.cv = coeffV[2]
        self.dv = coeffV[3]
        
        
        self.range = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
        
        self.residentSurf = surf
    }
    
    
    /// Build a curve from an Array of points
    public static func buildDots(dots: [PointSurf], surf: Bicubic) -> CubicUV  {
        
        var overallLength = 0.0
        
        for g in 1..<dots.count   {
            
            let hither = try! surf.pointAt(spot: dots[g - 1])
            let yon = try! surf.pointAt(spot: dots[g])
            overallLength += Point3D.dist(pt1: hither, pt2: yon)
        }
        
        let act2 = dots.count / 3
        let act3 = dots.count * 2 / 3
        
        var act1Length = 0.0
        
        for g in 1..<act2   {
            
            let hither = try! surf.pointAt(spot: dots[g - 1])
            let yon = try! surf.pointAt(spot: dots[g])
            act1Length += Point3D.dist(pt1: hither, pt2: yon)
        }
        
        let fraction1 = act1Length / overallLength
        
        
        var act2Length = act1Length
        
        for g in act2..<act3   {
            
            let hither = try! surf.pointAt(spot: dots[g - 1])
            let yon = try! surf.pointAt(spot: dots[g])
            act2Length += Point3D.dist(pt1: hither, pt2: yon)
        }

        let fraction2 = act2Length / overallLength
        

        let swoosh = CubicUV.init(alpha: dots.first!, beta: dots[act2], betaFraction: fraction1, gamma: dots[act3], gammaFraction: fraction2, delta: dots.last!, surf: surf)
        
        return swoosh
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
        
        /// Gate for filtering numerical errors
        let precision = 0.00001
        
        let t2 = t * t
        let t3 = t2 * t
        
        var myU = self.au * t3 + self.bu * t2 + self.cu * t + self.du
        var myV = self.av * t3 + self.bv * t2 + self.cv * t + self.dv
        
        
           // Catch and throw out any small numerical errors
        if myU < 0.0   {
            if abs(myU) < precision   {
                myU = 0.0
            }  else  { throw ParameterRangeErrorDos(parA: myU, parB: myV) }
        }
        
        if myU > 1.0   {
            if (myU - 1.0) < precision   {
                myU = 1.0
            }  else  { throw ParameterRangeErrorDos(parA: myU, parB: myV) }
        }

        if myV < 0.0   {
            if abs(myV) < precision   {
                myV = 0.0
            }  else  { throw ParameterRangeErrorDos(parA: myU, parB: myV) }
        }
        
        if myV > 1.0   {
            if (myV - 1.0) < precision   {
                myV = 1.0
            }  else  { throw ParameterRangeErrorDos(parA: myU, parB: myV) }
        }
        

        return PointSurf(u: myU, v: myV)
    }
    
    
    /// Find an orthogonal box that surrounds the curve.
    /// - Returns: Rectangular box in UV
    public func getExtent() -> ExtentUV   {
        
        let pieces = 120
        
        let step = (self.range.upperBound - self.range.lowerBound) / Double(pieces)
        
        var dots = [PointSurf]()
        
        for g in 0...pieces   {
            
            let param = self.range.lowerBound + Double(g) * step
            let plop = try! self.pointAt(t: param)
            dots.append(plop)
            
        }
        
        let box = ExtentUV(spots: dots)
        return box
    }
    
    
    /// Divide the curve while maintaining a maximum allowable crown.
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
        
//        let badTees = tees.filter { $0 > 1.0 }
        let spots = tees.map( { try! self.pointAt(t: $0) } )
        
//        let badSpotsU = spots.filter { $0.u > 1.0 }
//        let badSpotsV = spots.filter { $0.v > 1.0 }

        
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
