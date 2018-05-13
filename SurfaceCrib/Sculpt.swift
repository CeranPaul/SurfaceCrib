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
        /// Static functions in the surface called by "Easel" to generate geometry.
        let iso = Bicubic.stripes(panel: board, count: 4)
        displayLines.append(contentsOf: iso)
        
        
        
           // Generate and display quills
           // This should become a static function of Bicubic
        let quillShow = false
        
        if quillShow   {
            
            for myU in stride(from: 0.0, to: 1.0001, by: 0.2)   {
                
                for myV in stride(from: 0.0, to: 1.0001, by: 0.2)   {
                    
                    let pip = PointSurf(u: myU, v: myV)
                    let root = try! board.pointAt(spot: pip)
                    let dir = try! board.normalAt(spot: pip)
                    
                    let tip = root.offset(jump: dir)
                    
                    let quill = try! LineSeg(end1: root, end2: tip)
                    displayLines.append(quill)
                    
                }  // Inner loop
            }   // Outer loop
            
        }   // End of if statement
        
        
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
        
        
           // Test the ability to find points on the intersection of the surface and a plane
        let nexus2 = Point3D(x: 1.55, y: 1.2, z: 1.0)
        var pole2 = Vector3D(i: 0.97, j: 0.2, k: 0.0)
        pole2.normalize()

        /// The cutting plane
        let sheet = try! Plane(spot: nexus2, arrow: pole2)

        
        /// Collection of points for making a curve from the intersection
        var posts = [PointSurf]()
        
        /// Desired accuracy for the intersection
        let accur8 = 0.001
        
        for g in 0...20   {
            
            /// Assume some constant value for 'v'
            let fixedV = 0.05 * Double(g)
            
            /// Initial value for range to check
            let whole = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
            
            
            if let refinedRange = board.crossing(blade: sheet, span: whole, inU: true, fixedParam: fixedV)   {
            
                /// Separation across the current parameter range
                var sep = accur8 * 5   // A large intial value
                
                /// The returned intersection point
                var hip: Point3D
                
                /// Point for the latest iteration
                var speck: PointSurf
                
                /// Working variable for the successively narrower ranges
                var span = refinedRange
                
                /// Limit to avoid a runaway loop.
                var backstop = 0
                
                repeat   {
                    
                    /// A smaller range of parameter values
                    let narrower = board.crossing(blade: sheet, span: span, inU: true, fixedParam: fixedV)!
                    
                    speck = PointSurf(u: narrower.lowerBound, v: fixedV)
                    hip = try! board.pointAt(spot: speck)
                    speck = PointSurf(u: narrower.upperBound, v: fixedV)
                    let hop = try! board.pointAt(spot: speck)
                    
                    sep = Point3D.dist(pt1: hip, pt2: hop)
                    
                    span = narrower
                    backstop += 1
                    
                } while sep > accur8  && backstop < 8
                
                posts.append(speck)   // Capture the point
                
//                let global = try! board.pointAt(spot: speck)
//                let dashes = Point3D.crosshair(pip: global)   // Illustrate the intersection point
//                displayLines.append(contentsOf: dashes)
            }
            
        }
        
        let fence = CubicUV.buildDots(dots: posts, surf: board)
        
        var dots = fence.split(allowableCrown: 0.003)
        
        for g in 1..<dots.count   {
            let wire = try! LineSeg(end1: dots[g - 1], end2: dots[g])
            displayLines.append(wire)
        }
        
        
        let hyar = PointSurf(u: 0.60, v: 0.50)
        let yonder = PointSurf(u: 0.90, v: 0.60)
        
        let junct = board.pointWithinRange(blade: sheet, rangeEndA: hyar, rangeEndB: yonder, accuracy: 0.001)

        let global = try! board.pointAt(spot: junct)
        let hairs = Point3D.crosshair(pip: global)   // Illustrate the intersection point
        displayLines.append(contentsOf: hairs)

        
        // Find the deviation over a delta u of 0.01.  Why is that worthwhile to know?
        let steadyV = 0.3

        for jump in stride(from: 0.0, through: 0.9, by: 0.10)   {

            let dotA = PointSurf(u: jump, v: steadyV)
            let anchorA = try! board.pointAt(spot: dotA)
            let dotB = PointSurf(u: jump + 0.1, v: steadyV)
            let anchorB = try! board.pointAt(spot: dotB)

            let wire = try! LineSeg(end1: anchorA, end2: anchorB)

            var deviation = 0.0

            for step in stride(from: jump + 0.01, through: jump + 0.09, by: 0.01)   {
                let speck = PointSurf(u: step, v: steadyV)
                let pip = try! board.pointAt(spot: speck)

                let diffs = wire.resolveRelative(speck: pip)

                let separation = diffs.perp.length()   // Always a positive value

                if separation > deviation   {
                    deviation = separation
                }

            }

            // print(deviation)
        }

        
        
        let alpha = PointSurf(u: 0.30, v: 0.20)
        let slope1 = VectorSurf(i: 1.0, j: 0.0)
        
        let beta = PointSurf(u: 0.70, v: 0.60)
        let slope2 = VectorSurf(i: 0.0, j: 1.0)
        
        let smear = CubicUV(ptA: alpha, slopeA: slope1, ptB: beta, slopeB: slope2, surf: board)
        
        dots = smear.split(allowableCrown: 0.003)
        
        for g in 1..<dots.count   {
            let wire = try! LineSeg(end1: dots[g - 1], end2: dots[g])
            displayLines.append(wire)
        }

        
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
    
    
    /// Generate the first surface for experimentation
    func generateSurf1() -> Bicubic   {
        
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
    
    /// Generate a set of points at a constant U
    func genStrip(surf: Bicubic, u: Double, thick: Double) -> (on: [Point3D], offset: [Point3D])   {
        
        /// Most recent points for sweeping in the U direction
        var upperEdge = [Point3D]()
        var lowerEdge = [Point3D]()
        
        
        // Build the left edge
        for g in stride(from: 0.0, through: 1.0, by: 0.10)   {
            
            var g2 = g   // Substitute that can be tweaked
            
            if g == 0.0   {
                g2 = 0.03
            }
            
            if g == 1.0   {
                g2 = 0.97
            }
            
            let speck = PointSurf(u: u, v: g2)
            let pip = try! surf.pointAt(spot: speck)
            upperEdge.append(pip)
            
            // Create a point offset inward by 'thick'
            let norm = try! surf.normalAt(spot: speck)
            let inwards = norm.reverse()
            
            let inset = inwards * thick
            let inPip = pip.offset(jump: inset)
            lowerEdge.append(inPip)
        }
        
        return (upperEdge, lowerEdge)
    }
    
}
