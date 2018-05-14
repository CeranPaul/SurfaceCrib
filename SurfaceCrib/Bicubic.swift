//
//  Bicubic.swift
//  SurfaceCrib
//
//  Created by Paul on 5/23/17.
//  Copyright © 2018 Ceran Digital Media.  See LICENSE.md
//

import Foundation
import Accelerate
import simd

/// Surface defined by polynomials for u and v parameter directions.
/// Some notations show "s" and "t" as the parameters, instead of "u" and "v".
open class Bicubic   {
    
    // Three sets of 16 coefficients set up the way Foley and van Damm show it
    var qx, qy, qz: double4x4
    
    
    /// Most direct constructor
    init(freshqx: double4x4, freshqy: double4x4, freshqz: double4x4)   {
        
        self.qx = freshqx
        self.qy = freshqy
        self.qz = freshqz
        
    }
        
    
    /// Create a new Bicubic surface from 16 points and parameters
    /// - Parameters:
    ///   - params: Array of parameter pairs
    ///   - actual: Points for the new surface
    /// - Throws: SurfaceInputError if either input has a count not equal to 16
    /// - Returns: A Bicubic surface
    init(params: [PointSurf], actual: [Point3D]) throws   {
        
        guard params.count == 16  && actual.count == 16 else {throw SurfaceInputError(count: min(params.count, actual.count))}
        
        // Rearranged coordinate values
        var xCollect = [Float]()
        var yCollect = [Float]()
        var zCollect = [Float]()
        
        for g in 0...15   {   // Create coordinate vectors from input points
            
            let pip = actual[g]
            
            xCollect.append(Float(pip.x))
            yCollect.append(Float(pip.y))
            zCollect.append(Float(pip.z))
        }
        
        
        var paramM = Bicubic.genParamCol(params: params)   // This is the transpose of what Foley and van Damm describe
        
        
        // Make copies of the parameter matrix, because the solver destroys them
        var paramM2 = [Float]()
        var paramM3 = [Float]()
        var paramRock = [Float]()
        
        for phew in paramM   {
            paramM2.append(phew)
            paramM3.append(phew)
            paramRock.append(phew)
        }
        
        
        // Use LAPACK routines to solve
        typealias LAInt = __CLPK_integer
        
        let equations = 16
        var numberOfEquations: LAInt = 16
        var columnsInA:       LAInt = 16
        var elementsInB:      LAInt = 16
        var bSolutionCount:   LAInt = 1
        var outputOk: LAInt = 0
        var pivot = [LAInt](repeating: 0, count: equations)   // This is a new way to fill an array!
        
        // Danger, Will Robinson!  paramM gets modified when this routine is run
        sgesv_( &numberOfEquations, &bSolutionCount, &paramM, &columnsInA, &pivot, &xCollect, &elementsInB, &outputOk)
        
        /// Used in recording the solution for each direction
        var mediary = [double4]()
        
        /// Used throughout this function
        var row = double4(Double(xCollect[0]), Double(xCollect[1]), Double(xCollect[2]), Double(xCollect[3]))
        mediary.append(row)
        
        row = double4(Double(xCollect[4]), Double(xCollect[5]), Double(xCollect[6]), Double(xCollect[7]))
        mediary.append(row)
        
        row = double4(Double(xCollect[8]), Double(xCollect[9]), Double(xCollect[10]), Double(xCollect[11]))
        mediary.append(row)
        
        row = double4(Double(xCollect[12]), Double(xCollect[13]), Double(xCollect[14]), Double(xCollect[15]))
        mediary.append(row)
        
        /// The 4x4 of coefficients for X coordinates
        self.qx = double4x4(mediary)
        
        
        
        numberOfEquations = 16
        columnsInA = 16
        elementsInB = 16
        bSolutionCount = 1
        outputOk = 0
        pivot = [LAInt](repeating: 0, count: equations)   // This is a new way to fill an array!
        
        sgesv_( &numberOfEquations, &bSolutionCount, &paramM2, &columnsInA, &pivot, &yCollect, &elementsInB, &outputOk)
        
        
        mediary = [double4]()   // Make a clean instance
        
        row = double4(Double(yCollect[0]), Double(yCollect[1]), Double(yCollect[2]), Double(yCollect[3]))
        mediary.append(row)
        
        row = double4(Double(yCollect[4]), Double(yCollect[5]), Double(yCollect[6]), Double(yCollect[7]))
        mediary.append(row)
        
        row = double4(Double(yCollect[8]), Double(yCollect[9]), Double(yCollect[10]), Double(yCollect[11]))
        mediary.append(row)
        
        row = double4(Double(yCollect[12]), Double(yCollect[13]), Double(yCollect[14]), Double(yCollect[15]))
        mediary.append(row)
        
        self.qy = double4x4(mediary)
        
        
        numberOfEquations = 16
        columnsInA = 16
        elementsInB = 16
        bSolutionCount = 1
        outputOk = 0
        pivot = [LAInt](repeating: 0, count: equations)   // This is a new way to fill an array!
        
        sgesv_( &numberOfEquations, &bSolutionCount, &paramM3, &columnsInA, &pivot, &zCollect, &elementsInB, &outputOk)
        
        // If outputOK = 0, then everything went ok
        
        mediary = [double4]()   // Make a clean instance
        
        row = double4(Double(zCollect[0]), Double(zCollect[1]), Double(zCollect[2]), Double(zCollect[3]))
        mediary.append(row)
        
        row = double4(Double(zCollect[4]), Double(zCollect[5]), Double(zCollect[6]), Double(zCollect[7]))
        mediary.append(row)
        
        row = double4(Double(zCollect[8]), Double(zCollect[9]), Double(zCollect[10]), Double(zCollect[11]))
        mediary.append(row)
        
        row = double4(Double(zCollect[12]), Double(zCollect[13]), Double(zCollect[14]), Double(zCollect[15]))
        mediary.append(row)
        
        self.qz = double4x4(mediary)
        
    }
    
    
    /// Generate parameters as the transpose of the way Foley and van Damm suggest.
    private static func genParamCol(params: [PointSurf]) -> [Float]   {
        
        /// 16 x 16 collection of parameter values
        var paramCol = [Float]()
        
        for g in 0...15   {
            
            let u = params[g].u    // The order here is another place to check for an error
            let s = u
            let s2 = s * s
            let s3 = s2 * s
            
            let t = params[g].v
            let t2 = t * t
            let t3 = t2 * t
            
            paramCol.append(Float(s3 * t3))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            let s2 = s * s
            let s3 = s2 * s
            
            let t = params[g].v
            let t2 = t * t
            
            paramCol.append(Float(s3 * t2))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            let s2 = s * s
            let s3 = s2 * s
            
            let t = params[g].v
            
            paramCol.append(Float(s3 * t))
        }
        
        for g in 0...15   {
            
            let u = params[g].u    // The order here is another place to check for an error
            let s = u
            let s2 = s * s
            let s3 = s2 * s
            
            paramCol.append(Float(s3))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            let s2 = s * s
            
            let t = params[g].v
            let t2 = t * t
            let t3 = t2 * t
            
            paramCol.append(Float(s2 * t3))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            let s2 = s * s
            
            let t = params[g].v
            let t2 = t * t
            
            paramCol.append(Float(s2 * t2))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            let s2 = s * s
            
            let t = params[g].v
            
            paramCol.append(Float(s2 * t))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            let s2 = s * s
            
            paramCol.append(Float(s2))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            
            let t = params[g].v
            let t2 = t * t
            let t3 = t2 * t
            
            paramCol.append(Float(s * t3))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            
            let t = params[g].v
            let t2 = t * t
            
            paramCol.append(Float(s * t2))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            
            let t = params[g].v
            
            paramCol.append(Float(s * t))
        }
        
        for g in 0...15   {
            
            let u = params[g].u
            let s = u
            
            paramCol.append(Float(s))
        }
        
        for g in 0...15   {
            
            let t = params[g].v
            let t2 = t * t
            let t3 = t2 * t
            
            paramCol.append(Float(t3))
        }
        
        for g in 0...15   {
            
            let t = params[g].v
            let t2 = t * t
            
            paramCol.append(Float(t2))
        }
        
        for g in 0...15   {
            
            let t = params[g].v
            
            paramCol.append(Float(t))
        }
        
        for _ in 0...15   {
            
            paramCol.append(Float(1.0))
        }
        
        return paramCol
    }
    
