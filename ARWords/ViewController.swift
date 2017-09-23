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
import ReplayKit

class ViewController: UIViewController, ARSCNViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, RPPreviewViewControllerDelegate {

    // MARK: Property
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var textSizeSlider: UISlider!
    
    @IBOutlet weak var textInputTextField: UITextField!

    var textGeometry: SCNText = SCNText(string: "ARWords", extrusionDepth: 1.0)
    
    var textNode: SCNNode = SCNNode()
    
    struct textPosition {
        
        var x: CGFloat, y: CGFloat, z: CGFloat
    }
    
    var myTextPosition = textPosition(x: -0.25, y: 0, z: -0.3)
    
    var recordingNow: Bool = false

    @IBOutlet weak var startRecordBtn: UIButton!

    @IBOutlet weak var resetBtn: UIButton!

    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        
        setUpARSCNView()
        
        setUpTextField()
        
        setUpGesture()
        
        addARWords("想說什麼？")
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

        if recordingNow {
            
            self.stopRecording()
            
            return
        }
        
        let colors: [UIColor] = [ .midiBlack, .midiGreen, .midiRed, .midiYellow, .lightestGrey, .normalGrey, .tintGrey ]
        
        let randomColorIndex: Int = Int(arc4random_uniform(7))
        
        textGeometry.firstMaterial?.diffuse.contents = colors[randomColorIndex]
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
        
        textGeometry.firstMaterial?.diffuse.contents = UIColor.midiRed
        
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
    
    // MARK: Recording
    
    @IBAction func startRecording(_ sender: Any) {
        
        recordingNow = true
        
        controlWidget(show: false)
        
        RPScreenRecorder.shared().startRecording{ error in
            
            print("Record Error")
        }
    }
    
    func stopRecording() {
        
        recordingNow = false
        
        RPScreenRecorder.shared().stopRecording { [unowned self] (preview, error) in
            
            if let unwrappedPreview = preview {
                
                unwrappedPreview.previewControllerDelegate = self
                
                self.present(unwrappedPreview, animated: true)
            }
        }
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        
        dismiss(animated: true)
        
        controlWidget(show: true)
    }
    
    func controlWidget(show: Bool) {
        
        if show {
            
            textSizeSlider.isHidden = false
            
            textInputTextField.isHidden = false
            
            startRecordBtn.isHidden = false
            
            resetBtn.isHidden = false
            
        } else {
            
            textSizeSlider.isHidden = true
            
            textInputTextField.isHidden = true
            
            startRecordBtn.isHidden = true
            
            resetBtn.isHidden = true
        }
    }
    
    // MARK: Reset
    @IBAction func resetARSession(_ sender: Any) {
        
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        textInputTextField.text = ""
        
        textGeometry = SCNText(string: "", extrusionDepth: 2.0)
        
        textNode.removeFromParentNode()
    }
}
