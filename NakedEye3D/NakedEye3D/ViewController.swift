//
//  ViewController.swift
//  Parallax
//
//  Created by 许海峰 on 2020/11/5.
//

import UIKit
import SceneKit
import ARKit
import DeviceKit
class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var demoView: SCNView!
    private var perspectiveM:SCNMatrix4?
    private var eyeTransform:simd_float4x4?
    
    lazy var deviceSize: simd_float2 = {
        let px = UIScreen.main.nativeBounds.size
        let diagonalPx = sqrt(px.width*px.width + px.height*px.height)
        let sinx = px.height/diagonalPx
        let cosx = px.width/diagonalPx
        
        let ppi = CGFloat(Device.current.ppi ?? 0)
        let diagonalCm = diagonalPx / ppi * 0.0254
        let deviceSize = simd_float2(Float(diagonalCm * cosx), Float(diagonalCm * sinx))
        return deviceSize
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Set the scene to the view
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [.showWorldOrigin]
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        demoView.scene = scene
        demoView.delegate = self
        demoView.isPlaying = true
        demoView.pointOfView?.simdPosition = simd_float3.zero
        
        addWalls()
        addBricks()
    }
    func addBricks() {
        let depth:Float = 0.2
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIImage(named: "texture")
        
//        for i in 0..<3 {
//            for j in 0..<5 {
//                let brick = SCNNode(geometry: box)
//                brick.name = "\(i),\(j)"
//                brick.simdScale = simd_float3(0.01, 0.01, 0.02*Float(i))
//                brick.simdPosition = simd_float3(-deviceSize.x*0.5, 0, (0.02-depth)*0.5)
//                demoView.scene?.rootNode.addChildNode(brick)
//            }
//        }
    }
    func addWalls() {
        let depth:Float = 0.2
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.green
        
        let left = SCNNode(geometry: box)
        left.name = "left"
        left.simdScale = simd_float3(0.01, deviceSize.y, depth)
        left.simdPosition = simd_float3(-deviceSize.x*0.5, 0, -depth*0.5)
        demoView.scene?.rootNode.addChildNode(left)
        
        let right = SCNNode(geometry: box)
        right.name = "right"
        right.simdScale = simd_float3(0.01, deviceSize.y, depth)
        right.simdPosition = simd_float3(deviceSize.x*0.5, 0, -depth*0.5)
        demoView.scene?.rootNode.addChildNode(right)
        
        let top = SCNNode(geometry: box)
        top.name = "top"
        top.simdScale = simd_float3(deviceSize.x, 0.01, depth)
        top.simdPosition = simd_float3(0, deviceSize.y*0.5, -depth*0.5)
        demoView.scene?.rootNode.addChildNode(top)
        
        let bottom = SCNNode(geometry: box)
        bottom.name = "bottom"
        bottom.simdScale = simd_float3(deviceSize.x, 0.01, depth)
        bottom.simdPosition = simd_float3(0, -deviceSize.y*0.5, -depth*0.5)
        demoView.scene?.rootNode.addChildNode(bottom)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if renderer === demoView, let perspectiveM = perspectiveM, let eyeT = eyeTransform {
            demoView.pointOfView?.simdTransform = eyeT
            demoView.pointOfView?.camera?.projectionTransform = perspectiveM
        }
    }

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0)
        if anchor is ARFaceAnchor {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        } else {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        }
        return node
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let phoneT = renderer.pointOfView?.simdTransform, let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        let eyeT = faceAnchor.transform * matrix_float4x4(simd_quatf(angle: Float.pi, axis: SIMD3<Float>(0, 1, 0)))
        
        let phoneTInEye = eyeT.inverse * phoneT
        
        let faceInPhone = (phoneT.inverse * faceAnchor.transform).columns.3
        let near = -faceInPhone.z
        
        let phonePInEye = phoneTInEye.columns.3
        let scaleNear:Float = 0.01
        let scaleFactor:Float = scaleNear/near
        let left = (phonePInEye.x-deviceSize.x*0.5)*scaleFactor
        let right = (phonePInEye.x+deviceSize.x*0.5)*scaleFactor
        let bottom = (phonePInEye.y-deviceSize.y)*scaleFactor
        let top = (phonePInEye.y+0)*scaleFactor
        
        perspectiveM = SCNMatrix4(perspectiveOffCenter(left:left, right:right, bottom:bottom, top:top, near: scaleNear, far: 10))
        eyeTransform = phoneT * matrix_float4x4(simd_quatf(angle: Float.pi, axis: SIMD3<Float>(0, 1, 0)))
        eyeTransform?.columns.3 = phonePInEye
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func perspectiveOffCenter(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float) ->matrix_float4x4
      {
        let x = 2.0 * near / (right - left);
        let y = 2.0 * near / (top - bottom);
        let a = (right + left) / (right - left);
        let b = (top + bottom) / (top - bottom);
        let c = -(far + near) / (far - near);
        let d = -(2.0 * far * near) / (far - near);
        let e:Float = -1.0;
        
        let m = matrix_float4x4(
            simd_float4(x, 0, 0, 0),
            simd_float4(0, y, 0, 0),
            simd_float4(a, b, c, e),
            simd_float4(0, 0, d, 0)
        )
        
        return m;
      }
//    https://github.com/algomystic/TheParallaxView
    /*
     // look opposite direction of device cam
     Quaternion q = deviceCamera.transform.rotation * Quaternion.Euler(Vector3.up * 180);
     eyeCamera.transform.rotation = q;
     
     Vector3 deviceCamPos = eyeCamera.transform.worldToLocalMatrix.MultiplyPoint( deviceCamera.transform.position ); // find device camera in rendering camera's view space
     Vector3 fwd = eyeCamera.transform.worldToLocalMatrix.MultiplyVector (deviceCamera.transform.forward); // normal of plane defined by device camera
     Plane device_plane = new Plane( fwd, deviceCamPos);
     
     Vector3 close = device_plane.ClosestPointOnPlane (Vector3.zero);
     near = close.magnitude;
     
     
     // landscape iPhone X, measures in meters
     left = deviceCamPos.x - 0.000f;
     right = deviceCamPos.x + 0.135f;
     top = deviceCamPos.y + 0.022f;
     bottom = deviceCamPos.y - 0.040f;
     
     far = 10f; // may need bigger for bigger scenes, max 10 metres for now
     */
}