    /// Supply the point on the surface for the input parameter values.
    /// The order of operations in simd forces the transpose to be done on the coefficient matrices
    /// - Throws:
    ///   - ParameterRangeErrorDos if either of the input parameters are out of range
    /// - Returns: The corresponding point
    public func pointAt(spot: PointSurf) throws -> Point3D   {
        
        guard spot.isInRange()  else   { throw ParameterRangeErrorDos(parA: spot.u, parB: spot.v) }
        
        let s = spot.u
        let s2 = s * s
        let s3 = s2 * s
        
        let sRow = double4(s3, s2, s, 1.0)
        
        let t = spot.v
        let t2 = t * t
        let t3 = t2 * t
        
        let tRow = double4(t3, t2, t, 1.0)
        
        
        let qxT = qx.transpose
        
        /// Partial result in the matrix operations
        var part = sRow * qxT
        
        let myX = dot(part, tRow)
        
        let qyT = qy.transpose
        part = sRow * qyT
        let myY = dot(part, tRow)
        
        let qzT = qz.transpose
        part = sRow * qzT
        let myZ = dot(part, tRow)
        
        
        return Point3D(x: myX, y: myY, z: myZ)
    }
    
    
    /// Calculate the proper surrounding box.
    /// Increase the number of intermediate points as necessary.
    public func getExtent() -> OrthoVol   {
        
        let pieces = 15
        let step = 1.0 / Double(pieces)
        
        var bucket = [Point3D]()
        
        for g in 0...pieces   {
            
            let iso = Double(g) * step
            
            for w in 0...pieces   {
                let spot = PointSurf(u: iso, v: Double(w) * step)
                let pip = try! self.pointAt(spot: spot)
                bucket.append(pip)
            }
            
        }
        
        let box = OrthoVol(spots: bucket)
        
        return box
    }
    
    
    /// Supply the partial derivative for the surface for the input parameter values
    /// Some notations show "s" and "t" as the parameters, instead of "u" and "v"
    /// - Parameters:
    ///   - u:  Parameter value for one direction.  Assumes 0 < u < 1
    ///   - v:  Parameter value for the other direction.  Assumes 0 < v < 1
    /// - Throws:
    ///   - ParameterRangeErrorDos if either of the input parameters are out of range
    /// - Returns: A non-normalized vector
    public func partU(spot: PointSurf) throws -> Vector3D   {
        
        guard spot.isInRange()  else   { throw ParameterRangeErrorDos(parA: spot.u, parB: spot.v) }
        
        let s = spot.u
        let s2 = s * s
        
        let sRow = double3(3.0 * s2, 2.0 * s, 1.0)
        
        let t = spot.v
        let t2 = t * t
        let t3 = t2 * t
        
        let tRow = double4(t3, t2, t, 1.0)
        
        let qxT = qx.transpose   // So simd will do the expected multiplication
        
        /// Holding pot for the original matrix minus the fourth column
        var mediary3 = [double3]()
        
        var shortRow0 = double3(qxT[0].x, qxT[0].y, qxT[0].z)
        mediary3.append(shortRow0)
        
        var shortRow1 = double3(qxT[1].x, qxT[1].y, qxT[1].z)
        mediary3.append(shortRow1)
        
        var shortRow2 = double3(qxT[2].x, qxT[2].y, qxT[2].z)
        mediary3.append(shortRow2)
        
        var shortRow3 = double3(qxT[3].x, qxT[3].y, qxT[3].z)
        mediary3.append(shortRow3)
        
        
        let shortQX = double4x3(mediary3)
        
        var middle = sRow * shortQX
        
        
        let myI = dot(middle, tRow)
        
        
        let qyT = qy.transpose   // So simd will do the expected multiplication
        
        mediary3 = [double3]()   // Clear the array
        
        shortRow0 = double3(qyT[0].x, qyT[0].y, qyT[0].z)
        mediary3.append(shortRow0)
        
        shortRow1 = double3(qyT[1].x, qyT[1].y, qyT[1].z)
        mediary3.append(shortRow1)
        
        shortRow2 = double3(qyT[2].x, qyT[2].y, qyT[2].z)
        mediary3.append(shortRow2)
        
        shortRow3 = double3(qyT[3].x, qyT[3].y, qyT[3].z)
        mediary3.append(shortRow3)
        
        let shortQY = double4x3(mediary3)
        
        middle = sRow * shortQY
        
        let myJ = dot(middle, tRow)
        
        
        
        let qzT = qz.transpose   // So simd will do the expected multiplication
        
        mediary3 = [double3]()   // Clear the array
        
        shortRow0 = double3(qzT[0].x, qzT[0].y, qzT[0].z)
        mediary3.append(shortRow0)
        
        
        shortRow1 = double3(qzT[1].x, qzT[1].y, qzT[1].z)
        mediary3.append(shortRow1)
        
        
        shortRow2 = double3(qzT[2].x, qzT[2].y, qzT[2].z)
        mediary3.append(shortRow2)
        
        shortRow3 = double3(qzT[3].x, qzT[3].y, qzT[3].z)
        mediary3.append(shortRow3)
        
        
        let shortQZ = double4x3(mediary3)
        
        middle = sRow * shortQZ
        
        
        let myK = dot(middle, tRow)
        
        return Vector3D(i: myI, j: myJ, k: myK)
    }
    
