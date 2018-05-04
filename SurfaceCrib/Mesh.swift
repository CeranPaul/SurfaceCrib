//
//  Mesh.swift
//  SurfaceCrib
//
//  Created by Paul on 9/4/17.
//  Copyright © 2018 Ceran Digital Media. All rights reserved. See LICENSE.md
//

import Foundation

/// Collection of Triangles with construction and checking tools.
/// Could represent only a portion of an object.
/// Will want to report the collection of unpaired edges.
public class Mesh   {
    
    /// Simple collection of flakes to define a (partial) boundary of a volume
    var scales: [Facet]
    
    /// Topology for the Triangles.  You want to build this as Facets are added.
    var edgeSet: Set<EdgeShare>
    
    /// Definition of "equal" for point coordinates for this mesh.  Used to hash in "EdgeShare".
    /// Should vary with measurement system used, and with model dimensions
    /// Should this be a variable set with the constructor?
    /// Distinct from "allowableCrown", and Point3D.Epsilon
    public static let Epsilon = 0.010   // Appropriate for millimeters
    

    /// Simple constructor.  Accumulation happens through 'add', and 'addPoints'.
    init()   {
        
        scales = [Facet]()
        
        /// The record of topology
        edgeSet = Set<EdgeShare>()
        
    }
    
    
    /// Welcome a new Facet to the club.  Definitely not thread safe!
    /// - Parameters:
    ///   - shiny:  The new Facet
    /// - Throws: EdgeOverflowError if one of these edges represents a third triangle
    /// - SeeAlso:  addPoints()
    func add(shiny: Facet) throws -> Void   {
        
        try recordEdge(ptAlpha: shiny.getVertA(), ptOmega: shiny.getVertB(), chip: shiny)
        try recordEdge(ptAlpha: shiny.getVertB(), ptOmega: shiny.getVertC(), chip: shiny)
        try recordEdge(ptAlpha: shiny.getVertC(), ptOmega: shiny.getVertA(), chip: shiny)
        
        scales.append(shiny)
    }
    
    
    /// Create or modify an EdgeShare to the Set for this mesh.  Definitely not thread safe!
    /// - Parameters:
    ///   - ptAlpha:  One end of the common edge
    ///   - ptOmega:  Other end of the common edge
    ///   - chip:  The fresh Facet that contains this edge
    /// - Throws: EdgeOverflowError if a third triangle was attempted
    /// - SeeAlso:  add()
    public func recordEdge(ptAlpha: Point3D, ptOmega: Point3D, chip: Facet) throws -> Void   {
        
        /// Shiny new EdgeShare
        var razor = EdgeShare(ptA: ptAlpha, ptB: ptOmega)
        
        if self.edgeSet.contains(razor)  {   // Modify an existing member
            
            let xedni = self.edgeSet.index(of: razor)
            var temp = self.edgeSet[xedni!]
            
            if temp.getRef2() != nil   { throw EdgeOverflowError(dupeEndA: ptAlpha, dupeEndB: ptOmega)  }
            
            self.edgeSet.remove(temp)
            try temp.addMate(wilson: chip)   // The 'if' statement should protect this
            self.edgeSet.insert(temp)
            
        }  else  {   // Insert the new EdgeShare
            try razor.addMate(wilson: chip)   // Low probability since this is brand new
            self.edgeSet.insert(razor)
        }
        
    }
    
    /// Combine two Meshes.
    /// Should this be done by overloading the '+' operator?
    public func absorb(noob: Mesh) throws -> Void   {
        
           // The way you want to do the combining means you can't use "formUnion"
        for hinge in noob.edgeSet   {
            
            if self.edgeSet.contains(hinge)    {
                
                if hinge.getRef2() == nil   {
                    
                    let xedni = self.edgeSet.index(of: hinge)
                    var temp = self.edgeSet[xedni!]
                    
                    if temp.getRef2() != nil   { throw EdgeOverflowError(dupeEndA: temp.commonA, dupeEndB: temp.commonB)  }
                    
                    self.edgeSet.remove(temp)
                    try temp.addMate(wilson: temp.getRef1()!)   // The 'if' statement should protect this
                    self.edgeSet.insert(temp)
                    
                 }  else  {
                    throw EdgeOverflowError(dupeEndA: hinge.commonA, dupeEndB: hinge.commonB)
                }
                
            }  else  {   // Not pre-existing
                self.edgeSet.insert(hinge)
            }
        }
        
        self.scales.append(contentsOf: noob.scales)   // Simple accumulation
        
    }
    
    // Will need to test for overlaps
    
    /// Find an edge among Facets already recorded
    //    func findExist(ptAlpha: Point3D, ptOmega: Point3D) -> Triangle  {
    //
    //    }
    
    
    /// Pile on a new Facet starting from three points
    /// - Parameters:
    ///   - ptA:  One vertex
    ///   - ptB:  Another vertex
    ///   - ptC:  Final vertex
    /// - Throws: CoincidentPointsError if any of the vertices are duplicates
    /// - Throws: TriangleError if the vertices are linear
    /// - SeeAlso:  add()
    func addPoints(ptA: Point3D, ptB: Point3D, ptC: Point3D) throws   {
        
        // Be certain that they are distinct points
        guard Point3D.isThreeUnique(alpha: ptA, beta: ptB, gamma: ptC) else { throw CoincidentPointsError(dupePt: ptB) }
        
        // Ensure that the points are not linear
        guard !Point3D.isThreeLinear(alpha: ptA, beta: ptB, gamma: ptC) else { throw TriangleError(dupePt: ptB) }
        
        let dorito = try Facet(ptA: ptA, ptB: ptB, ptC: ptC)
        
        try recordEdge(ptAlpha: ptA, ptOmega: ptB, chip: dorito)
        try recordEdge(ptAlpha: ptB, ptOmega: ptC, chip: dorito)
        try recordEdge(ptAlpha: ptC, ptOmega: ptA, chip: dorito)
        
        scales.append(dorito)
                    
    }
    
