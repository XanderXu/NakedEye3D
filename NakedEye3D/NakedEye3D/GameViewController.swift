//
//  GameViewController.swift
//  NakedEye3D
//
//  Created by CoderXu on 2018/3/14.
//  Copyright © 2018年 XanderXu. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import AVFoundation
import Vision

class GameViewController: UIViewController {
    fileprivate var session = AVCaptureSession()
    fileprivate var deviceInput: AVCaptureDeviceInput?
    fileprivate var previewLayer = AVCaptureVideoPreviewLayer()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        // animate the 3d object
        //ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        
        addScaningVideo()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //停止扫描
        session.stopRunning()
    }
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    fileprivate func addScaningVideo(){
        //1.获取输入设备（摄像头）
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        //2.根据输入设备创建输入对象
        guard let deviceIn = try? AVCaptureDeviceInput(device: device) else { return }
        deviceInput = deviceIn
        
        //3.创建原数据的输出对象
        let metadataOutput = AVCaptureMetadataOutput()
        
        //4.设置代理监听输出对象输出的数据，在主线程中刷新
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        //4.2 设置输出代理
        
        
        //5.设置输出质量(高像素输出)
        session.sessionPreset = .high
        
        //6.添加输入和输出到会话
        if session.canAddInput(deviceInput!) {
            session.addInput(deviceInput!)
        }
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
        
        //7.告诉输出对象要输出什么样的数据,识别人脸, 最多可识别10张人脸
        metadataOutput.metadataObjectTypes = [.face]
        
        //8.创建预览图层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        
        //10. 开始扫描
        if !session.isRunning {
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }
}

//MARK: AV代理
extension GameViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for face in metadataObjects {
            let faceObj = face as? AVMetadataFaceObject
            //            let faceID = faceObj?.faceID
            //            let faceRollAngle = faceObj?.rollAngle
            print(faceObj!)
        }
        
        
    }
}