    /// Supply the partial derivative for the surface for the input parameter values
    /// Some notations show "s" and "t" as the parameters, instead of "u" and "v"
    /// - Parameters:
    ///   - u:  Parameter value for one direction.  Assumes 0 < u < 1
    ///   - v:  Parameter value for the other direction.  Assumes 0 < v < 1
    /// - Throws:
    ///   - ParameterRangeErrorDos if either of the input parameters are out of range
    /// - Returns: A non-normalized vector
    public func partV(spot: PointSurf) throws -> Vector3D   {
        
        guard spot.isInRange()  else   { throw ParameterRangeErrorDos(parA: spot.u, parB: spot.v) }
        
        let s = spot.u
        let s2 = s * s
        let s3 = s2 * s
        
        let sRow = double4(s3, s2, s, 1.0)
        
        let t = spot.v
        let t2 = t * t
        
        let tRow = double3(3.0 * t2, 2.0 * t, 1.0)
        
        /// Necessary to use simd
        let qxT = qx.transpose
        
        /// Holding pot for the original matrix minus the fourth column
        var mediary4 = [double4]()
        
        var sortRow0 = double4(qxT[0].x, qxT[0].y, qxT[0].z, qxT[0].w)
        mediary4.append(sortRow0)
        
        var sortRow1 = double4(qxT[1].x, qxT[1].y, qxT[1].z, qxT[1].w)
        mediary4.append(sortRow1)
        
        var sortRow2 = double4(qxT[2].x, qxT[2].y, qxT[2].z, qxT[2].w)
        mediary4.append(sortRow2)
        
        
        let sortQX = double3x4(mediary4)
        
        
        var middle = sRow * sortQX
        
        let myI = dot(middle, tRow)
        
        
        let qyT = qy.transpose
        
        mediary4 = [double4]()   // Clear the matrix
        
        sortRow0 = double4(qyT[0].x, qyT[0].y, qyT[0].z, qyT[0].w)
        mediary4.append(sortRow0)
        
        sortRow1 = double4(qyT[1].x, qyT[1].y, qyT[1].z, qyT[1].w)
        mediary4.append(sortRow1)
        
        sortRow2 = double4(qyT[2].x, qyT[2].y, qyT[2].z, qyT[2].w)
        mediary4.append(sortRow2)
        
        
        let sortQY = double3x4(mediary4)
        
        middle = sRow * sortQY
        
        
        let myJ = dot(middle, tRow)
        
        
        let qzT = qz.transpose
        
        mediary4 = [double4]()
        sortRow0 = double4(qzT[0].x, qzT[0].y, qzT[0].z, qzT[0].w)
        mediary4.append(sortRow0)
        
        sortRow1 = double4(qzT[1].x, qzT[1].y, qzT[1].z, qzT[1].w)
        mediary4.append(sortRow1)
        
        sortRow2 = double4(qzT[2].x, qzT[2].y, qzT[2].z, qzT[2].w)
        mediary4.append(sortRow2)
        
        
        let sortQZ = double3x4(mediary4)
        
        middle = sRow * sortQZ
        
        let myK = dot(middle, tRow)
        
        
        return Vector3D(i: myI, j: myJ, k: myK)
    }
    
    
    /// Supply the normal to the surface for the input parameter values
    /// Some notations show "s" and "t" as the parameters, instead of "u" and "v"
    /// - Parameters:
    ///   - u:  Parameter value for one direction.
    ///   - v:  Parameter value for the other direction.
    /// - Throws:
    ///   - ParameterRangeErrorDos if either of the input parameters are out of range
    /// - Returns: A normalized vector perpendicular to the surface at the point
    public func normalAt(spot: PointSurf) throws -> Vector3D   {
        
        guard spot.isInRange()  else   { throw ParameterRangeErrorDos(parA: spot.u, parB: spot.v) }
        
        var dU = try! self.partU(spot: spot)
        dU.normalize()
        
        var dV = try! self.partV(spot: spot)
        dV.normalize()
        
        var outward = try! Vector3D.crossProduct(lhs: dU, rhs: dV)    // dU and dV might not be parallel
        outward.normalize()
        
        return outward
    }
    
    
    /// Examine the coefficients by printing to terminal
    public func showCoeff() -> Void  {
        
        print()
        print("     X  ")
        for g in 0...3   {
            
            let myRow = qx[g]
            
            let col1 = String(format: "%.3f", myRow[0])
            let col2 = String(format: "%.3f", myRow[1])
            let col3 = String(format: "%.3f", myRow[2])
            let col4 = String(format: "%.3f", myRow[3])
            
            print(col1 + "  " + col2 + "  " + col3 + "  " + col4)
        }
        
        print()
        print("     Y  ")
        for g in 0...3   {
            
            let myRow = qy[g]
            
            let col1 = String(format: "%.3f", myRow[0])
            let col2 = String(format: "%.3f", myRow[1])
            let col3 = String(format: "%.3f", myRow[2])
            let col4 = String(format: "%.3f", myRow[3])
            
            print(col1 + "  " + col2 + "  " + col3 + "  " + col4)
        }
        
        print()
        print("     Z  ")
        for g in 0...3   {
            
            let myRow = qz[g]
            
            let col1 = String(format: "%.3f", myRow[0])
            let col2 = String(format: "%.3f", myRow[1])
            let col3 = String(format: "%.3f", myRow[2])
            let col4 = String(format: "%.3f", myRow[3])
            
            print(col1 + "  " + col2 + "  " + col3 + "  " + col4)
        }
        
        print()
    }

    
    /// Generate a vector between the input point and the line.
    /// - Parameters:
    ///   - surf: Patch to be checked
    ///   - spot: Trial point
    internal static func errorToLine(surf: Bicubic, spot: PointSurf, arrow: Line) -> Vector3D   {
        
        /// Approximation point on surface
        let approx = try! surf.pointAt(spot: spot)
        
        /// Nearest point on line
        let dropped = arrow.dropPoint(away: approx)
        
        /// Difference between approx and line
        let error = Vector3D.built(from: approx, towards: dropped)
        
        return error
    }
    
