import ARKit

extension ARHitTestResult {

    // MARK: - Properties

    var worldVector: SCNVector3 {
        SCNVector3Make(
            worldTransform.columns.3.x,
            worldTransform.columns.3.y,
            worldTransform.columns.3.z
        )
    }
}

extension Array where Element: ARHitTestResult {

    // MARK: - Properties

    var closest: ARHitTestResult? {
        sorted { $0.distance < $1.distance }.first
    }
}
