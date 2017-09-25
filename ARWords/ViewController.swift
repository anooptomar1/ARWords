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
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var textSizeSlider: UISlider! {
        
        didSet {
            
            textSizeSlider.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)

            textSizeSlider.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint(item: textSizeSlider, attribute: .trailing, relatedBy: .equal, toItem: sceneView, attribute: .trailing, multiplier: 1.0, constant: -20).isActive = true
            
            NSLayoutConstraint(item: textSizeSlider, attribute: .width, relatedBy: .equal, toItem: sceneView, attribute: .width, multiplier: 1.0, constant: -250.0).isActive = true
            
            NSLayoutConstraint(item: textSizeSlider, attribute: .centerY, relatedBy: .equal, toItem: sceneView, attribute: .centerY, multiplier: 1.0, constant: 0.0).isActive = true
        }
    }
    
    @IBOutlet weak var textInputTextField: UITextField!

    var textGeometry: SCNText = SCNText(string: "ARWords", extrusionDepth: 3.0)
    
    var textNode: SCNNode = SCNNode()
    
    struct textPosition {
        
        var x: CGFloat, y: CGFloat, z: CGFloat
    }
    
    var myTextPosition = textPosition(x: -0.5, y: -0.25, z: -0.3)
    
    var myTextScale: Float = 0.01
    
    var recordingNow: Bool = false

    @IBOutlet weak var startRecordBtn: UIButton!

    @IBOutlet weak var resetBtn: UIButton!
    
    @IBOutlet weak var addWordsBtn: UIButton!

    var colorIndex: Int = 0

    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        
        setUpStartRecordBtn()
        
        setUpARSCNView()
        
        setUpTextField()
        
        setUpGesture()
        
        addARWords("想說什麼？")
        
        textInputTextField.text = "想說什麼？"
        
        textInputTextField.isHidden = true
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
    
    func setUpStartRecordBtn() {
        
        startRecordBtn.layer.cornerRadius = startRecordBtn.bounds.size.width / 2.0
        
        startRecordBtn.layer.borderWidth = 10.0
        
        startRecordBtn.layer.borderColor = UIColor(red: 51.0 / 255.0, green: 51.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0).cgColor
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
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        
        sceneView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {

        switch gesture.state {
        
        case .began, .changed:
            
            if abs(gesture.velocity) > 1 {
            
                self.myTextScale = Float(gesture.scale) / 100.0
                
            }
            
        case .ended:
            
            gesture.scale = 1.0

        default:
            
            break
        }
    }
    
    @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
        
        guard gesture.state == .changed else { return }
        
        textNode.eulerAngles.y -= Float(gesture.rotation)
        
        gesture.rotation = 0
    }

    @objc func didTap(_ gesture: UITapGestureRecognizer) {

        print("didTap")
        
        if recordingNow {
        
            let alertController = UIAlertController(title: "", message: "您要停止錄影嗎？", preferredStyle: .alert)
        
            let defaultAction = UIAlertAction(title: "好的", style: .default) { _ in
            
                self.stopRecording()
            
            }
        
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
            alertController.addAction(defaultAction)
        
            alertController.addAction(cancelAction)
        
            present(alertController, animated: true, completion: nil)

            return
        }
        
        let colors: [UIColor] = [ .cubicWhite, .cubicGreenBlue, .cubicBlue, .cubicPink, .cubicBlack, .cubicGreen, .cubicOrange, .cubicYellow ]
        
        let index: Int = colorIndex % colors.count
        
        textGeometry.firstMaterial?.diffuse.contents = colors[index]
        
        colorIndex += 1
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
        
        textNode.scale = SCNVector3( myTextScale,  myTextScale, myTextScale)

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
        
        textGeometry = SCNText(string: words, extrusionDepth: 1.0)
        
        textGeometry.font = UIFont(name: "Arial", size: 10)
        
        textGeometry.flatness = 0.2
        
        textGeometry.firstMaterial?.diffuse.contents = UIColor.cubicYellow
        
        textNode = SCNNode(geometry: textGeometry)
        
        textNode.position = SCNVector3(myTextPosition.x, myTextPosition.y, myTextPosition.z)
        
        textNode.scale = SCNVector3( myTextScale,  myTextScale, myTextScale)
        
        scene.rootNode.addChildNode(textNode)

        sceneView.scene = scene
    }

    @IBAction func addWordBtnClicked(_ sender: Any) {
        
        textInputTextField.becomeFirstResponder()
        
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
        
        controlWidget(show: false)
        
        recordingNow = true
        
        RPScreenRecorder.shared().startRecording{ error in
            
            if let error = error {
                
                print("start recording error " + error.localizedDescription)
                
                return
            }
        }
    }
    
    func stopRecording() {
        
        RPScreenRecorder.shared().stopRecording { [unowned self] (preview, error) in

            if let error = error {

                print("stop recording error" + error.localizedDescription)

                return
            }

            self.controlWidget(show: true)

            self.recordingNow = false

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
            
            textInputTextField.isHidden = true
            
            startRecordBtn.isHidden = false
            
            resetBtn.isHidden = false
            
            addWordsBtn.isHidden = false
            
        } else {
            
            textSizeSlider.isHidden = true
            
            textInputTextField.isHidden = true
            
            startRecordBtn.isHidden = true
            
            resetBtn.isHidden = true
            
            addWordsBtn.isHidden = true
        }
    }
    
    // MARK: Reset
    @IBAction func resetARSession(_ sender: Any) {
        
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        textNode.removeFromParentNode()
        
        if let word = textInputTextField.text {
            
            addARWords(word)
        }
    }
}
