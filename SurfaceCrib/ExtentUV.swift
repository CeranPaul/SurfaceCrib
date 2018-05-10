//
//  ExtentUV.swift
//  SurfaceCrib
//
//  Created by Paul on 5/10/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// Rectangular area - probably not the minimum area
public struct ExtentUV   {
    
    var rangeU: ClosedRange<Double>
    var rangeV: ClosedRange<Double>
    
    
    /// Find the enclosing area for an Array of points
    init(spots: [PointSurf]) {
        
        let uValues = spots.map( { $0.u } )
        let vValues = spots.map( { $0.v } )
        
        let leastU = uValues.min()!
        let mostU = uValues.max()!
        
        let leastV = vValues.min()!
        let mostV = vValues.max()!
        
        rangeU = ClosedRange(uncheckedBounds: (lower: leastU, upper: mostU))
        rangeV = ClosedRange(uncheckedBounds: (lower: leastV, upper: mostV))
        
    }
    

}
