//
//  PointPair.swift
//  SurfaceCrib
//
//  Created by Paul on 5/20/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// Pair of surface points to be used for refining an intersection.
public struct PointPair: Hashable   {
    
    public var commonA: PointSurf   // No significance to the ordering
    public var commonB: PointSurf
    
    /// The co-owners
    private var ref1: Facet?   // No significance to the ordering
    private var ref2: Facet?
    
    
    
    /// Start working on one
    init(ptA: PointSurf, ptB: PointSurf)   {
        
        self.commonA = ptA
        self.commonB = ptB
        
        self.ref1 = nil
        self.ref2 = nil
    }
    
    
    
    /// Generate the unique value
    public var hashValue: Int   {
        
        get  {
            
            var divX = commonA.u / PointSurf.Epsilon
            let myX = Int(round(divX))
            
            var divY = commonA.v / PointSurf.Epsilon
            let myY = Int(round(divY))
            
            
            divX = commonB.u / PointSurf.Epsilon
            let secondX = Int(round(divX))
            
            divY = commonB.v / PointSurf.Epsilon
            let secondY = Int(round(divY))
            
            
            return myX.hashValue + myY.hashValue + secondX.hashValue + secondY.hashValue
        }
    }
    
}


/// Check to see that both edges use the same points, independent of ordering
/// These seem like strange functions to have for something Hashable,
/// but Hashable is a child of Equatable
public func == (lhs: PointPair, rhs: PointPair) -> Bool   {
    
    var separationA = PointSurf.dist(pt1: lhs.commonA, pt2: rhs.commonA)
    var separationB = PointSurf.dist(pt1: lhs.commonB, pt2: rhs.commonB)
    
    let forward = separationA < PointSurf.Epsilon  &&  separationB < PointSurf.Epsilon
    
    separationA = PointSurf.dist(pt1: lhs.commonA, pt2: rhs.commonB)
    separationB = PointSurf.dist(pt1: lhs.commonB, pt2: rhs.commonA)
    
    let backward = separationA < PointSurf.Epsilon  &&  separationB < PointSurf.Epsilon
    
    return forward || backward
}


/// Verify that the two edges are distinct
public func != (lhs: PointPair, rhs: PointPair) -> Bool   {
    
    var separationA = PointSurf.dist(pt1: lhs.commonA, pt2: rhs.commonA)
    var separationB = PointSurf.dist(pt1: lhs.commonB, pt2: rhs.commonB)
    
    let forward = separationA > PointSurf.Epsilon  ||  separationB > PointSurf.Epsilon
    
    separationA = PointSurf.dist(pt1: lhs.commonA, pt2: rhs.commonB)
    separationB = PointSurf.dist(pt1: lhs.commonB, pt2: rhs.commonA)
    
    let backward = separationA > PointSurf.Epsilon  ||  separationB > PointSurf.Epsilon
    
    
    return forward && backward
}
