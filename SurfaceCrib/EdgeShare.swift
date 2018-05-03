//
//  EdgeShare.swift
//  SurfaceCrib
//
//  Created by Paul on 9/4/17.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

/// Document the topology across a triangle edge
/// Should this class be collocated with the definition of "Mesh"?
public struct EdgeShare: Hashable   {
    
    public var commonA: Point3D   // No significance to the ordering
    public var commonB: Point3D
    
    /// The co-owners
    private var ref1: Facet?   // No significance to the ordering
    private var ref2: Facet?
    
    
    
    /// Start working on one
    init(ptA: Point3D, ptB: Point3D)   {
        
        self.commonA = ptA
        self.commonB = ptB
        
        self.ref1 = nil
        self.ref2 = nil
    }
    
    /// Simple accessor
    func getRef1() -> Facet?   {
        return ref1
    }
    
    /// Simple accessor
    func getRef2() -> Facet?   {
        return ref2
    }
    
    /// Fill in the next half of the relationship
    /// This is deliberately the only way to insert values in ref1 and ref2
    /// - Parameters:
    ///   - wilson:  Neighboring facet
    /// - Throws: EdgeOverflowError if this is an attempted third edge
    public mutating func addMate(wilson: Facet) throws -> Void   {
        
        guard self.ref2 == nil  else  { throw EdgeOverflowError(dupeEndA: commonA, dupeEndB: commonB) }
        
        if self.ref1 != nil   {
            self.ref2 = wilson
        }  else  {
            self.ref1 = wilson
        }
        
    }
    
    
    /// Simple check
//    public static func contains(share: EdgeShare, fence: HashEdge) -> Bool   {
//        
//        return share.rail == fence
//    }
    
    
    /// Generate the unique value
    public var hashValue: Int   {
        
        get  {
            
            var divX = commonA.x / Mesh.Epsilon
            let myX = Int(round(divX))
            
            var divY = commonA.y / Mesh.Epsilon
            let myY = Int(round(divY))
            
            var divZ = commonA.z / Mesh.Epsilon
            let myZ = Int(round(divZ))
            
            divX = commonB.x / Mesh.Epsilon
            let secondX = Int(round(divX))
            
            divY = commonB.y / Mesh.Epsilon
            let secondY = Int(round(divY))
            
            divZ = commonB.z / Mesh.Epsilon
            let secondZ = Int(round(divZ))
            
            return myX.hashValue + myY.hashValue + myZ.hashValue + secondX.hashValue + secondY.hashValue + secondZ.hashValue
        }
    }
    
}


/// Check to see that both edges use the same points, independent of ordering
/// These seem like strange functions to have for something Hashable,
/// but Hashable is a child of Equatable
public func == (lhs: EdgeShare, rhs: EdgeShare) -> Bool   {
    
    var separationA = Point3D.dist(pt1: lhs.commonA, pt2: rhs.commonA)
    var separationB = Point3D.dist(pt1: lhs.commonB, pt2: rhs.commonB)
    
    let forward = separationA < Point3D.Epsilon  &&  separationB < Point3D.Epsilon
    
    separationA = Point3D.dist(pt1: lhs.commonA, pt2: rhs.commonB)
    separationB = Point3D.dist(pt1: lhs.commonB, pt2: rhs.commonA)
    
    let backward = separationA < Point3D.Epsilon  &&  separationB < Point3D.Epsilon
    
    return forward || backward
}


/// Verify that the two edges are distinct
public func != (lhs: EdgeShare, rhs: EdgeShare) -> Bool   {
    
    var separationA = Point3D.dist(pt1: lhs.commonA, pt2: rhs.commonA)
    var separationB = Point3D.dist(pt1: lhs.commonB, pt2: rhs.commonB)
    
    let forward = separationA > Point3D.Epsilon  ||  separationB > Point3D.Epsilon
    
    separationA = Point3D.dist(pt1: lhs.commonA, pt2: rhs.commonB)
    separationB = Point3D.dist(pt1: lhs.commonB, pt2: rhs.commonA)
    
    let backward = separationA > Point3D.Epsilon  ||  separationB > Point3D.Epsilon
    
    
    return forward && backward
}
