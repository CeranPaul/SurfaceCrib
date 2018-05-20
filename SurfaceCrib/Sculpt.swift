//
//  Sculpt.swift
//  SurfaceCrib
//
//  Reworked by Paul starting on 1/1/18.
//  Copyright © 2018 Ceran Digital Media.  See LICENSE.md
//

import UIKit
import simd

/// Model geometry to be displayed
var modelGeo = Sculpt()

/// Experimenting with single parametric surfaces
class Sculpt   {

    /// Various LineSegs to be displayed
    var displayLines = [LineSeg]()

    /// Triangles that could be used for 3D printing
    var ptCloud = Mesh()
    
    /// Bounding area for play
    var arena = CGRect(x: -3.0, y: -3.0, width: 6.0, height: 6.0)   // Will get replaced in "init"
    
    /// Rotation center
    var rotCenter = Point3D(x: 0.0, y: 0.0, z: 0.0)   // Will get replaced in "init"
    
    
    init()   {
        
        /// Sample surface
        let board = generateSurf1()
        
        let brick = board.getExtent()
        
        rotCenter = brick.getRotCenter()
        
        let stretch = brick.getLongest()
        
        arena = CGRect(x: rotCenter.x - stretch / 1.5, y: rotCenter.y - stretch / 1.5, width: stretch * 1.333, height: stretch * 1.333)
        
        
        /// A set of isoparametric curves.   There should a set of "PenTypes" to control surface display.
        let iso = Bicubic.stripes(panel: board, count: 4)
        displayLines.append(contentsOf: iso)
        
        
        
           // Show the intersection of a line with the surface
           // There are a million other tests that should be run for this ability
        let nexus = Point3D(x: 0.55, y: -0.3, z: 2.0)
        var thataway = Vector3D(i: 0.2, j: -0.15, k: 0.6)
        thataway.normalize()

        let laser = try! Line(spot: nexus, arrow: thataway)

        var jump = thataway * 2.0
        let hither = nexus.offset(jump: jump)

        jump = thataway * -2.0
        let yon = nexus.offset(jump: jump)

        let pole = try! LineSeg(end1: hither, end2: yon)
        displayLines.append(pole)

        /// Intersection of line and surface
        let splash = try! Bicubic.intersectSurfLine(surf: board, arrow: laser)
        
        /// The intersection point
        let smack = splash.spot

        let dashes = Point3D.crosshair(pip: smack)   // Illustrate the intersection point
        displayLines.append(contentsOf: dashes)
        
        
        
           // Demonstrate the ability to build a curve on the intersection of the surface and a plane
//        let nexus2 = Point3D(x: 2.45, y: 1.2, z: 1.0)
//        var pole2 = Vector3D(i: 0.97, j: -0.20, k: 0.0)
        let nexus2 = Point3D(x: 2.05, y: 1.0, z: 1.0)
        var pole2 = Vector3D(i: -0.08, j: 0.83, k: 0.4)
        pole2.normalize()

        /// The cutting plane
        let sheet = try! Plane(spot: nexus2, arrow: pole2)

        
        if let fence = board.intersectPerp(blade: sheet, accuracy: 0.001)   {
            
            // Draw the curve
            var dots = fence.split(allowableCrown: 0.003)
            
            for g in 1..<dots.count   {
                let wire = try! LineSeg(end1: dots[g - 1], end2: dots[g])
                displayLines.append(wire)
            }
            
        }
        
        
           // Experimenting with a more brute force method of finding the intersection.
        
        let rangeU = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 0.5))
        let rangeV = ClosedRange<Double>(uncheckedBounds: (lower: 0.5, upper: 1.0))
        
        let crosses = Bicubic.changeGrid(surf: board, blade: sheet, rangeU: rangeU, rangeV: rangeV)
        displayLines.append(contentsOf: crosses)
        

        
           // Build a curve from two points and two slopes
        let alpha = PointSurf(u: 0.30, v: 0.20)
        let slope1 = VectorSurf(i: 1.0, j: 0.0)
        
        let beta = PointSurf(u: 0.70, v: 0.60)
        let slope2 = VectorSurf(i: 0.0, j: 1.0)
        
        let smear = CubicUV(ptA: alpha, slopeA: slope1, ptB: beta, slopeB: slope2, surf: board)
        
        var dots = smear.split(allowableCrown: 0.003)
        
        for g in 1..<dots.count   {
            let wire = try! LineSeg(end1: dots[g - 1], end2: dots[g])
            displayLines.append(wire)
        }

        
           // Build a curve from four points
        let ptA = PointSurf(u: 0.10, v: 0.55)
        let ptB = PointSurf(u: 0.24, v: 0.70)
        let fractionB = 0.34
        let ptC = PointSurf(u: 0.60, v: 0.82)
        let fractionC = 0.68

        let ptD = PointSurf(u: 0.70, v: 0.97)

        let arch = CubicUV(alpha: ptA, beta: ptB, betaFraction: fractionB, gamma: ptC, gammaFraction: fractionC, delta: ptD, surf: board)
        
        dots = arch.split(allowableCrown: 0.003)
        
        for g in 1..<dots.count   {
            let wire = try! LineSeg(end1: dots[g - 1], end2: dots[g])
            displayLines.append(wire)
        }
        
    }   // End of func init
    
    
    /// Generate a surface for experimentation
    private func generateSurf1() -> Bicubic   {
        
        /// Array used multiple times
        var mediary = [double4]()
        
        // Make the first row for the X value
        let qx11 = 0.0
        let qx12 = 0.0
        let qx13 = 0.0
        let qx14 = 0.0
        
        var row1 = double4(qx11, qx12, qx13, qx14)
        mediary.append(row1)
        
        
        let qx21 = 0.0
        let qx22 = 0.0
        let qx23 = 0.0
        let qx24 = 0.0
        
        var row2 = double4(qx21, qx22, qx23, qx24)
        mediary.append(row2)
        
        
        let qx31 = 0.0
        let qx32 = 0.0
        let qx33 = 0.0
        let qx34 = 4.0
        
        var row3 = double4(qx31, qx32, qx33, qx34)
        mediary.append(row3)
        
        
        let qx41 = 0.0
        let qx42 = 0.0
        let qx43 = 0.0
        let qx44 = -1.5
        
        var row4 = double4(qx41, qx42, qx43, qx44)
        mediary.append(row4)
        
        let qx = double4x4(mediary)
        
        
        mediary = [double4]()   // Clear the array
        
        // Make the first row for the Y value
        let qy11 = 0.0
        let qy12 = 0.0
        let qy13 = 0.0
        let qy14 = 0.0
        
        row1 = double4(qy11, qy12, qy13, qy14)
        mediary.append(row1)
        
        
        let qy21 = 0.0
        let qy22 = 0.0
        let qy23 = 0.0
        let qy24 = 0.0
        
        row2 = double4(qy21, qy22, qy23, qy24)
        mediary.append(row2)
        
        
        let qy31 = 0.0
        let qy32 = 0.0
        let qy33 = 0.0
        let qy34 = 0.0
        
        row3 = double4(qy31, qy32, qy33, qy34)
        mediary.append(row3)
        
        
        let qy41 = 0.0
        let qy42 = 0.0
        let qy43 = 3.5
        let qy44 = -1.75
        
        row4 = double4(qy41, qy42, qy43, qy44)
        mediary.append(row4)
        
        let qy = double4x4(mediary)
        
        mediary = [double4]()   // Clear the array
        
        // Make the first row for the Y value
        let qz11 = 0.0
        let qz12 = 0.0
        let qz13 = 0.0
        let qz14 = 0.0
        
        row1 = double4(qz11, qz12, qz13, qz14)
        mediary.append(row1)
        
        
        let qz21 = 0.0
        let qz22 = 0.0
        let qz23 = 0.0
        let qz24 = -1.8
        
        row2 = double4(qz21, qz22, qz23, qz24)
        mediary.append(row2)
        
        
        let qz31 = 0.0
        let qz32 = 0.0
        let qz33 = 0.0
        let qz34 = 0.8
        
        row3 = double4(qz31, qz32, qz33, qz34)
        mediary.append(row3)
        
        
        let qz41 = 0.0
        let qz42 = -0.9
        let qz43 = 1.0
        let qz44 = 0.95
        
        row4 = double4(qz41, qz42, qz43, qz44)
        mediary.append(row4)
        
        let qz = double4x4(mediary)
        
        
        let board = Bicubic(freshqx: qx, freshqy: qy, freshqz: qz)
        
        return board
    }
    
    
}
