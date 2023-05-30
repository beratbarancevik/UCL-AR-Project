import ARKit
import SceneKit
import UIKit
import Vision

final class RectangleNode: SCNNode {
    
    // MARK: - Constants
    
    private let meters2inches = CGFloat(39.3701)
    
    // MARK: - Initialization
    
    convenience init(_ planeRectangle: PlaneRectangle) {
        self.init(
            center: planeRectangle.position,
            width: planeRectangle.size.width,
            height: planeRectangle.size.height,
            orientation: planeRectangle.orientation)
    }
    
    init(center position: SCNVector3, width: CGFloat, height: CGFloat, orientation: Float) {
        super.init()
        
        // Create the 3D plane geometry with the dimensions calculated from corners
        let planeGeometry = SCNPlane(width: width, height: height)
        let rectNode = SCNNode(geometry: planeGeometry)
        
        // Planes in SceneKit are vertical by default so we need to rotate
        // 90 degrees to match planes in ARKit
        var transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        
        // Set rotation to the corner of the rectangle
        transform = SCNMatrix4Rotate(transform, orientation, 0, 1, 0)
        
        rectNode.transform = transform
        
        // We add the new node to ourself since we inherited from SCNNode
        self.addChildNode(rectNode)
        
        // Set position to the center of rectangle
        self.position = position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    
}
