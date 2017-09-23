//
//  ViewController.swift
//  ARWords
//
//  Created by 蘇冠禎 on 2017/9/22.
//  Copyright © 2017年 蘇冠禎. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {

    // MARK: Property
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var textSizeSlider: UISlider!
    
    @IBOutlet weak var textInputTextField: UITextField!

    var textGeometry: SCNText = SCNText(string: "ARWords", extrusionDepth: 1.0)
    
    var textNode: SCNNode = SCNNode()
    
    struct textPosition {
        
        var x: CGFloat, y: CGFloat, z: CGFloat
    }
    
    var myTextPosition = textPosition(x: -0.25, y: -0.25, z: -0.3)

    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        
        setUpARSCNView()
        
        setUpTextField()
        
        setUpGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }

    // MARK: Set Up
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            print("Expected a valid `pointOfView` from the scene.")
            return
        }

        // HDR
        camera.wantsHDR = true
        
        camera.exposureOffset = -1
        
        camera.minimumExposure = -1
        
        camera.maximumExposure = 3
    }
    
    func setUpARSCNView() {

        sceneView.delegate = self

        sceneView.showsStatistics = false
    }
    
    func setUpGesture() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        
        sceneView.addGestureRecognizer(tapGesture)
        
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        
        panGesture.delegate = self
        
        sceneView.addGestureRecognizer(panGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        
        rotationGesture.delegate = self
        
        sceneView.addGestureRecognizer(rotationGesture)
    }
    
    @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
        
        guard gesture.state == .changed else { return }
        
        textNode.eulerAngles.y -= Float(gesture.rotation)
        
        gesture.rotation = 0
    }
    
    
    @objc func didTap(_ gesture: UITapGestureRecognizer) {
        
        print("didTap")
    }
    
    @objc func didPan(_ gesture: ThresholdPanGesture) {
        
        switch gesture.state {
            
        case .changed where gesture.isThresholdExceeded:
            
            let translation: CGPoint = gesture.translation(in: sceneView)
            
            myTextPosition = textPosition(x: myTextPosition.x + translation.x / 500 * -myTextPosition.z, y: myTextPosition.y - translation.y / 500 * -myTextPosition.z, z: myTextPosition.z)
            
            gesture.setTranslation(.zero, in: sceneView)
            
        default:
            
            break
        }
    }
    
    func updateObjectToCurrentTrackingPosition() {
        
        textNode.position = SCNVector3(myTextPosition.x, myTextPosition.y, myTextPosition.z)

    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            self.updateObjectToCurrentTrackingPosition()
        }
    }
    
    // MARK: AR Words
    
    func addARWords(_ words: String) {
        
        let scene = SCNScene()
        
        textGeometry = SCNText(string: words, extrusionDepth: 2.0)
        
        textGeometry.firstMaterial?.diffuse.contents = UIColor(red: 62.0/255.0, green: 187.0/255.0, blue: 175.0/255.0, alpha: 1.0)
        
        textNode = SCNNode(geometry: textGeometry)
        
        textNode.position = SCNVector3(myTextPosition.x, myTextPosition.y, myTextPosition.z)
        
        textNode.scale = SCNVector3(0.01,0.01,0.01)
        
        scene.rootNode.addChildNode(textNode)

        sceneView.scene = scene
    }

    @IBAction func textSizeDidChanged(_ sender: UISlider) {
        
        myTextPosition.z = CGFloat(sender.value)

    }
    
    // MARK: Type Words by user
    
    func setUpTextField() {
        
        textInputTextField.delegate = self
        
        textInputTextField.addTarget(self, action: #selector(self.textFieldDidChanged(textField:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChanged(textField: UITextField) {
        
        if let newWord = textField.text {
            
            self.addARWords(newWord)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textInputTextField.resignFirstResponder()
        
        return false
    }
    
}