    /// Fill a strip with triangles.  Port and starboard are important to get triangle normals in the proper direction
    /// The chain counts may be different by one, in which case a wedge will be added at the finish
    /// This could certainly benefit from an illustration
    public static func skewLadderm1(port: [Point3D], starboard: [Point3D]) -> Mesh   {
        
        /// The triangle data that will be returned.
        let strip = Mesh()
        
        let portCount = port.count
        let starCount = starboard.count
        
        /// Default value for iterations
        var lesserCount = portCount
        
        /// Is there one more point in the starboard chain?
        var growing = true
        
        let equalCounts = (portCount == starCount)
        
        if !equalCounts {
            
            // Change some settings when the starboard array is smaller than the port array
            if starCount < portCount   {
                lesserCount = starCount
                growing = false
            }
        }
        
        for g in 1..<lesserCount   {
            let pair = try! meshFromFour(ptA: port[g - 1], ptB: port[g], ptC: starboard[g], ptD: starboard[g - 1])
            try! strip.absorb(noob: pair)
        }
        
         // Insert one wedge triangle, if needed
        if !equalCounts  {
            
            let wedgeCount = lesserCount - 1
            
            let extraA = starboard[wedgeCount]
            let extraB = port[wedgeCount]
            
            if growing   {
                try! strip.addPoints(ptA: extraA, ptB: extraB, ptC: starboard[wedgeCount + 1])
            }  else  {
                try! strip.addPoints(ptA: extraA, ptB: extraB, ptC: port[wedgeCount + 1])
            }
        }
        
        return strip
    }
    

    /// Transform a Mesh copy including the creation of new topology
    /// Should be thread safe
    /// - Parameters:
    ///   - source:  Mesh to be moved or rotated
    ///   - xirtam:  Combination of translation, rotation, and scaling to be applied
    /// - Returns: A shiny Mesh
    public static func transform(source: Mesh, xirtam: Transform) -> Mesh   {
        
        /// The new Mesh to be returned
        let sparkling = Mesh()
        
        for chip in source.scales   {
            
            /// Transformed vertices
            let transA = chip.getVertA().transform(xirtam: xirtam)
            let transB = chip.getVertB().transform(xirtam: xirtam)
            let transC = chip.getVertC().transform(xirtam: xirtam)

            try! sparkling.addPoints(ptA: transA, ptB: transB, ptC: transC)
        }
        
        return sparkling
    }
    
    /// Return LineSegs for the edges that are used exactly twice
    public static func getMated(screen: Mesh) -> [LineSeg]   {
        
        /// Array to be returned
        var happy = [LineSeg]()
            
        for razor in screen.edgeSet   {
            
            if razor.getRef2() != nil   {
                let bar = try! LineSeg(end1: razor.commonA, end2: razor.commonB)
                happy.append(bar)
            }
        }
        
        return happy
    }
    
    /// Return LineSegs for the edges that are used only once
    public static func getBach(screen: Mesh) -> [LineSeg]   {
        
        /// Array to be returned
        var happy = [LineSeg]()
        
        for razor in screen.edgeSet   {
            
            if razor.getRef2() == nil   {
                let bar = try! LineSeg(end1: razor.commonA, end2: razor.commonB)
                happy.append(bar)
            }
        }
        
        return happy
    }
    
    /// Build a Mesh of two Facets from four points - using the shorter common edge
    /// Points are assumed to be in CCW order
    /// - Returns: Small Mesh
    /// Different than most other functions with this name
    /// - Throws: CoincidentPointsError if any of the vertices are duplicates
    /// - Throws: TriangleError if the vertices are linear
    /// - Throws: EdgeOverflowError if a third triangle was attempted
    public static func meshFromFour(ptA: Point3D, ptB: Point3D, ptC: Point3D, ptD: Point3D) throws -> Mesh   {
        
        /// Collection of triangle pairs being constructed
        let resultMesh = Mesh()
        
        let distanceAC = Point3D.dist(pt1: ptA, pt2: ptC)
        let distanceBD = Point3D.dist(pt1: ptB, pt2: ptD)
        
        /// Two chips from four points
        var flake1, flake2: Facet
        
        if distanceAC < distanceBD  {
            
            flake1 = try Facet(ptA: ptA, ptB: ptB, ptC: ptC)
            flake2 = try Facet(ptA: ptC, ptB: ptD, ptC: ptA)
            
        }  else  {
            
            flake1 = try Facet(ptA: ptB, ptB: ptC, ptC: ptD)
            flake2 = try Facet(ptA: ptD, ptB: ptA, ptC: ptB)
            
        }
        
        try resultMesh.add(shiny: flake1)
        try resultMesh.add(shiny: flake2)
        
        return resultMesh
    }

}



