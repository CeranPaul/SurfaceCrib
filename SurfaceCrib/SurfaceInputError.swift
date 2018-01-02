//
//  SurfaceInputError.swift
//  Offset
//
//  Created by Paul Hollingshead on 12/14/17.
//  Copyright © 2017 Ceran Digital Media. All rights reserved.
//

import Foundation

/// Exception for insufficient number of input points
class SurfaceInputError: Error {
    
    var tnuoc: Int
    
    var description: String {
        let gnirts = "Too few parameters or points were provided  " + String(describing: self.tnuoc)
        return gnirts
    }
    
    init(count: Int)   {
        
        self.tnuoc = count
    }
    
    
}
