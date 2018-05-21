//
//  ViewController.swift
//  SurfaceCrib
//
//  Created by Paul Hollingshead on 1/1/18.
//  Copyright © 2018 Ceran Digital Media. All rights reserved.
//


import SceneKit

/// Rotation angles after user input.  Radians.  To feed the UIView
var yawChange = 0.0   // Around the screen Y axis
var pitchChange = 0.0   // Around the screen X axis

class ViewController: UIViewController {

    /// How much rotation happens with a swipe
    let sensitivity = 280.0   // Set empirically
    
    /// Reset point to keep rotation non-cumulative
    var touchPrevious = CGPoint(x: 0.0, y: 0.0)
    
    @IBOutlet weak var sceneView: SCNView!    // I have no clue why I'm doing this  Where instantiated?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {   // I have no idea why this is the right place
        // to prepare the scene
        super.viewDidAppear(animated)
        
        sceneSetup()
    }
    
   override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /// Always treat a pan as a rotation
    @IBAction func handlePan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            
            yawChange = Double(translation.x) / sensitivity
            pitchChange = Double(translation.y) / -sensitivity    // Due to screen inversion
            
            view.setNeedsDisplay()     // Request a display update
        }
        
        recognizer.setTranslation(touchPrevious, in: self.view)
    }
    
    /// Do the prep work for displaying geometry
    func sceneSetup() {
        
        let scene = SCNScene()
        
        
        
        // 2
        
        /// Instantiate some shape to be displayed
        let sculpture = modelGeo
        
        let boxNode = SCNNode(geometry: sculpture.likeness)
        scene.rootNode.addChildNode(boxNode)
        
        // Remember that it's the camera that gets moved by gestures
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 25)
        scene.rootNode.addChildNode(cameraNode)
        
        
        // Add the scene to the SCNView
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        
    }
}

