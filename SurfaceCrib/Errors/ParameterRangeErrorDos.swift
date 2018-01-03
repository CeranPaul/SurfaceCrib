//
//  ParameterRangeErrorDos.swift
//  SingleLab
//
//  Created by Paul on 6/7/17.
//  Copyright © 2017 Ceran Digital Media. All rights reserved.
//

import Foundation

/// Exception for when the points should not have be coincident
class ParameterRangeErrorDos: Error {
    
    var paramA: Double
    var paramB: Double
    
    var description: String {
        return "Parameter was outside valid range! " + String(describing: paramA) + "  " + String(describing: paramB)
    }
    
    init(parA: Double, parB: Double)   {
        
        self.paramA = parA
        self.paramB = parB
    }
    
}
