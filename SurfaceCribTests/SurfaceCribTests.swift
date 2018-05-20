//
//  SurfaceCribTests.swift
//  SurfaceCribTests
//
//  Created by Paul on 1/1/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.
//

import XCTest
import simd

class SurfaceCribTests: XCTestCase {
    
    var convex: Bicubic?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        let nexus2 = Point3D(x: 2.05, y: 1.0, z: 1.0)
        var pole2 = Vector3D(i: -0.08, j: 0.83, k: 0.4)
        pole2.normalize()
        
        /// The cutting plane
        let sheet = try! Plane(spot: nexus2, arrow: pole2)
        
        self.measure {
            
            let rangeU = ClosedRange<Double>(uncheckedBounds: (lower: 0.0, upper: 0.5))
            let rangeV = ClosedRange<Double>(uncheckedBounds: (lower: 0.5, upper: 1.0))
            
            let crosses = Bicubic.changeGrid(surf: convex!, blade: sheet, rangeU: rangeU, rangeV: rangeV)
            
            // Put the code you want to measure the time of here.
        }
    }
    
}