    /// Finds only one intersection.  Works only for well-behaved cases.
    /// Accuracy is assumed to be Point3D.Epsilon.
    /// - Parameters:
    ///   - surf: The surface to be pierced
    ///   - arrow:  The Line of interest
    /// - Returns: A single point, even if there might be multiple intersections
    ///    and the parameters of that point
    /// - Throws:
    ///   - ParameterRangeErrorDos for an out-of-range parameter
    ///   - ConvergenceError if 25 iterations don't do the trick
    public static func intersectSurfLine(surf: Bicubic, arrow: Line) throws -> (spot: Point3D, spotSurf: PointSurf)   {
        
        var approxSpot = PointSurf(u: 0.5, v:  0.5)    // Initial guess
       
        /// Tally to keep loop from running away
        var backstop = 0
        
        repeat   {
            
            /// Difference between approx and line
            let discrep = Bicubic.errorToLine(surf: surf, spot: approxSpot, arrow: arrow)
            
            if discrep.length() < Point3D.Epsilon   {
                let pierce = try! surf.pointAt(spot: approxSpot)
                return (pierce, approxSpot)
            }
            
            /// Vector in the U direction
            let dirU = try! surf.partU(spot: approxSpot)
            
            var normU = dirU
            normU.normalize()
            let errorU = Vector3D.dotProduct(lhs: discrep, rhs: normU)
            
            /// Vector in the V direction
            let dirV = try! surf.partV(spot: approxSpot)
            
            var normV = dirV
            normV.normalize()
            let errorV = Vector3D.dotProduct(lhs: discrep, rhs: normV)
            
               // This would be a good spot for 'offsetLimit'
            if abs(errorU) > abs(errorV)   {    // Follow the stronger partial
                approxSpot.u += errorU / dirU.length()
                if approxSpot.u < 0.0 || approxSpot.u > 1.0   {
                    throw ParameterRangeErrorDos(parA: approxSpot.u, parB: approxSpot.v)
                }
            }  else  {
                approxSpot.v += errorV / dirV.length()
                if approxSpot.v < 0.0 || approxSpot.v > 1.0   {
                    throw ParameterRangeErrorDos(parA: approxSpot.u, parB: approxSpot.v)
                }
            }
            
            backstop += 1
            
        } while backstop < 25
        
        // Bail out with notification if convergence failed
        if backstop > 24   { throw ConvergenceError(tnuoc: backstop) }
        

        let pierce = try! surf.pointAt(spot: approxSpot)   // This should never get reached

        return (pierce, approxSpot)
    }
    
    
    
