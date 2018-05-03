//
//  Facet.swift
//  SurfaceCrib
//
//  Created by Paul on 9/6/17.
//  Copyright © 2017 Ceran Digital Media. All rights reserved.
//

import Foundation

/// A triangle with additional functions
public struct Facet   {
    
    /// The geometry
    private var vertA: Point3D   // To block new values that have skipped the integrity checks
    private var vertB: Point3D
    private var vertC: Point3D
    

    /// Flag for filtering
    var surrounded = false

    
    
    /// Ordering of vertices defines the normal direction
    /// - Parameters:
    ///   - ptA:  One vertex
    ///   - ptB:  Another vertex
    ///   - ptC:  Final vertex
    /// - Throws: CoincidentPointsError if any of the vertices are duplicates
    /// - Throws: TriangleError if the vertices are linear
    /// - See: 'testFidelity' and 'testCoincidence' under FacetTests
    init(ptA: Point3D, ptB: Point3D, ptC: Point3D) throws   {
        
        // Be certain that they are distinct points
        guard Point3D.isThreeUnique(alpha: ptA, beta: ptB, gamma: ptC) else { throw CoincidentPointsError(dupePt: ptB) }
        
        // Ensure that the points are not linear
        guard !Point3D.isThreeLinear(alpha: ptA, beta: ptB, gamma: ptC) else { throw TriangleError(dupePt: ptB) }
        
        
        self.vertA = ptA
        self.vertB = ptB
        self.vertC = ptC

    }
    
    
    
    /// Simple accessor
    public func getVertA() -> Point3D   {
        return self.vertA
    }
    
    /// Simple accessor
    public func getVertB() -> Point3D   {
        return self.vertB
    }
    
    /// Simple accessor
    public func getVertC() -> Point3D   {
        return self.vertC
    }
    
    /// Duplicate, move, rotate, and scale by a matrix
    /// - Throws: CoincidentPointsError or TriangleError if it was scaled to be very small
    /// - Returns: A sparkling new Facet
    public func dupeMove(xirtam: Transform) throws -> Facet {
        
        let tVertA = self.vertA.transform(xirtam: xirtam)
        let tVertB = self.vertB.transform(xirtam: xirtam)
        let tVertC = self.vertC.transform(xirtam: xirtam)

        let transformed = try Facet(ptA: tVertA, ptB: tVertB, ptC: tVertC)
        
        return transformed
    }
    
    /// Change the order of vertices to generate the opposite normal
    public mutating func reverse() -> Void   {
        
        let bubble = self.vertB
        self.vertB = self.vertC
        self.vertC = bubble
        
    }
    
    
    
    
    /// Get the volume that bounds the figure
    /// What to do when the triangle lies parallel to one of the coordinate planes?
    /// - Parameters:
    ///   - tricorner:  Triangle of interest
    /// - Returns: A box aligned to the coordinate system
    public static func getExtent(tricorner: Facet) -> OrthoVol  {
        
        let leastX = min(tricorner.vertA.x, tricorner.vertB.x, tricorner.vertC.x)
        let mostX = max(tricorner.vertA.x, tricorner.vertB.x, tricorner.vertC.x)
        
        let leastY = min(tricorner.vertA.y, tricorner.vertB.y, tricorner.vertC.y)
        let mostY = max(tricorner.vertA.y, tricorner.vertB.y, tricorner.vertC.y)
        
        let leastZ = min(tricorner.vertA.z, tricorner.vertB.z, tricorner.vertC.z)
        let mostZ = max(tricorner.vertA.z, tricorner.vertB.z, tricorner.vertC.z)
        
        let box = OrthoVol(minX: leastX, maxX: mostX, minY: leastY, maxY: mostY, minZ: leastZ, maxZ: mostZ)
        
        return box
    }
    
    /// Calculate the cross product of two edge directions
    /// Assumes that the vertices are unique, and not linear
    /// - Parameters:
    ///   - tricorner:  Triangle of interest
    /// - Returns: Normalized vector pointing outwards
    /// - Throws: TriangleError if the vertices somehow got corrupted
    public static func genNormal(tricorner: Facet) throws -> Vector3D  {
        
        do   {
            
            let firstDir = Vector3D.built(from: tricorner.vertA, towards: tricorner.vertB)
            let secondDir = Vector3D.built(from: tricorner.vertB, towards: tricorner.vertC)
            
            var upwards =  try Vector3D.crossProduct(lhs: firstDir, rhs: secondDir)
            upwards.normalize()
            
            return upwards
            
        }  catch  {
            throw TriangleError(dupePt: tricorner.vertB)   // The constructor checks should keep this from happening
        }
        
    }
    
    // TODO: Determine IF this one and a plane intersect
    // TODO: Find the line of intersection with a plane
    // TODO: Calculate area
    // TODO: Code an order independent equality check
    
}
