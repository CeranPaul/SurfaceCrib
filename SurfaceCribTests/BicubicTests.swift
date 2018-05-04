//
//  BicubicTests.swift
//  SurfaceCrib
//
//  Created by Paul on 5/25/17.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import XCTest
import simd

class BicubicTests: XCTestCase {
    
    var convex: Bicubic?
    
    override func setUp() {
        
        super.setUp()
        
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
        let qz24 = 2.5
        
        row2 = double4(qz21, qz22, qz23, qz24)
        mediary.append(row2)
        
        
        let qz31 = 0.0
        let qz32 = 0.0
        let qz33 = 0.0
        let qz34 = -0.8
        
        row3 = double4(qz31, qz32, qz33, qz34)
        mediary.append(row3)
        
        
        let qz41 = 0.0
        let qz42 = 2.2
        let qz43 = -1.0
        let qz44 = 0.95
        
        row4 = double4(qz41, qz42, qz43, qz44)
        mediary.append(row4)
        
        let qz = double4x4(mediary)
        
        
        convex = Bicubic(freshqx: qx, freshqy: qy, freshqz: qz)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPointAt()   {
    
        let target00 = Point3D(x: -1.5, y: -1.75, z: 0.95)
        var speck = PointSurf(u: 0.0, v: 0.0)
        let fred00 = try! convex!.pointAt(spot: speck)
        XCTAssertEqual(fred00, target00)
        
        let target01 = Point3D(x: -1.5, y: 1.75, z: 2.15)
        speck = PointSurf(u: 0.0, v: 1.0)
        let fred01 = try! convex!.pointAt(spot: speck)
        XCTAssertEqual(fred01, target01)
        
        let target10 = Point3D(x: 2.5, y: -1.75, z: 2.65)
        speck = PointSurf(u: 1.0, v: 0.0)
        let fred10 = try! convex!.pointAt(spot: speck)
        XCTAssertEqual(fred10, target10)
        
        let target11 = Point3D(x: 2.5, y: 1.75, z: 3.85)
        speck = PointSurf(u: 1.0, v: 1.0)
        let fred11 = try! convex!.pointAt(spot: speck)
        XCTAssertEqual(fred11, target11)
        
    }
    
    func testPartU() {
        
        var speck = PointSurf(u: 0.0, v: 0.0)
        let fred = try! convex!.partU(spot: speck)
        
        let outX = Vector3D(i: 4.0, j: 0.0, k: -0.8)
        
        XCTAssertEqual(fred, outX)
        
        speck = PointSurf(u: 1.0, v: 0.0)
        let fred2 = try! convex!.partU(spot: speck)
        
        let outX2 = Vector3D(i: 4.0, j: 0.0, k: 4.2)
        
        XCTAssertEqual(fred2, outX2)
        
    }
    
    func testPartV() {
        
        let speck = PointSurf(u: 0.0, v: 0.0)
        let fred = try! convex!.partV(spot: speck)
        
        let outX = Vector3D(i: 0.0, j: 3.5, k: -1.0)
        
        XCTAssertEqual(fred, outX)
        
        let fred2 = try! convex!.partV(spot: speck)
        
        let outX2 = Vector3D(i: 0.0, j: 3.5, k: -1.0)
        
        XCTAssertEqual(fred2, outX2)
    }
    
    func testNormal()   {
        
        let speck = PointSurf(u: 0.0, v: 0.0)
        let quill = try! convex!.normalAt(spot: speck)
        
        let target = Vector3D(i: 0.18884, j: 0.26977, k: 0.94422)
        
        XCTAssertEqual(quill, target)
    }
    
    func testIntersectLine()   {
        
        let nexus = Point3D(x: -0.5, y: -0.2, z: 0.1)
        var thataway = Vector3D(i: 0.5, j: 0.4, k: 0.6)
        thataway.normalize()
        
        let laser = try! Line(spot: nexus, arrow: thataway)
        
        let target = Point3D(x: 0.45377, y: 0.54865, z: 1.44786)

        let trial = try! Bicubic.intersectSurfLine(surf: convex!, arrow: laser)
        
        XCTAssertEqual(trial.spot, target)
    }
    
}
