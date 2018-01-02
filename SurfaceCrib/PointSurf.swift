//
//  PointSurf.swift
//  Offset
//
//  Created by Paul Hollingshead on 12/14/17.
//  Copyright © 2017 Ceran Digital Media. All rights reserved.
//

import Foundation

/// Simple representation of a position on a parametric surface
/// u and v are the equivalent of s and t
/// No range checks are made to keep u and v between 0.0 and 1.0
/// The default initializer suffices
public struct PointSurf   {
    
    var u: Double
    var v: Double
    
}
