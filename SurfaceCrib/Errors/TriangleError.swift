//
//  TriangleError.swift
//  TriGen
//
//  Created by Paul Hollingshead on 9/3/17.
//  Copyright © 2017 Ceran Digital Media. All rights reserved.
//

import Foundation

/// Exception for when the points aren't unique
class TriangleError: Error {
    
    var ptA: Point3D
    
    var description: String {
        return "Coincident points were specified - no bueno! " + String(describing: ptA)
    }
    
    init(dupePt: Point3D)   {
        
        self.ptA = dupePt
        
    }
    
}
