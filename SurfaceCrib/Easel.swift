//
//  Easel.swift
//  SingleLab
//
//  Created by Paul on 1/8/17.
//  Copyright © 2017 Ceran Digital Media.  See LICENSE.md
//

import UIKit
import simd

/// Graphics sketchpad
/// - Attention: This class name needs to linked in the storyboard's Identity Inspector in an app to be seen
class Easel: UIView   {
        
       // Declare pen properties
    var black: CGColor
    var blue: CGColor
    var green: CGColor
    var grey: CGColor
    var orange: CGColor
    var brown: CGColor

        // Prepare pen widths
    let thick = CGFloat(4.0)
    let standard = CGFloat(3.0)
    let thin = CGFloat(1.5)
    
    /// Transforms between model and screen space
    var modelToDisplay: CGAffineTransform?
    var displayToModel: CGAffineTransform?
    
    /// Coordinate transform driven by screen touches
    /// Initialized to a unit diagonal matrix
    var rotTform = Transform()
    
    /// Scaling and centering transform for display
    var plotTform = Transform()
    
    
    required init(coder aDecoder: NSCoder)  {
        
           // Prepare colors
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let blackComponents: [CGFloat] = [0.0, 0.0, 0.0, 1.0]
        black = CGColor(colorSpace: colorSpace, components: blackComponents)!
        let blueComponents: [CGFloat] = [0.0, 0.0, 1.0, 1.0]
        blue = CGColor(colorSpace: colorSpace, components: blueComponents)!
        let greenComponents: [CGFloat] = [0.0, 1.0, 0.0, 1.0]
        green = CGColor(colorSpace: colorSpace, components: greenComponents)!
        let greyComponents: [CGFloat] = [0.7, 0.7, 0.7, 1.0]
        grey = CGColor(colorSpace: colorSpace, components: greyComponents)!
        let orangeComponents: [CGFloat] = [1.0, 0.65, 0.0, 1.0]
        orange = CGColor(colorSpace: colorSpace, components: orangeComponents)!
        let brownComponents: [CGFloat] = [0.63, 0.33, 0.18, 1.0]   
        brown = CGColor(colorSpace: colorSpace, components: brownComponents)!
        
        
        super.init(coder: aDecoder)!   // Done here to be able to use "self.bounds" for scaling below
        
        // Set up transforms to and from model coordinates
        let tforms = findScaleAndCenter(displayRect: self.bounds, subjectRect: modelGeo.arena)
        
        modelToDisplay = tforms.toDisplay
        displayToModel = tforms.toModel
    }
    

    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState();    // Preserve settings that were used before
        
        context.setStrokeColor(grey)
        context.setLineWidth(standard)
        
        context.setLineDash(phase: 0, lengths: [])
        
        /// Rotate the points using angles driven by touch input  See ViewController code
        let twist = buildGestureTransform(alpha: yawChange, theta: pitchChange, rotCtr: modelGeo.rotCenter)
        
        
        for wire in modelGeo.displayLines   {    // Traverse through the entire collection of displayLines
            
            let rotwire = try! wire.transform(xirtam: twist)
            
            // Choose the appropriate pen
            switch rotwire.usage  {
                
            case .Triangle:
                context.setStrokeColor(brown)
                context.setLineWidth(thin)
                context.setLineDash(phase: 0, lengths: [])    // To clear any previous dash pattern
                
            case .Paired:
                context.setStrokeColor(brown)
                context.setLineWidth(thin)
//                context.setLineDash(phase: 4, lengths: [CGFloat(8), CGFloat(8)])    // Equal dashes
                context.setLineDash(phase: 0, lengths: [])    // To clear any previous dash pattern
                
            case .Mesh:
                context.setStrokeColor(black)
                context.setLineWidth(thin)
                context.setLineDash(phase: 0, lengths: [])    // To clear any previous dash pattern
                
            case .Bachelor:
                context.setStrokeColor(orange)
                context.setLineWidth(thin)
                context.setLineDash(phase: 0, lengths: [])    // To clear any previous dash pattern
                
            case .Overflow:
                context.setStrokeColor(orange)
                context.setLineWidth(thick)
                context.setLineDash(phase: 4, lengths: [CGFloat(8), CGFloat(4)])    // Unequal dashes
                
            case .Ordinary:
                context.setStrokeColor(black)
                context.setLineWidth(thin)
                context.setLineDash(phase: 0, lengths: [])    // To clear any previous dash pattern
                
//            case .Far:
//                context.setStrokeColor(brown)
//                context.setLineWidth(thin)
//                context.setLineDash(phase: 4, lengths: [CGFloat(8), CGFloat(8)])    // Equal dashes
//                
                
            }
            
            rotwire.draw(context: context, tform: modelToDisplay!)
            
        }   // End of loop through the display list
        
        
        context.restoreGState();    // Restore prior settings
        
    }    // End of overridden 'draw'
    
    
    
    /// Determines parameters to center the model on the screen.
    /// - Parameter: displayRect: Bounds of the plotting area
    /// - Parameter: subjectRect: A CGRect that bounds the model space used
    /// - Returns: A tuple containing transforms between model and display space
    func  findScaleAndCenter(displayRect: CGRect, subjectRect: CGRect) -> (toDisplay: CGAffineTransform, toModel: CGAffineTransform)   {
        
        let rangeX = subjectRect.width
        let rangeY = subjectRect.height
        
        /// For an individual edge
        let margin = CGFloat(20.0)   // Measured in "points", not pixels, or model units
        let twoMargins = CGFloat(2.0) * margin
        
        let scaleX = (displayRect.width - twoMargins) / rangeX
        let scaleY = (displayRect.height - twoMargins) / rangeY
        
        let scale = min(scaleX, scaleY)
        
        
        // Find the middle of the model area for translation
        let giro = subjectRect.origin
        
        let middleX = giro.x + 0.5 * rangeX
        let middleY = giro.y + 0.5 * rangeY
        
        let transX = (displayRect.width - twoMargins) / 2 - middleX * scale + margin
        let transY = (displayRect.height - twoMargins) / 2 + middleY * scale + margin
        
        let modelScale = CGAffineTransform(scaleX: scale, y: -scale)   // To make Y positive upwards
        let modelTranslate = CGAffineTransform(translationX: transX, y: transY)
        
        
        /// The combined matrix based on the plot parameters
        let modelToDisplay = modelScale.concatenating(modelTranslate)
        let displayToModel = modelToDisplay.inverted()
        
        return (modelToDisplay, displayToModel)
    }
    
    /// Generate a Transform based on touch inputs
    /// Rotate only - no scaling or translation.  Driven by angles captured by ViewController
    /// - Parameters:
    ///   - alpha: Rotation around the screen Y axis
    ///   - theta: Rotation around the screen X axis
    /// Affects rotTform
    /// - Returns: A Transform that combines the two rotations
    func buildGestureTransform(alpha: Double, theta: Double, rotCtr: Point3D) -> Transform  {
        
        let rotX = Transform.init(rotationAxis: Axis.x, angleRad: -1.0 * theta)  // I don't know why the angle...
        let rotY = Transform.init(rotationAxis: Axis.y, angleRad: alpha)
        
        rotTform = rotTform * rotX * rotY
        return rotTform
    }
    
    
}
