
// This code is taken from (GitHub, 2018)
// GitHub, (2018). ARKitRectangleDetection. [online]. Available at: https://github.com/mludowise/ARKitRectangleDetection [Accessed: 20 April 2018].
// Some modifications to the code might have been made to adjust this code for the application's needs

import ARKit

extension SCNVector3 {
    func distance(from vector: SCNVector3) -> CGFloat {
        let deltaX = self.x - vector.x
        let deltaY = self.y - vector.y
        let deltaZ = self.z - vector.z
        
        return CGFloat(sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ))
    }
    
    func midpoint(from vector: SCNVector3) -> SCNVector3 {
        let midX = (self.x + vector.x) / 2
        let midY = (self.y + vector.y) / 2
        let midZ = (self.z + vector.z) / 2
        return SCNVector3Make(midX, midY, midZ)
    }
    
    // from Apples demo APP
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}
