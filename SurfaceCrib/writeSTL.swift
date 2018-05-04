//
//  writeSTL.swift
//  SurfaceCrib
//
//  Created by Paul on 8/31/15.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.
//

import Foundation

// The label "vertex" makes it a bad idea to do this as Printable for Point3D
func vertexString(pt: Point3D) -> String   {
    
    let str1 = String(format: "%0.3f", pt.x)
    let str2 = String(format: "%0.3f", pt.y)
    let str3 = String(format: "%0.3f", pt.z)
    
    let vertexLine = "         vertex  " + str1 + "  " + str2 + "  " + str3 + "\n"
    
    return vertexLine
}

/// Creates the "facet" header and perpendicular normal data
func normalString(vect: Vector3D) -> String   {
    
    let str1 = String(format: "%0.3f", vect.i)
    let str2 = String(format: "%0.3f", vect.j)
    let str3 = String(format: "%0.3f", vect.k)
    
    let normLine = "   facet normal  " + str1 + "  " + str2 + "  " + str3 + "\n"
    
    return normLine
}


func writeSTLText(fileName:  String, ptCloud: Array<Point3D>, trindices: Array<Int>)  {
    
    if let dir : NSURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.allDomainsMask).first as NSURL?  {
        
        let fileurl =  dir.appendingPathComponent(fileName)
        print(fileurl!.path)
        
        
        
        if FileManager.default.fileExists(atPath: fileurl!.path) {
            
            print(fileurl!.path)
            
            do {
                let fileHandle = try FileHandle(forWritingTo: fileurl!)
                
                //                  fileHandle.seekToEndOfFile()
                
                let openingStr = "solid Cheops\n"
                let closingStr = "endsolid\n"
                let loopAlpha = "      outer loop\n"
                let loopOmega = "      endloop\n"
                let facetOmega = "   endfacet\n"
                
                // Write to file
                print(openingStr)
                var data = openingStr.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                fileHandle.write(data)
                
                for i in stride(from: 0, to: trindices.count, by: 3)   {
                    
                    let ptA = ptCloud[trindices[i]]
                    let ptB = ptCloud[trindices[i+1]]
                    
                    var leg1 = Vector3D.built(from: ptA, towards: ptB)
                    leg1.normalize()
                    
                    let ptC = ptCloud[trindices[i+2]]
                    
                    var leg2 = Vector3D.built(from: ptB, towards: ptC)
                    leg2.normalize()
                    
                    var flagpole = try! Vector3D.crossProduct(lhs: leg1, rhs: leg2)
                    flagpole.normalize()
                    
                    let fLine = normalString(vect: flagpole)
                    //print(fLine)
                    data = fLine.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    fileHandle.write(data)
                    
                    //                        print(loopAlpha)
                    data = loopAlpha.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    fileHandle.write(data)
                    
                    
                    var vxString = vertexString(pt: ptA)
                    //                        print(vxString)
                    data = vxString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    fileHandle.write(data)
                    
                    vxString = vertexString(pt: ptB)
                    //                        print(vxString)
                    data = vxString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    fileHandle.write(data)
                    
                    vxString = vertexString(pt: ptC)
                    //                        print(vxString)
                    data = vxString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    fileHandle.write(data)
                    
                    //                        print(loopOmega)
                    data = loopOmega.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    fileHandle.write(data)
                    
                    //                        print (facetOmega)
                    data = facetOmega.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    fileHandle.write(data)
                    
                }    // Index traversal loop
                
                print(closingStr)
                data = closingStr.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                fileHandle.write(data)
                
                
                fileHandle.closeFile()
            }   // Outer do clause
                
            catch { print("Couldn't get a file handle")}
            
        }  // if file exists
        
    }   // if dir3
    
}   // func definition
