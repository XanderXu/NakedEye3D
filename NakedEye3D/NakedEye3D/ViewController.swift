//
//  ViewController.swift
//  Parallax
//
//  Created by 许海峰 on 2020/11/5.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var demoView: SCNView!
    
    
    var shipNode:SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        demoView.scene = scene
        demoView.isPlaying = true
        demoView.pointOfView?.simdPosition = simd_float3.zero
        shipNode = scene.rootNode.childNode(withName: "ship", recursively: true)
        // Set the scene to the view
        sceneView.scene = SCNScene()
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
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        if anchor is ARFaceAnchor {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        } else {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        }
        return node
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let phoneT = renderer.pointOfView?.simdTransform else {
            return
        }
        let eyeT = anchor.transform * matrix_float4x4(simd_quatf(angle: Float.pi, axis: SIMD3<Float>(0, 1, 0)))
        
        let phoneTInEye = eyeT.inverse * phoneT
        let phonePInEye = phoneTInEye.columns.3
        
        let close = (phoneT.inverse * anchor.transform).columns.3
        
        let near = -close.z
        
        let scaleFactor:Float = 6//0.01/near
        let left = (phonePInEye.x-0.031)*scaleFactor
        let right = (phonePInEye.x+0.031)*scaleFactor
        let bottom = (phonePInEye.y-0.135)*scaleFactor
        let top = (phonePInEye.y+0)*scaleFactor
        
        let perspectiveM = SCNMatrix4(perspectiveOffCenter(left:left , right:right , bottom:bottom , top:top , near: near, far: 100))
        
        demoView.pointOfView?.camera?.projectionTransform = perspectiveM
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

}
