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
    var arena = CGRect(x: -2.0, y: -2.0, width: 4.0, height: 4.0)   // Will get replaced in "init"
    
    /// Rotation center
    var rotCenter = Point3D(x: 0.0, y: 0.0, z: 0.0)   // Will get replaced in "init"
    
    init()   {
        
        /// Build sample surface
        let board = generateSurf1()
        
        let brick = board.getExtent()
        
        rotCenter = brick.getRotCenter()
        
        let stretch = brick.getLongest()
        
        arena = CGRect(x: rotCenter.x - stretch / 2.0, y: rotCenter.y - stretch / 2.0, width: stretch, height: stretch)
        
        
        /// A set of isoparametric curves   There should a set of "PenTypes" to control surface display.
        /// Static functions in the surface called by "Easel" to generate geometry.
        let iso = Bicubic.stripes(panel: board, count: 4)
        displayLines.append(contentsOf: iso)
        
        
//           // Make some line segments that appear to be triangles for illustration
//           // This has nothing to do with allowable crown
//        for myV in stride(from: 0.0, through: 0.9, by: 0.1)   {
//
//            var prevDown = try! board.pointAt(u: 0.0, v: myV)
//            var prevUp = try! board.pointAt(u: 0.0, v: myV + 0.1)
//
//            let startingGate = try! LineSeg(end1: prevDown, end2: prevUp)
//            startingGate.setIntent(PenTypes.Mesh)
//            displayLines.append(startingGate)
//
//            for u in stride(from: 0.1, through: 1.0, by: 0.1)   {
//
//                let edgeDown = try! board.pointAt(u: u, v: myV)
//                let edgeUp = try! board.pointAt(u: u, v: myV + 0.1)
//
//                let bottom = try! LineSeg(end1: prevDown, end2: edgeDown)
//                bottom.setIntent(PenTypes.Mesh)
//                displayLines.append(bottom)
//
//                let top = try! LineSeg(end1: prevUp, end2: edgeUp)
//                top.setIntent(PenTypes.Mesh)
//                displayLines.append(top)
//
//                let cross = try! LineSeg(end1: edgeDown, end2: edgeUp)
//                cross.setIntent(PenTypes.Mesh)
//                displayLines.append(cross)
//
//                let diag = try! LineSeg(end1: prevDown, end2: edgeUp)
//                diag.setIntent(PenTypes.Mesh)
//                displayLines.append(diag)
//
//
//                prevDown = edgeDown   // Prepare for the next iteration
//                prevUp = edgeUp
//
//            }
//
//        }
        
           // Generate and display quills
           // This should become a static function of Bicubic
        let quillShow = false
        
        if quillShow   {
            
            for myU in stride(from: 0.0, to: 1.0001, by: 0.2)   {
                
                for myV in stride(from: 0.0, to: 1.0001, by: 0.2)   {
                    
                    let root = try! board.pointAt(u: myU, v: myV)
                    let dir = try! board.normalAt(u: myU, v: myV)
                    
                    let tip = root.offset(jump: dir)
                    
                    let quill = try! LineSeg(end1: root, end2: tip)
                    displayLines.append(quill)
                    
                }  // Inner loop
            }   // Outer loop
            
        }   // End of if statement
        
        
           // Show the intersection of a line with the surface
           // There are a million other tests that should be run
        let nexus = Point3D(x: -0.55, y: 0.3, z: 2.0)
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

        let dashes = Point3D.crosshair(pip: smack)
        displayLines.append(contentsOf: dashes)
        
        
//           // Test the ability to find points on the intersection of the surface and a plane
//        let nexus2 = Point3D(x: 1.0, y: 1.0, z: 1.0)
//        var pole2 = Vector3D(i: 0.707, j: 0.707, k: 0.0)
//        pole2.normalize()
//
//        let sheet = try! Plane(spot: nexus2, arrow: pole2)
//
//        /// Constant value for 'v'
//        let fixedV = 0.7
//
//        /// Initial value for range to check
//        let span = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 1.0))
//
//        let _ = board.crossing(sheet: sheet, span: span, inU: true, fixedParam: fixedV)
//
//
//        let steadyV = 0.3
//
//        for jump in stride(from: 0.0, through: 0.9, by: 0.10)   {
//
//            let anchorA = try! board.pointAt(u: jump, v: steadyV)
//            let anchorB = try! board.pointAt(u: jump + 0.1, v: steadyV)
//
//            let wire = try! LineSeg(end1: anchorA, end2: anchorB)
//
//            var deviation = 0.0
//
//            for step in stride(from: jump + 0.01, through: jump + 0.09, by: 0.01)   {
//                let pip = try! board.pointAt(u: step, v: steadyV)
//
//                let diffs = wire.resolveRelative(speck: pip)
//
//                let separation = diffs.perp.length()   // Always a positive value
//
//                if separation > deviation   {
//                    deviation = separation
//                }
//
//            }
//
//            //            print(deviation)
//        }
//
        
        
        // Hunt for the tangent point for a fillet
        
//        let ribHeight = 0.50
//
//        /// Half of the pillar thickness
//        let halfThick = 0.08
//
//        /// Fillet radius
//        let filletRad = 0.25
//
//        let allowableCrown = 0.001
//
//
//
//        /// Location for building a cross-section
//        var pillarU = 0.80
//        var pillarV = 0.03
//
//
//        /// Direction perpendicular to the cut
//        var cutDir = board.partV(u: pillarU, v: pillarV)
//        cutDir.normalize()
//
//        var flipFlag = true
//
//        /// Which side to do
//        var botPips = [Point3D]()
        
//        var vertsA = bladeSide(surf: board, pillarU: pillarU, pillarV: pillarV, cutDir: cutDir, halfThick: halfThick, filletRad: filletRad, allowableCrown: allowableCrown, ribHeight: ribHeight, flipFlag: flipFlag)
//
//        botPips.append(contentsOf: vertsA)
//
//
//        flipFlag = false
//
//        var vertsB = bladeSide(surf: board, pillarU: pillarU, pillarV: pillarV, cutDir: cutDir, halfThick: halfThick, filletRad: filletRad, allowableCrown: allowableCrown, ribHeight: ribHeight, flipFlag: flipFlag)
//
//        botPips.append(contentsOf: vertsB.reversed())
//
//
//        // Generate the last cross section
//
//        /// Location for building a cross-section
//        pillarU = 0.80
//        pillarV = 0.97
//
//        /// Direction perpendicular to the cut
//        cutDir = board.partV(u: pillarU, v: pillarV)
//        cutDir.normalize()
//
//        flipFlag = true
//
//        /// Which side to do
//        var topPips = [Point3D]()
//
//        vertsA = bladeSide(surf: board, pillarU: pillarU, pillarV: pillarV, cutDir: cutDir, halfThick: halfThick, filletRad: filletRad, allowableCrown: allowableCrown, ribHeight: ribHeight, flipFlag: flipFlag)
//
//        topPips.append(contentsOf: vertsA)
//
//
//        flipFlag = false
//
//        vertsB = bladeSide(surf: board, pillarU: pillarU, pillarV: pillarV, cutDir: cutDir, halfThick: halfThick, filletRad: filletRad, allowableCrown: allowableCrown, ribHeight: ribHeight, flipFlag: flipFlag)
//
//        topPips.append(contentsOf: vertsB.reversed())

        
//        /// Skin thickness
//        let thick = 0.20
//
//        /// Borders of the opening
//        var voidLeft = [Point3D]()
//        var voidRight = [Point3D]()
//
//        let lanes = genStrip(surf: board, u: 0.0, thick: thick)
//
//        var skinny = Mesh.skewLadderm1(port: lanes.on, starboard: lanes.offset)
//        try! ptCloud.absorb(noob: skinny)
//
//        var prevOn = lanes.on
//        var prevOffset = lanes.offset
        
//        for g in 1...10   {
//
//            let constU = Double(g) * 0.10
//
//               // Generate two more chains of points
//            let band = genStrip(surf: board, u: constU, thick: thick)
//
//               // Preserve points around the void
//            if g == 7   {
//                voidLeft = band.on
//            }
//
//            if g == 9   {
//                voidRight = band.on
//            }
//
//            if g != 8 && g != 9   {   // Skip columns near the stiffener
//                skinny = Mesh.skewLadderm1(port: band.on, starboard: prevOn)
//                try! ptCloud.absorb(noob: skinny)
//            }
//
//            skinny = Mesh.skewLadderm1(port: prevOffset, starboard: band.offset)
//            try! ptCloud.absorb(noob: skinny)
//
//
//            switch g {
//
//            case 8:
//
//                try! ptCloud.addPoints(ptA: prevOn.first!, ptB: prevOffset.first!, ptC: band.offset.first!)
//
//                ptCloud.append(band.offset.first!)
//                ptCloud.append(botPips.first!)
//                ptCloud.append(prevOn.first!)
//
//                ptCloud.append(band.offset.first!)
//                ptCloud.append(band.on.first!)
//                ptCloud.append(botPips.first!)
//
//
//                ptCloud.append(band.offset.last!)
//                ptCloud.append(prevOffset.last!)
//                ptCloud.append(prevOn.last!)
//
//                ptCloud.append(band.offset.last!)
//                ptCloud.append(prevOn.last!)
//                ptCloud.append(topPips.first!)
//
//                ptCloud.append(band.offset.last!)
//                ptCloud.append(topPips.first!)
//                ptCloud.append(band.on.last!)
//
//
//                var tnuoc = topPips.count
//
//                var curveCount = tnuoc / 2 - 1
//
//                for g in 1..<curveCount   {
//
//                    try! ptCloud.addPoints(ptA: topPips[g], ptB: band.on.last!, ptC: topPips[g - 1])
//
//                    ptCloud.append(topPips[tnuoc - g])
//                    ptCloud.append(band.on.last!)
//                    ptCloud.append(topPips[tnuoc - g - 1])
//
//                }
//
//                ptCloud.append(band.on.last!)
//                ptCloud.append(topPips[curveCount - 1])
//                ptCloud.append(topPips[curveCount + 2])
//
//                var flap = try! Mesh.meshFromFour(ptA: topPips[curveCount - 1], ptB: topPips[curveCount], ptC: topPips[curveCount + 1], ptD: topPips[curveCount + 2])
//
//                try! ptCloud.absorb(noob: flap)
//
//                tnuoc = botPips.count
//
//                curveCount = tnuoc / 2 - 1
//
//                for g in 1..<curveCount   {
//
//                    ptCloud.append(botPips[g])
//                    ptCloud.append(botPips[g - 1])
//                    ptCloud.append(band.on.first!)
//
//                    ptCloud.append(botPips[tnuoc - g])
//                    ptCloud.append(botPips[tnuoc - g - 1])
//                    ptCloud.append(band.on.first!)
//
//                }
//
//                ptCloud.append(band.on.first!)
//                ptCloud.append(botPips[curveCount + 2])
//                ptCloud.append(botPips[curveCount - 1])
//
//                flap = try! Mesh.meshFromFour(ptA: botPips[curveCount + 2], ptB: botPips[curveCount + 1], ptC: botPips[curveCount], ptD: botPips[curveCount - 1])
//
//                ptCloud.append(contentsOf: flap)
//
//           case 9:
//
//                ptCloud.append(band.offset.first!)
//                ptCloud.append(band.on.first!)
//                ptCloud.append(prevOffset.first!)
//
//                ptCloud.append(prevOffset.first!)
//                ptCloud.append(band.on.first!)
//                ptCloud.append(botPips.last!)
//
//                ptCloud.append(prevOffset.first!)
//                ptCloud.append(botPips.last!)
//                ptCloud.append(prevOn.first!)
//
//
//                ptCloud.append(band.offset.last!)
//                ptCloud.append(prevOffset.last!)
//                ptCloud.append(band.on.last!)
//
//                ptCloud.append(prevOffset.last!)
//                ptCloud.append(topPips.last!)
//                ptCloud.append(band.on.last!)
//
//                ptCloud.append(prevOffset.last!)
//                ptCloud.append(prevOn.last!)
//                ptCloud.append(topPips.last!)
//
//            default:
//
//                var cap = try! Mesh.meshFromFour(ptA: prevOn.last!, ptB: band.on.last!, ptC: band.offset.last!, ptD: prevOffset.last!)
//                try! ptCloud.absorb(noob: cap)
//
//                cap = try! Mesh.meshFromFour(ptA: prevOn.first!, ptB: prevOffset.first!, ptC: band.offset.first!, ptD: band.on.first!)
//                try! ptCloud.absorb(noob: cap)
//            }
//
//
//            if constU == 1.0   {   // Add the edge to the RH side
//                skinny = Mesh.skewLadderm1(port: band.offset, starboard: band.on)
//                ptCloud.append(contentsOf: skinny)
//            }
//
//            prevOn = band.on   // Prepare for the next iteration
//            prevOffset = band.offset
//        }


//
////        var prevNecklace = [Point3D]()
//        var midA = Point3D(x: 0.0, y: 0.0, z: 0.0)
//        var midB = Point3D(x: 0.0, y: 0.0, z: 0.0)
//
//        var prevNecklace = botPips
//
//        for g in 2...18   {
//
//            /// Location for building a cross-section
//            let pillarU = 0.80
//            let pillarV = Double(g) * 0.05
//
//            /// Direction perpendicular to the cut
//            var cutDir = board.partV(u: pillarU, v: pillarV)
//            cutDir.normalize()
//
//            var flipFlag = true
//
//            /// Which side to do
//            var pips = [Point3D]()
//
//            let vertsA = bladeSide(surf: board, pillarU: pillarU, pillarV: pillarV, cutDir: cutDir, halfThick: halfThick, filletRad: filletRad, allowableCrown: allowableCrown, ribHeight: ribHeight, flipFlag: flipFlag)
//
//            pips.append(contentsOf: vertsA)
//
//
//            flipFlag = false
//
//            let vertsB = bladeSide(surf: board, pillarU: pillarU, pillarV: pillarV, cutDir: cutDir, halfThick: halfThick, filletRad: filletRad, allowableCrown: allowableCrown, ribHeight: ribHeight, flipFlag: flipFlag)
//
//            pips.append(contentsOf: vertsB.reversed())
//
//
//
//            let hump = Mesh.skewLadderm1(port: prevNecklace, starboard: pips)
//            try! ptCloud.absorb(noob: hump)
//
//
//            let gOdd = g % 2
//
//            switch gOdd  {
//
//            case 0:
//
//                if g > 3   {
//
//                    ptCloud.append(pips.last!)
//                    ptCloud.append(midB)
//                    ptCloud.append(voidRight[g / 2])
//
//                    ptCloud.append(midB)
//                    ptCloud.append(voidRight[g / 2 - 1])
//                    ptCloud.append(voidRight[g / 2])
//
//                    ptCloud.append(pips.first!)
//                    ptCloud.append(voidLeft[g / 2])
//                    ptCloud.append(midA)
//
//                    ptCloud.append(midA)
//                    ptCloud.append(voidLeft[g / 2])
//                    ptCloud.append(voidLeft[g / 2 - 1])
//
//                }  else  {
//
//                    ptCloud.append(pips.last!)
//                    ptCloud.append(botPips.last!)
//                    ptCloud.append(voidRight[0])
//
//                    ptCloud.append(pips.last!)
//                    ptCloud.append(voidRight[0])
//                    ptCloud.append(voidRight[1])
//
//                    ptCloud.append(pips.first!)
//                    ptCloud.append(voidLeft[0])
//                    ptCloud.append(botPips.first!)
//
//                    ptCloud.append(pips.first!)
//                    ptCloud.append(voidLeft[1])
//                    ptCloud.append(voidLeft[0])
//
//                }
//
//
//            case 1:
//                midA = pips.first!
//                midB = pips.last!
//
//                ptCloud.append(midB)
//                ptCloud.append(prevNecklace.last!)
//                ptCloud.append(voidRight[g / 2])
//
//                ptCloud.append(midA)
//                ptCloud.append(voidLeft[g / 2])
//                ptCloud.append(prevNecklace.first!)
//
//
//            default:
//                midA = pips.first!   // These should never get executed
//                midB = pips.last!
//            }
//
//            if g == 18   {   // Fill the last tile
//                var tile = try! Mesh.meshFromFour(ptA: pips.last!, ptB: voidRight[voidRight.count - 2], ptC: voidRight.last!, ptD: topPips.last!)
//
//                try! ptCloud.absorb(noob: tile)
//
//                tile = try! Mesh.meshFromFour(ptA: voidLeft[voidLeft.count - 2], ptB: pips.first!, ptC: topPips.first!, ptD: voidLeft.last!)
//
//                try! ptCloud.absorb(noob: tile)
//           }
//
//
//            prevNecklace = pips   // Prepare for the next iteration
//
//
//        }   // Generate most of the cross sections
//
//
//        print(prevNecklace.count)
//        print(topPips.count)
//        let hump = Mesh.skewLadderm1(port: prevNecklace, starboard: topPips)
//        ptCloud.append(contentsOf: hump)
//
//
//        let streamers = HashEdge.statusDisplay(vertices: ptCloud)
//        displayLines.append(contentsOf: streamers)
//
//        print(ptCloud.count)
//
//
//        var ptSet = Set<Point3D>()
//
//        for pip in ptCloud   {
//            ptSet.insert(pip)
//        }
//
//        print(ptSet.count)
//
//        let pointCloud = Array(ptSet)
//
//        var triIndices = [Int]()
//
//        for pip in ptCloud   {
//
//            if let reference = pointCloud.index(of: pip) {
//                triIndices.append(reference)
//            }
//
//        }
//
//
//        writeSTLText(fileName: "curvStif.txt", ptCloud: pointCloud, trindices: triIndices)
        
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
            
            
            let pip = try! surf.pointAt(u: u, v: g2)
            upperEdge.append(pip)
            
            // Create a point offset inward by 'thick'
            let norm = try! surf.normalAt(u: u, v: g2)
            let inwards = norm.reverse()
            
            let inset = inwards * thick
            let inPip = pip.offset(jump: inset)
            lowerEdge.append(inPip)
        }
        
        return (upperEdge, lowerEdge)
    }
    
    
    /// Generate points for a half-slice
