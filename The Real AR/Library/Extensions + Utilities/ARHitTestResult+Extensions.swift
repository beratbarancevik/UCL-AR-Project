
// This code is taken from (GitHub, 2018)
// GitHub, (2018). ARKitRectangleDetection. [online]. Available at: https://github.com/mludowise/ARKitRectangleDetection [Accessed: 20 April 2018].
// Some modifications to the code might have been made to adjust this code for the application's needs

import Foundation
import ARKit

extension ARHitTestResult {
    var worldVector: SCNVector3 {
        get {
            return SCNVector3Make(worldTransform.columns.3.x,
                                  worldTransform.columns.3.y,
                                  worldTransform.columns.3.z)
        }
    }
}

extension Array where Element:ARHitTestResult {
    var closest: ARHitTestResult? {
        get {
            return sorted { (result1, result2) -> Bool in
                return result1.distance < result2.distance
            }.first
        }
    }
}