    /// Generate the data necessary to show 200 triangles.
    /// This has nothing to do with allowable crown.
    /// - Parameters:
    ///   - board:  The surface to be illustrated
    /// - Returns: An array of line segments
    public static func triData(board: Bicubic) -> [LineSeg]   {
        
        /// The data to be returned
        var dashes = [LineSeg]()
        
        // Make some line segments that appear to be triangles for illustration
        for myV in stride(from: 0.0, through: 0.9, by: 0.1)   {
            
            var dot = PointSurf(u: 0.0, v: myV)
            var prevDown = try! board.pointAt(spot: dot)
            dot = PointSurf(u: 0.0, v: myV + 0.1)
            var prevUp = try! board.pointAt(spot: dot)
            
            let startingGate = try! LineSeg(end1: prevDown, end2: prevUp)
            startingGate.setIntent(PenTypes.Mesh)
            dashes.append(startingGate)
            
            for u in stride(from: 0.1, through: 1.0, by: 0.1)   {
                
                dot = PointSurf(u: u, v: myV)
                let edgeDown = try! board.pointAt(spot: dot)
                dot = PointSurf(u: u, v: myV + 0.1)
                let edgeUp = try! board.pointAt(spot: dot)
                
                let bottom = try! LineSeg(end1: prevDown, end2: edgeDown)
                
                dashes.append(bottom)
                
                let top = try! LineSeg(end1: prevUp, end2: edgeUp)
                dashes.append(top)
                
                let cross = try! LineSeg(end1: edgeDown, end2: edgeUp)
                dashes.append(cross)
                
                let diag = try! LineSeg(end1: prevDown, end2: edgeUp)
                dashes.append(diag)
                
                prevDown = edgeDown   // Prepare for the next iteration
                prevUp = edgeUp
                
            }
            
        }

        return dashes
    }
    
    
    /// Not used at the moment.
    /// Find the range of an iso-parametric point pair where it crosses a plane.
    /// This is part of finding the intersection - by successively refining the interval.
    /// Assumes that there is only one intersection.
    /// - Parameters:
    ///   - sheet:  The Plane to be used in testing for a crossing.
    ///   - span:  A ClosedRange<Double> of a single surface parameter in which to hunt.
    ///   - inU:  Whether the trial range is in u, or in v.
    ///   - fixedParam:  Value for the invariant parameter.
    /// - Returns: A smaller ClosedRange<Double>
    private func crossingIso(blade: Plane, span: ClosedRange<Double>, inU: Bool, fixedParam: Double) -> ClosedRange<Double>?   {
        
        /// Number of pieces to divide range
        let chunks = 5
        
        /// Parameter step
        let parStep = (span.upperBound - span.lowerBound) / Double(chunks)
        
        /// The possible return value
        var tighter: ClosedRange<Double>
        
        let dot = PointSurf(u: span.lowerBound, v: fixedParam)
        var lowerPoint = try! self.pointAt(spot: dot)
        
        if !inU   {
            let speck = PointSurf(u: fixedParam, v: span.lowerBound)
            lowerPoint = try! self.pointAt(spot: speck)
        }
        
        
        let lowerSep = blade.resolveRelative(pip: lowerPoint)
        var refArrow = lowerSep.perp
        
        // Actually should do something different here if you end up with a zero vector
        if !refArrow.isZero()   {
            refArrow.normalize()
        }
        
        /// Recent value of parameter
        var previousParam = span.lowerBound
        
        for g in 1...chunks   {
            
            let runningParam = span.lowerBound + Double(g) * parStep   // Generate a new parameter value
            
            // Find the corresponding point on the surface
            let speck = PointSurf(u: runningParam, v: fixedParam)
            var runningPoint = try! self.pointAt(spot: speck)
            
            if !inU   {
                let speck = PointSurf(u: fixedParam, v: runningParam)
                runningPoint = try! self.pointAt(spot: speck)
            }
            
            // See which side of 'sheet' it is on
            let runningSep = blade.resolveRelative(pip: runningPoint)
            let runningArrow = runningSep.perp
            
            /// Length of "runningArrow" when projected to the reference vector
            let projection = Vector3D.dotProduct(lhs: runningArrow, rhs: refArrow)
            
            if projection < 0.0   {   // Opposite of the reference, so a crossing was just passed
                tighter = ClosedRange<Double>(uncheckedBounds: (lower: previousParam, upper: runningParam))
                return tighter   // Bails after the first crossing found, even if there happen to be more
            }  else  {
                previousParam = runningParam   // Prepare for checking the next interval
            }
        }
        
        return nil
    }

    
    /// Find the intersection with a mostly perpendicular plane.
    /// - Parameters:
    ///   - blade:  The Plane to be used for the intersection.
    ///   - accuracy: Precision in UV for the location of each point
    /// - Returns: An optional fresh CubicUV
    public func intersectPerp(blade: Plane, accuracy: Double) -> CubicUV?   {
        
        /// Answer on whether or not the plane is suitable for this process
        let verdict = self.isEdgesSplit(flat: blade)
        
        if verdict.flag  &&  verdict.chops.count == 2   {
            
            /// Two boundary points that define the ends of the intersection curve.
            let edgeCrossingOne = verdict.chops[0]
            let edgeCrossingOpp = verdict.chops[1]
            
            let diffU = edgeCrossingOpp.u - edgeCrossingOne.u
            let diffV = edgeCrossingOpp.v - edgeCrossingOne.v
            
            /// Direction from the first intersection point to the second.
            var dirAlong = VectorSurf(i: diffU, j: diffV)
            let dirLen = dirAlong.length()
            dirAlong.normalize()
            
            /// Perpendicular to dirAlong
            let dirPerp = VectorSurf(i: -dirAlong.j, j: dirAlong.i)
            
            /// The collection of surface points
            var posts = [PointSurf]()
            posts.append(edgeCrossingOne)   // Add one boundary point
            
            for g in 1...19   {
                
                let plod = dirAlong * Double(g) * 0.05 * dirLen   // Step towards the final boundary point
                
                if let middle = edgeCrossingOne.offsetNil(jump: plod)   {
                    var stride = dirPerp * 0.08
                    
                    if let port = middle.offsetNil(jump: stride)   {
                        stride = dirPerp * -0.08
                        
                        if let stbd = middle.offsetNil(jump: stride)   {
                            
                            let junct = try! self.pointWithinRange(blade: blade, rangeEndA: port, rangeEndB: stbd, accuracy: accuracy)
                            posts.append(junct)   // Add this latest point
                            
                        }
                    }
                    
                }
                
            }
            
            posts.append(edgeCrossingOpp)   // Add the closing boundary point
            
            /// The resulting curve
            let fence = CubicUV.buildDots(dots: posts, surf: self)
            
            return fence
            
        }  else  {   // Not the right data for determining an intersection
            
            return nil
        }
        
    }
    
    
    /// Find a closer set of points that are split by the plane.
    /// A helper for finding the intesection.
    /// This perhaps could be private.
    /// - Parameters:
    ///   - blade:  The Plane to be used in testing for a crossing.
    ///   - rangeEndA:  A PointSurf for one end of the hunting range.
    ///   - rangeEndB:  A PointSurf for the other end of the hunting range.
    /// - Returns: A pair of PointSurf's for a narrower range
    internal func crossing(blade: Plane, rangeEndA: PointSurf, rangeEndB: PointSurf) -> (alpha: PointSurf, omega: PointSurf)   {
        
        /// Number of desired divisions for the input range
        let chunks = 5
        
        /// Points defining several smaller ranges
        let hops = PointSurf.splitSpan(pointA: rangeEndA, pointB: rangeEndB, chunks: chunks)
        
        for g in 1...chunks   {
            
            let dotA = hops[g - 1]
            let ballA = try! self.pointAt(spot: dotA)
            
            let dotB = hops[g]
            let ballB = try! self.pointAt(spot: dotB)
            
            let flag = blade.isOpposite(pointA: ballA, pointB: ballB)
            
            if flag   { return(dotA, dotB) }
        }
        
        return(rangeEndA, rangeEndB)   // This indicates a problem!
    }
    
    
    /// Finds a PointSurf on the intersection of a plane.
    /// Assumes that the starting range is good.
    /// - Parameters:
    ///   - blade:  The Plane to be used in testing for a crossing.
    ///   - rangeEndA:  A PointSurf for one end of the hunting range.
    ///   - rangeEndB:  A PointSurf for the other end of the hunting range.
    /// - Throws: ConvergenceError if 8 iterations isn't sufficient.
    /// - Returns: The intersection point.
    internal func pointWithinRange(blade: Plane, rangeEndA: PointSurf, rangeEndB: PointSurf, accuracy: Double) throws -> PointSurf   {
        
        /// Separation of Point3D's for each iteration
        var sep = accuracy * 10.0   // Radical starting value
      
        /// Point to be returned
        var hip = rangeEndA
        
        /// Working point at the other end of the range.
        var hop = rangeEndB

        
        /// Counter to avoid a runaway loop
        var backstop = 0
        
        while backstop < 8   {
            
            let refined = self.crossing(blade: blade, rangeEndA: hip, rangeEndB: hop)
            let speckA = try! self.pointAt(spot: refined.alpha)
            let speckB = try! self.pointAt(spot: refined.omega)
            sep = Point3D.dist(pt1: speckA, pt2: speckB)
            
            if sep < accuracy   {
                hip = refined.alpha
                break
            }

            hip = refined.alpha
            hop = refined.omega
            backstop += 1
        }
        
           // Bail out with notification if convergence failed
        if backstop > 7   { throw ConvergenceError(tnuoc: backstop) }
        
        return hip
    }
    
    
    /// Find the relationship between a plane and the four corners.
    /// This method will generate false negatives when a plane is nearly tangent to the surface.
    /// This could possibly become private, since it is probably only used for a intersection.
    /// - Parameters:
    ///   - flat:  The plane to be checked
    /// - Returns: A flag indicating whether or not the plane splits two edges, and the two PointSurfs
    /// - See: 'testIsEdgesSplit' in BicubicTests
    internal func isEdgesSplit(flat: Plane) -> (flag: Bool, chops: [PointSurf])   {
        
        /// Find the relationship of a point to the plane's normal
        let cornerSense: (PointSurf) -> Double = {
            let corner = try! self.pointAt(spot: $0)
            let dirPair = flat.resolveRelative(pip: corner)
            return Vector3D.dotProduct(lhs: flat.getNormal(), rhs: dirPair.perp)
        }
        
        let cornerA = PointSurf(u: 0.0, v: 0.0)
        let cornerB = PointSurf(u: 0.0, v: 1.0)
        let cornerC = PointSurf(u: 1.0, v: 1.0)
        let cornerD = PointSurf(u: 1.0, v: 0.0)
        
        let senseA = cornerSense(cornerA)
        let senseB = cornerSense(cornerB)
        let senseC = cornerSense(cornerC)
        let senseD = cornerSense(cornerD)

        
        /// Locations where the plane splits the edges.  Should end up with two members.
        var crossings = [PointSurf]()
        
        let flag1 = (senseA * senseB) < 0.0
        
        if flag1   {
            let chop = try! self.pointWithinRange(blade: flat, rangeEndA: cornerA, rangeEndB: cornerB, accuracy: 0.001)
            crossings.append(chop)
        }
        
        
        let flag2 = (senseA * senseD) < 0.0
        
        if flag2   {
            let chop = try! self.pointWithinRange(blade: flat, rangeEndA: cornerA, rangeEndB: cornerD, accuracy: 0.001)
            crossings.append(chop)
        }
        
        
        let flag3 = (senseB * senseC) < 0.0
        
        if flag3   {
            let chop = try! self.pointWithinRange(blade: flat, rangeEndA: cornerB, rangeEndB: cornerC, accuracy: 0.001)
            crossings.append(chop)
        }
        
        
        let flag4 = (senseC * senseD) < 0.0
        
        if flag4   {
            let chop = try! self.pointWithinRange(blade: flat, rangeEndA: cornerC, rangeEndB: cornerD, accuracy: 0.001)
            crossings.append(chop)
        }
        
        
        /// Positive if all of the corner points are on the same side of the plane, either positive, or negative.
        let prod = senseA * senseB * senseC * senseD
        
        if prod < 0.0 { return (true, crossings) }   // Three on one side, one on the other.
        

           // Deal with the case of two positives and two negatives
        if flag1  &&  flag4    { return (true, crossings) }
        if flag2  &&  flag3    { return (true, crossings) }

        
        return (false, crossings)   // No intersection
    }
    
    
    
