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
    fileprivate var cameraNode = SCNNode()
    fileprivate var previewLayer = AVCaptureVideoPreviewLayer()
    fileprivate var previewView = { () -> UIView in
        let preview = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 150))
        return preview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScene()
        
        addScaningVideo()
        
        view.addSubview(previewView)
        //创建预览图层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        previewView.layer.addSublayer(previewLayer)
        previewLayer.frame = previewView.bounds
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //停止扫描
        session.stopRunning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    fileprivate func setScene() {
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)
        // create and add a camera to the scene
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 500;
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 9)
        let constraint = SCNLookAtConstraint(target: ship)
        cameraNode.constraints = [constraint]

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
        
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
    }
    fileprivate func addScaningVideo(){
        //1.获取输入设备（摄像头）
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {return}
        
        //2.根据输入设备创建输入对象
        guard let deviceIn = try? AVCaptureDeviceInput(device: device) else { return }
        
        
        //3.创建原数据的输出对象
        let videoDataOutput = AVCaptureVideoDataOutput()
        
        //4.设置代理监听输出对象输出的数据，在主线程中刷新
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        //4.2 设置输出代理
        
        //5.设置输出质量
        session.sessionPreset = .low
        
        //6.添加输入和输出到会话
        if session.canAddInput(deviceIn) {
            session.addInput(deviceIn)
        }
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        
        //10. 开始扫描
        if !session.isRunning {
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }
}

//MARK: AV代理
extension GameViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("return"); return;
        }
        //移除旧矩形框
        for sublayer in self.previewView.layer.sublayers! {
            if sublayer != self.previewLayer {
                sublayer.removeFromSuperlayer()
            }
        }
        // 创建处理requestHandler
        let faceRequest = VNDetectFaceRectanglesRequest { (request2, error) in
            //print("results---\(request2.results)")
            guard let results = request2.results else {return}
            
            for observation in results {
                if let face = observation as? VNFaceObservation {
                    //print("face---\(face.boundingBox)==\(face.confidence)")
                    
                    let oldRect = face.boundingBox;
                    let w = oldRect.size.width * self.previewView.bounds.size.width;
                    let h = oldRect.size.height * self.previewView.bounds.size.height;
                    let x = (1-oldRect.origin.x) * self.previewView.bounds.size.width - w;
                    let y = (1 - oldRect.origin.y) * self.previewView.bounds.size.height - h;
                    
                    // 添加矩形
                    let testLayer = CALayer();
                    testLayer.borderWidth = 2;
                    testLayer.cornerRadius = 3;
                    testLayer.borderColor = UIColor.red.cgColor;
                    testLayer.frame = CGRect(x: x, y: y, width: w, height: h)
                    
                    self.previewView.layer.addSublayer(testLayer);
                    
                    
                    self.cameraNode.position = SCNVector3Make(Float((0.5-oldRect.origin.x) * 10), Float(oldRect.origin.y * 10), Float( 20 / oldRect.size.width) + 8)
                }
            }
        }

        let detectFaceRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        
        do {
            try detectFaceRequestHandler.perform([faceRequest])
        } catch  {
            //error异常对象
            print("error---\(error)")
        }
        
        
    }
}
