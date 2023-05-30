import ARKit

extension ARHitTestResult {
    
    // MARK: - Variables
    
    var worldVector: SCNVector3 {
        get {
            SCNVector3Make(
                worldTransform.columns.3.x,
                worldTransform.columns.3.y,
                worldTransform.columns.3.z)
        }
    }
}

extension Array where Element: ARHitTestResult {
    
    // MARK: - Variables
    
    var closest: ARHitTestResult? {
        get {
            return sorted { (result1, result2) -> Bool in
                return result1.distance < result2.distance
            }.first
        }
    }
}