    /// Look for surface curvature around a point
    /// Checks four points at 0.05 away
    /// - Parameters:
    ///   - u:  Parameter value for one direction.  Assumes 0 < u < 1
    ///   - v:  Parameter value for the other direction.  Assumes 0 < v < 1
    /// - Returns: A flag
    private func isConvex(spot: PointSurf) throws -> Bool   {
        
        guard spot.isInRange()  else   { throw ParameterRangeErrorDos(parA: spot.u, parB: spot.v) }
        
        /// Central point
        let base = try! self.pointAt(spot: spot)
        
        var dU = try! self.partU(spot: spot)
        dU.normalize()
        
        var dV = try! self.partV(spot: spot)
        dV.normalize()
        
        /// Reference direction at this point
        var ref = try! Vector3D.crossProduct(lhs: dU, rhs: dV)
        ref.normalize()
        
        /// Normal line at the point of interest
        let grail = try! Line(spot: base, arrow: ref)
        
        
        var jump = ref * 0.25
        
        /// Genesis point for making test lines
        let apex = base.offset(jump: jump)
        
        
        /// Array for points to generate test lines
        var overhead = [Point3D]()
        
        jump = dU * 0.05
        var skyhook = apex.offset(jump: jump)
        overhead.append(skyhook)
        
        jump = dV * 0.05
        skyhook = apex.offset(jump: jump)
        overhead.append(skyhook)
        
        jump = dU * -0.05
        skyhook = apex.offset(jump: jump)
        overhead.append(skyhook)
        
        jump = dV * -0.05
        skyhook = apex.offset(jump: jump)
        overhead.append(skyhook)
        
        /// Indicators that an intersection is below the surface
        var flags = [Bool]()
        
        for pip in overhead   {
            
            /// Line from one overhead point
            let ray = try! Line(spot: pip, arrow: ref)
            
            /// Intersection with the surface
            let surfSpot = try! Bicubic.intersectSurfLine(surf: self, arrow: ray)
            
            /// Normal at the intersection point.  Not necessarily coplanar with 'ref'
            let localNorm = try! self.normalAt(spot: surfSpot.spotSurf)
            
            /// Normal line from peripheral point
            var distal = try! Line(spot: surfSpot.spot, arrow: localNorm)
            
            if !Line.isCoplanar(straightA: grail, straightB: distal)   {
                
                let clamp = try! Plane(alpha: base, beta: surfSpot.spot, gamma: apex)
                
                let planePerp = clamp.getNormal()
                
                /// The out-of-plane portion
                let error = Vector3D.dotProduct(lhs: planePerp, rhs: localNorm)
                
                let errorVector = planePerp * error
                
                var swung = localNorm - errorVector
                swung.normalize()
                
                distal = try! Line(spot: surfSpot.spot, arrow: swung)
            }
            
            /// Intersection point
            let collision = try! Line.intersectTwo(straightA: grail, straightB: distal)
            
            
            let wire = Vector3D.built(from: surfSpot.spot, towards: collision, unit: true)
            
            let compliance = Vector3D.dotProduct(lhs: ref, rhs: wire)
            
            var semaphore: Bool
            
            if compliance < 0.0   {
                semaphore = true
            }  else  {
                semaphore = false
            }
            
            flags.append(semaphore)
        }
        
        let decision = flags[0]  &&  flags[1]  &&  flags[2]  && flags[3]
        
        return decision
    }
    
    
    