//    func bladeSide(surf: Bicubic, pillarU: Double, pillarV: Double, cutDir: Vector3D, halfThick: Double, filletRad: Double, allowableCrown: Double, ribHeight: Double, flipFlag: Bool) -> [Point3D]   {
//        
//        /// The points for a half-slice
//        var pearls = [Point3D]()
//        
//        /// Three points that define the fillet
//        let takeoff = Bicubic.searchFillet(surf: surf, pillarU: pillarU, pillarV: pillarV, cutDir: cutDir, halfThick: halfThick, filletRad: filletRad, flip: flipFlag)
//        
//        
//           // Much of this should become an Arc function
//        var vecSurf = Vector3D.built(from: takeoff.filletCtr, towards: takeoff.surfTan)
//        vecSurf.normalize()
//        
//        var vecUp = Vector3D.built(from: takeoff.filletCtr, towards: takeoff.uprightTan)
//        vecUp.normalize()
//        
//        let bar = Vector3D.dotProduct(lhs: vecSurf, rhs: vecUp)
//        
//        let foo = 1.0 - allowableCrown / filletRad
//        
//        let halfAngle = acos(foo)
//        
//        let angleStep = 2.0 * halfAngle
//        
//        let sweep = acos(bar)
//        let facets = ceil(sweep / angleStep)
//        
//        
//        let hook = try! Arc(center: takeoff.filletCtr, end1: takeoff.surfTan, end2: takeoff.uprightTan, useSmallAngle: true)
//        
//        
//        let arcStep = 1.0 / facets
//        
//        pearls.append(takeoff.surfTan)
//        
//        for c in 1..<Int(facets)   {   // Should this become a 'map'?
//            
//            let freshPoint = try! hook.pointAt(t: Double(c) * arcStep)
//            pearls.append(freshPoint)
//        }
//        
//        pearls.append(takeoff.uprightTan)
//        
//        
//        /// The base point for the section
//        let filletRoot = try! surf.pointAt(u: pillarU, v: pillarV)
//        
//        /// Normal at point chosen for fillet
//        let rocket = surf.normalAt(u: pillarU, v: pillarV)
//        
//        let jump2 = rocket * ribHeight
//        
//        let tip = filletRoot.offset(jump: jump2)
//        
//        
//        var crossThk = try! Vector3D.crossProduct(lhs: cutDir, rhs: rocket)
//        crossThk.normalize()
//        
//        if flipFlag   {
//            crossThk = crossThk.reverse()
//        }
//        
//        let jump3 = crossThk * halfThick
//        
//        /// Top of the stiffener
//        let cliff = tip.offset(jump: jump3)
//        pearls.append(cliff)
//        
//        return pearls
//    }
    
}
