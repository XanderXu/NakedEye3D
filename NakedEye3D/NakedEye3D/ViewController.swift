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
        if renderer === demoView, let perspectiveM = perspectiveM {
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
        
        guard let phoneT = renderer.pointOfView?.simdTransform, anchor is ARFaceAnchor else {
            return
        }
        let eyeT = anchor.transform * matrix_float4x4(simd_quatf(angle: Float.pi, axis: SIMD3<Float>(0, 1, 0)))
        
        let phoneTInEye = eyeT.inverse * phoneT
        
        let close = (phoneT.inverse * anchor.transform).columns.3
        let near = -close.z
        
        let phonePInEye = phoneTInEye.columns.3
        let scaleFactor:Float = 0.01/near
        let left = (phonePInEye.x-deviceSize.x*0.5)*scaleFactor
        let right = (phonePInEye.x+deviceSize.x*0.5)*scaleFactor
        let bottom = (phonePInEye.y-deviceSize.y)*scaleFactor
        let top = (phonePInEye.y+0)*scaleFactor
        
        perspectiveM = SCNMatrix4(perspectiveOffCenter(left:left , right:right , bottom:bottom , top:top , near: near, far: 20))
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
    /*
     // look opposite direction of device cam
     Quaternion q = deviceCamera.transform.rotation * Quaternion.Euler(Vector3.up * 180);
     eyeCamera.transform.rotation = q;
     
     Vector3 deviceCamPos = eyeCamera.transform.worldToLocalMatrix.MultiplyPoint( deviceCamera.transform.position ); // find device camera in rendering camera's view space
     Vector3 fwd = eyeCamera.transform.worldToLocalMatrix.MultiplyVector (deviceCamera.transform.forward); // normal of plane defined by device camera
     Plane device_plane = new Plane( fwd, deviceCamPos);
     
     Vector3 close = device_plane.ClosestPointOnPlane (Vector3.zero);
     near = close.magnitude;
     
     // couldn't get device orientation to work properly in all cases, so just landscape for now (it's just the UI that is locked to landscape, everyting else works just fine)
     /*if (Screen.orientation == ScreenOrientation.Portrait) {
     left = trackedCamPos.x - 0.040f; // portrait iphone X
     right = trackedCamPos.x + 0.022f;
     top = trackedCamPos.y + 0.000f;
     bottom = trackedCamPos.y - 0.135f;
     } else {*/
     
     // landscape iPhone X, measures in meters
     left = deviceCamPos.x - 0.000f;
     right = deviceCamPos.x + 0.135f;
     top = deviceCamPos.y + 0.022f;
     bottom = deviceCamPos.y - 0.040f;
     
     far = 10f; // may need bigger for bigger scenes, max 10 metres for now
     */
}
