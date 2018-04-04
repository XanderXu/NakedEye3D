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
    fileprivate var cameraNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        
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
        
        addScaningVideo()
        let preview = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 150))
        view.addSubview(preview)
        preview.layer.addSublayer(previewLayer)
        previewLayer.frame = preview.frame
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //停止扫描
        session.stopRunning()
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
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {return}
        
        //2.根据输入设备创建输入对象
        guard let deviceIn = try? AVCaptureDeviceInput(device: device) else { return }
        deviceInput = deviceIn
        
        //3.创建原数据的输出对象
        let videoDataOutput = AVCaptureVideoDataOutput()
        
        //4.设置代理监听输出对象输出的数据，在主线程中刷新
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        //4.2 设置输出代理
        
        
        //5.设置输出质量(高像素输出)
        session.sessionPreset = .medium
        
        //6.添加输入和输出到会话
        if session.canAddInput(deviceInput!) {
            session.addInput(deviceInput!)
        }
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        
        //7.告诉输出对象要输出什么样的数据,识别人脸, 最多可识别10张人脸
        //metadataOutput.metadataObjectTypes = [.face]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        //8.创建预览图层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        
        
        //10. 开始扫描
        if !session.isRunning {
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }
}

//MARK: AV代理
extension GameViewController: AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for face in metadataObjects {
            let faceObj = face as? AVMetadataFaceObject
                        let faceID = faceObj?.faceID
                        let faceRollAngle = faceObj?.rollAngle
            print(faceObj!,faceID ?? 0,faceRollAngle ?? 0)
        }
        
        
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        let detectRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer!, options: [:])
        // 创建处理requestHandler
        
        let request1 = VNDetectFaceRectanglesRequest { (request, error) in
            
            print(request.results!)
            guard let observations = request.results as? [VNFaceObservation] else {return};
            for faceservation in observations {
                print(faceservation.boundingBox)
            }
        }
        do {
            try detectRequestHandler.perform([request1])
        }catch{
            //error异常对象
            print(error)
        }
        
        //print(request1.results!)
    }
}
