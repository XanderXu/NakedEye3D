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
    fileprivate var previewView = UIView()
    fileprivate var rectLayer = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //3D场景加载
        setScene()
        //视频开启
        addScaningVideo()
        //预览界面
        addPreview()
        
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
        let ship = scene.rootNode.childNode(withName: "endBox", recursively: true)
        // create and add a camera to the scene
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 500;
        //cameraNode.camera?.usesOrthographicProjection = true
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 20)
        let constraint = SCNLookAtConstraint(target: ship)
        cameraNode.constraints = [constraint]

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 0, z: 15)
        scene.rootNode.addChildNode(lightNode)
        
        
        let lightNode2 = SCNNode()
        lightNode2.light = SCNLight()
        lightNode2.light!.type = .ambient
        lightNode2.light?.color = UIColor.gray
        lightNode2.position = SCNVector3(x: 0, y: 0, z: 15)
        scene.rootNode.addChildNode(lightNode2)
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        //scnView.autoenablesDefaultLighting = true
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
        
        //3.创建视频数据的输出对象(用于Vision框架人脸识别)
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        //4. 创建元数据的输出对象(用于AVFoundation框架人脸识别)
        let metaDataOutput = AVCaptureMetadataOutput()
        metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        //5.设置输出质量
        session.sessionPreset = .low
        
        //6.添加输入和输出到会话
        if session.canAddInput(deviceIn) {
            session.addInput(deviceIn)
        }
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        if session.canAddOutput(metaDataOutput) {
            session.addOutput(metaDataOutput)
        }
        //7.AVFoundation框架识别类型
        metaDataOutput.metadataObjectTypes = [.face]
        //8. 开始扫描
        if !session.isRunning {
            DispatchQueue.global().async {
                self.session.startRunning()
            }
        }
    }
    
    fileprivate func addPreview(){
        //预览显示view
        previewView.frame = CGRect(x: 0, y: 0, width: 100, height: 150)
        view.addSubview(previewView)
        //创建预览layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer)
        previewLayer.frame = previewView.bounds
        
        //识别方框
        rectLayer.borderWidth = 2;
        rectLayer.cornerRadius = 3;
        rectLayer.borderColor = UIColor.red.cgColor;
        rectLayer.isHidden = true
        self.previewView.layer.addSublayer(rectLayer);
    }
}

//MARK: AV代理
extension GameViewController: AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for obj in metadataObjects {
            if obj.type == .face {
                print("face---\(obj.bounds)")
                // 坐标转换
                let oldRect = obj.bounds;
                let w = oldRect.size.height * self.previewView.bounds.size.width;
                let h = oldRect.size.width * self.previewView.bounds.size.height;
                let x = oldRect.origin.y * self.previewView.bounds.size.width;
                let y = oldRect.origin.x * self.previewView.bounds.size.height;
                
                // 添加矩形
                rectLayer.frame = CGRect(x: x, y: y, width: w, height: h)
                rectLayer.isHidden = false
                
                
                let cameraX = (oldRect.origin.y - 0.3) * 3
                let cameraY = (0.8 - oldRect.origin.x) * 3
                // 移动摄像机
                self.cameraNode.position = SCNVector3(cameraX, cameraY, 20)
            }else {
                rectLayer.isHidden = true
            }
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //太卡了,先不用了...
        return
        
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("return"); return;
        }
        // 创建处理request回调
        let faceRequest = VNDetectFaceRectanglesRequest { (request2, error) in
            //print("results---\(request2.results)")
            guard let results = request2.results else {return}
            
            for observation in results {
                if let face = observation as? VNFaceObservation {
                    //print("face---\(face.boundingBox)==\(face.confidence)")
                    // 坐标转换
                    let oldRect = face.boundingBox;
                    let w = oldRect.size.width * self.previewView.bounds.size.width;
                    let h = oldRect.size.height * self.previewView.bounds.size.height;
                    let x = (1-oldRect.origin.x) * self.previewView.bounds.size.width - w;
                    let y = (1 - oldRect.origin.y) * self.previewView.bounds.size.height - h;
                    
                    // 更新矩形
                    self.rectLayer.frame = CGRect(x: x, y: y, width: w, height: h)
                    self.rectLayer.isHidden = false

                    //移动摄像机
                    self.cameraNode.simdPosition = float3(Float((0.5-oldRect.origin.x) * 10), Float(oldRect.origin.y * 10), Float( 20 / oldRect.size.width) + 8)
                    
                }else {
                    self.rectLayer.isHidden = true
                }
            }
        }

        // 创建Handler
        let detectFaceRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        
        // 开始识别
        do {
            try detectFaceRequestHandler.perform([faceRequest])
        } catch  {
            //error异常对象
            print("error---\(error)")
        }
        
        
    }
}
