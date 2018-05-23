//
//  SurfaceMesh.swift
//  SurfaceCrib
//
//  Created by Paul on 5/22/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation

public class SurfaceMesh   {
    
    /// Collection, not a Set, of points.
    var verts: [PointSurf]
    
    /// Indices to the verts array.  Used in groups of three.
    var xedni: [Int]
    
    /// The surface being represented
    var parent: Bicubic
    
    /// Definition of "equal" for point coordinates for this mesh.  Used if hashing is set up.
    /// Distinct from "allowableCrown", and Point3D.Epsilon
    public static let Epsilon = 0.001
    

    
    /// Bare bones constructor.
    init(surf: Bicubic)   {
        
        self.verts = [PointSurf]()
        
        self.xedni = [Int]()
        
        self.parent = surf
    }
    
    
    
    /// Accumulate a triangle.
    public func add(alpha: PointSurf, beta: PointSurf, gamma: PointSurf) -> Void   {
        
        self.verts.append(alpha)
        self.xedni.append(self.verts.count - 1)
        
        self.verts.append(beta)
        self.xedni.append(self.verts.count - 1)
        
        self.verts.append(gamma)
        self.xedni.append(self.verts.count - 1)
        
    }
    
    
    /// Find which member triangles have a common area with the target.
    public func overlap(target: ExtentUV) -> (pts: [PointSurf], ind: [Int])   {
        
        var pts = [PointSurf]()
        var ind = [Int]()
        
        for g in stride(from: 2, to: self.verts.count, by: 3)   {
            
            var triPts = [PointSurf]()
            
            triPts.append(self.verts[g - 2])
            triPts.append(self.verts[g - 1])
            triPts.append(self.verts[g])
            
            let trial = ExtentUV(spots: triPts)
            
            if ExtentUV.isOverlapping(lhs: target, rhs: trial)   {
                
                pts.append(triPts[0])
                ind.append(self.verts.count - 1)
                
                pts.append(triPts[1])
                ind.append(self.verts.count - 1)
                
                pts.append(triPts[2])
                ind.append(self.verts.count - 1)
                
           }
            
        }   // Iterate by threes
        
        
        return (pts, ind)
    }
    
}