    /// Refine values as part of finding the fillet tangent point on the surface
    /// - Parameters:
    ///   - playingField:  The surface to be used in finding the tangency point
    ///   - filletCL:  Line 'filletRad' away from the pillar surface
    ///   - filletRad:  Radius to blend between the base surface and the pillar
    ///   - sideways:  Vector representing 'horizontal' in the section cut
    ///   - planeOut:  Vector perpendicular to the section cut
    ///   - span:  Ratio of fillet radius used for this iteration
    /// - Returns: A narrower range if a crossing is found, nil otherwise, plus the value of the error and three points
    private static func crossingFillet(playingField: Bicubic, filletCL: Line, filletRad: Double, sideways: Vector3D, planeOut: Vector3D,  span: ClosedRange<Double>) -> (egnar:ClosedRange<Double>?, error: Double, surfTan: Point3D, filletCtr: Point3D, uprightTan: Point3D)   {
        
        /// Number of pieces to divide range
        let chunks = 8
        
        /// The possible return value
        var tighter: ClosedRange<Double>
        
        /// Parameter step
        let parStep = (span.upperBound - span.lowerBound) / Double(chunks)
        
        
        let refTuple = offsetNormalInter(playingField: playingField, filletCL: filletCL, filletRad: filletRad, sideways: sideways, planeOut: planeOut, hop: span.lowerBound)
        
        /// Value at the beginning of the range
        let refValue = refTuple.dist - filletRad
        
        /// Recent value of parameter
        var previousHop = span.lowerBound
        
        var meritSpot = Point3D(x: 0.0, y: 0.0, z: 0.0)
        var swingCtr = Point3D(x: 0.0, y: 0.0, z: 0.0)
        
        for g in 1...chunks   {
            
            let freshHop = span.lowerBound + Double(g) * parStep
            
            // Generate the objective
            let merit = offsetNormalInter(playingField: playingField, filletCL: filletCL, filletRad: filletRad, sideways: sideways, planeOut: planeOut, hop: freshHop)
            
            let myObjective = merit.dist - filletRad
            
            let flipIndicator = myObjective * refValue
            
            if flipIndicator < 0.0   {   // Opposite of the reference, so a crossing was just passed
                
                let delta = myObjective
                
                tighter = ClosedRange<Double>(uncheckedBounds: (lower: previousHop, upper: freshHop))
                
                meritSpot = merit.spot
                
                swingCtr = merit.filletCtr
                
                let jump = sideways * -filletRad
                let upTan = swingCtr.offset(jump: jump)
                
                return (tighter, delta, meritSpot, swingCtr, upTan)   // Bails after the first crossing found, even if there happen to be more
            }  else  {
                previousHop = freshHop   // Prepare for checking the next interval
            }
        }
        
        return (nil, 5.0, meritSpot, meritSpot, meritSpot)   // Bogus numeric value and nonsensical points
    }
    
    
    /// Only used for the stiffened panel.
    /// Find the normal and intersection for a fillet tangency on a surface.
    /// - Parameters:
    ///   - playingField:  The surface to be used in finding the tangency point
    ///   - filletCL:  Line 'filletRad' away from the pillar surface
    ///   - filletRad:  Radius to blend between the base surface and the pillar
    ///   - sideways:  Vector representing 'horizontal' in the section cut
    ///   - planeOut:  Vector perpendicular to the section cut
    ///   - hop:  Ratio of fillet radius used as an offset for this iteration
    /// - Returns: A tuple containing a Point3D and its distance to the filletCL
    private static func offsetNormalInter(playingField: Bicubic, filletCL: Line, filletRad: Double, sideways: Vector3D, planeOut: Vector3D, hop: Double) -> (spot: Point3D, spotSurf: PointSurf, dist: Double, filletCtr: Point3D)   {
        
        let jump = sideways * (filletRad * hop)
        
        /// Base for one of the trial lines
        let follicle = filletCL.getOrigin().offset(jump: jump)
        
        let hairOff = try! Line(spot: follicle, arrow: filletCL.getDirection())
        
        /// Possible fillet tangency point
        let maybeTan = try! Bicubic.intersectSurfLine(surf: playingField, arrow: hairOff)
        
        
        // Remove any out-of-plane component that the normal might have
        let tiltBeam = try! playingField.normalAt(spot: maybeTan.spotSurf)   // Not necessarily in-plane
        
        let gravelMag = Vector3D.dotProduct(lhs: tiltBeam, rhs: planeOut)
        //            print("G: " + String(format: "%.3f", gravelMag))
        
        /// Small out-of-plane component
        let gravel = planeOut * gravelMag
        
        /// The modified surface normal
        var beamVec = tiltBeam - gravel
        beamVec.normalize()
        
        /// Possible radial line of the fillet
        let beam = try! Line(spot: maybeTan.spot, arrow: beamVec)
        
        /// Point where the line to the surface intersects filletCL
        let slash = try! Line.intersectTwo(straightA: filletCL, straightB: beam)
        
        /// Distance from the surface to the fillet centerline
        var dennison = Point3D.dist(pt1: slash, pt2: maybeTan.spot)
        
        let newman = Vector3D.built(from: maybeTan.spot, towards: slash)
        let nSense = Vector3D.dotProduct(lhs: filletCL.getDirection(), rhs: newman)
        
        var factor = 1.0   // Positive if above the surface, negative if below
        if nSense < 0.0   {
            factor = -1.0
        }
        
        dennison *= factor   // The goal is to find this positive and equal to the fillet radius
                
        return(maybeTan.spot, maybeTan.spotSurf, dennison, slash)
    }

    
    /// Generate a few isoparametric lines to illustrate the surface
    /// This should become a class function for Bicubic
    /// - Returns: Array of LineSeg's to be plotted
    public static func stripes(panel: Bicubic, count: Int) -> [LineSeg]   {
        
        /// The array to be returned
        var strokes = [LineSeg]()
        
        var priorPt = Point3D(x: 0.0, y: 0.0, z: 0.0)   // Will get overwritten in the loop
        
        let stepV = 1.0 / Double(count)
        
        for band in 0...count   {
            
            let v = Double(band) * stepV
            
            for g in 0...20   {
                
                let p = Double(g) * 0.05
                
                let dot = PointSurf(u: p, v: v)
                let currentPt = try! panel.pointAt(spot: dot)
                
                if g > 0   {
                    let wire = try! LineSeg(end1: priorPt, end2: currentPt)
                    strokes.append(wire)
                }
                
                priorPt = currentPt
                
            }
            
            for g in 0...20   {
                
                let p = Double(g) * 0.05
                
                let dot = PointSurf(u: v, v: p)
                let currentPt = try! panel.pointAt(spot: dot)
                
                if g > 0   {
                    let wire = try! LineSeg(end1: priorPt, end2: currentPt)
                    strokes.append(wire)
                }
                
                priorPt = currentPt
                
            }
        }
        
        return strokes
    }
    
    
    
    /// Generate short lines to indicate curvature.
    /// Spacing and length are candidates for input parameters.
    /// - Returns: Array of LineSeg
    public func genQuills() -> [LineSeg]   {
        
        /// Short lines to be returned
        var spikes = [LineSeg]()
        
        for myU in stride(from: 0.0, to: 1.0001, by: 0.1)   {
            
            for myV in stride(from: 0.0, to: 1.0001, by: 0.1)   {
                
                let pip = PointSurf(u: myU, v: myV)
                let root = try! self.pointAt(spot: pip)
                let dir = try! self.normalAt(spot: pip)
                
                let tip = root.offset(jump: dir)
                
                let quill = try! LineSeg(end1: root, end2: tip)
                spikes.append(quill)
                
            }  // Inner loop
            
        }   // Outer loop
        
        return spikes
    }
    
    
}

