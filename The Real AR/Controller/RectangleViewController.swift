
import UIKit
import SceneKit
import ARKit
import Vision

class RectangleViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - UI Variables
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    // MARK: - Internal properties used to identify the rectangle the user is selecting
    
    // Displayed rectangle outline
    private var selectedRectangleOutlineLayer: CAShapeLayer?
    
    // Observed rectangle currently being touched
    private var selectedRectangleObservation: VNRectangleObservation?
    
    // The time the current rectangle selection was last updated
    private var selectedRectangleLastUpdated: Date?
    
    // Current touch location
    private var currTouchLocation: CGPoint?
    
    // Gets set to true when actively searching for rectangles in the current frame
    private var searchingForRectangles = false
    
    // MARK: - Rendered items
    
    // RectangleNodes with keys for rectangleObservation.uuid
    private var rectangleNodes = [VNRectangleObservation:RectangleNode]()
    
    // Used to lookup SurfaceNodes by planeAnchor and update them
    private var surfaceNodes = [ARPlaneAnchor:SurfaceNode]()
    
    // MARK: - Debug properties
    
    var showDebugOptions = false {
        didSet {
            if showDebugOptions {
                sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
            } else {
                sceneView.debugOptions = []
            }
        }
    }
    
    // MARK: - Message displayed to the user
    
    private var message: Message? {
        didSet {
            DispatchQueue.main.async {
                if let message = self.message {
                    self.messageView.isHidden = false
                    self.messageLabel.text = message.localizedString
                    self.messageLabel.numberOfLines = 0
                    self.messageLabel.sizeToFit()
                    self.messageLabel.superview?.setNeedsLayout()
                } else {
                    self.messageView.isHidden = true
                }
            }
        }
    }
    
    // MARK: - View Controller Life Cycle Methods
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    var isReferenceSet = false
    
    var referenceObject: VirtualObject? {
        didSet {
            isReferenceSet = true
        }
    }
    
    var scene: Scene? {
        didSet {
            if let scene = scene {
                print("Scene Name: \(scene.name)")
                for step in scene.steps {
                    for virtualObject in step.virtualObjects {
                        print(virtualObject.xCoor)
                        print(virtualObject.yCoor)
                        print(virtualObject.zCoor)
                    }
                }
            }
        }
    }
    
    var index: Int? {
        didSet {
            if let index = index {
                print("Scene Index: \(index)")
            }
        }
    }
    
    var objectToPlace: VirtualObjectType = .pin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textButton.isHidden = true
        backButton.isHidden = true
        forwardButton.isHidden = true
        
        // Set the view's delegates
        sceneView.delegate = self
        
        // Comment out to disable rectangle tracking
        sceneView.session.delegate = self
        
        // Show world origin and feature points if desired
        if showDebugOptions {
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        }
        
        // Enable default lighting
        sceneView.autoenablesDefaultLighting = true
        
        // Create a new scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Don't display message
        message = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        // Tell user to find the a surface if we don't know of any
        if surfaceNodes.isEmpty {
            message = .helpFindSurface
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let currentFrame = sceneView.session.currentFrame else {
                return
        }
        
        currTouchLocation = touch.location(in: sceneView)
        findRectangle(locationInScene: currTouchLocation!, frame: currentFrame)
        message = .helpTapReleaseRect
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ignore if we're currently searching for a rect
        if searchingForRectangles {
            return
        }
        
        guard let touch = touches.first,
            let currentFrame = sceneView.session.currentFrame else {
                return
        }
        
        currTouchLocation = touch.location(in: sceneView)
        findRectangle(locationInScene: currTouchLocation!, frame: currentFrame)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currTouchLocation = nil
        message = .helpTapHoldRect
        
        guard let selectedRect = selectedRectangleObservation else {
            return
        }
        
        // Create a planeRect and add a RectangleNode
        addPlaneRect(for: selectedRect)
    }
    
    // MARK: - ARSessionDelegate
    
    // Update selected rectangle if it's been more than 1 second and the screen is still being touched
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if searchingForRectangles {
            return
        }
        
        guard let currTouchLocation = currTouchLocation,
            let currentFrame = sceneView.session.currentFrame else {
                return
        }
        
        if selectedRectangleLastUpdated?.timeIntervalSinceNow ?? 0 < 1 {
            return
        }
        
        findRectangle(locationInScene: currTouchLocation, frame: currentFrame)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let surface = SurfaceNode(anchor: anchor)
        surfaceNodes[anchor] = surface
        node.addChildNode(surface)
        
        if message == .helpFindSurface {
            message = .helpTapHoldRect
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // See if this is a plane we are currently rendering
        guard let anchor = anchor as? ARPlaneAnchor,
            let surface = surfaceNodes[anchor] else {
                return
        }
        
        surface.update(anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor,
            let surface = surfaceNodes[anchor] else {
                return
        }
        
        surface.removeFromParentNode()
        
        surfaceNodes.removeValue(forKey: anchor)
    }
    
    // MARK: - Helper Methods
    
    // Updates selectedRectangleObservation with the the rectangle found in the given ARFrame at the given location
    private func findRectangle(locationInScene location: CGPoint, frame currentFrame: ARFrame) {
        // Note that we're actively searching for rectangles
        searchingForRectangles = true
        selectedRectangleObservation = nil
        
        // Perform request on background thread
        DispatchQueue.global(qos: .background).async {
            let request = VNDetectRectanglesRequest(completionHandler: { (request, error) in
                
                // Jump back onto the main thread
                DispatchQueue.main.async {
                    
                    // Mark that we've finished searching for rectangles
                    self.searchingForRectangles = false
                    
                    // Access the first result in the array after casting the array as a VNClassificationObservation array
                    guard let observations = request.results as? [VNRectangleObservation],
                        let _ = observations.first else {
                            print ("No results")
                            self.message = .errNoRect
                            return
                    }
                    
                    print("\(observations.count) rectangles found")
                    
                    // Remove outline for selected rectangle
                    if let layer = self.selectedRectangleOutlineLayer {
                        layer.removeFromSuperlayer()
                        self.selectedRectangleOutlineLayer = nil
                    }
                    
                    // Find the rect that overlaps with the given location in sceneView
                    guard let selectedRect = observations.filter({ (result) -> Bool in
                        let convertedRect = self.sceneView.convertFromCamera(result.boundingBox)
                        return convertedRect.contains(location)
                    }).first else {
                        print("No results at touch location")
                        self.message = .errNoRect
                        return
                    }
                    
                    // Outline selected rectangle
                    let points = [selectedRect.topLeft, selectedRect.topRight, selectedRect.bottomRight, selectedRect.bottomLeft]
                    let convertedPoints = points.map { self.sceneView.convertFromCamera($0) }
                    self.selectedRectangleOutlineLayer = self.drawPolygon(convertedPoints, color: UIColor.red)
                    self.sceneView.layer.addSublayer(self.selectedRectangleOutlineLayer!)
                    
                    // Track the selected rectangle and when it was found
                    self.selectedRectangleObservation = selectedRect
                    self.selectedRectangleLastUpdated = Date()
                    
                    // Check if the user stopped touching the screen while we were in the background.
                    // If so, then we should add the planeRect here instead of waiting for touches to end.
                    if self.currTouchLocation == nil {
                        // Create a planeRect and add a RectangleNode
                        self.addPlaneRect(for: selectedRect)
                    }
                }
            })
            
            // Don't limit resulting number of observations
            request.maximumObservations = 0
            
            // Perform request
            let handler = VNImageRequestHandler(cvPixelBuffer: currentFrame.capturedImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func addPlaneRect(for observedRect: VNRectangleObservation) {
        // Remove old outline of selected rectangle
        if let layer = selectedRectangleOutlineLayer {
            layer.removeFromSuperlayer()
            selectedRectangleOutlineLayer = nil
        }
        
        // Convert to 3D coordinates
        guard let planeRectangle = PlaneRectangle(for: observedRect, in: sceneView) else {
            print("No plane for this rectangle")
            message = .errNoPlaneForRect
            return
        }
        
        let rectangleNode = RectangleNode(planeRectangle)
        rectangleNodes[observedRect] = rectangleNode
        addPin(for: planeRectangle)
    }
    
    var stepCount = 1
    
    var stepText = ""
    
    private func addPin(for planeRectangle: PlaneRectangle) {
        
        forwardButton.isHidden = false
        
        if self.scene?.steps.count == 1 {
            forwardButton.setImage(UIImage(named: "save"), for: .normal)
        }
        
        referenceObject = VirtualObject(type: .pin, xCoor: planeRectangle.position.x, yCoor: planeRectangle.position.y, zCoor: planeRectangle.position.z)
        
        for step in (scene?.steps)! {
            
            if step.stepNumber.elementsEqual("step_\(stepCount)") {
                for virtualObject in step.virtualObjects {
                    let x = (referenceObject?.xCoor)! - virtualObject.xCoor
                    let y = (referenceObject?.yCoor)! - virtualObject.yCoor
                    let z = (referenceObject?.zCoor)! - virtualObject.zCoor
                    
                    objectToPlace = virtualObject.type
                    
                    if virtualObject.type == .text {
                        textButton.isHidden = false
                        stepText.append(virtualObject.text)
                    }
                    
                    let position = SCNVector3Make(x, y, z)
                    let pinNode = createObjectFromScene(position)!
                    sceneView.scene.rootNode.addChildNode(pinNode)
                    
                    nodesArray.append(pinNode)
                }
            }
            
        }
    }
    
    private func createGreenPinFromScene(_ position: SCNVector3) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "art.scnassets/green_pin", withExtension: "dae") else {
            print("Could not find pin scene")
            return nil
        }
        guard let node = SCNReferenceNode(url: url) else { return nil }
        
        node.load()
        
        // Position scene
        node.position = position
        
        return node
    }
    
    private func createObjectFromScene(_ position: SCNVector3) -> SCNNode? {
        if self.objectToPlace == .pin {
            guard let url = Bundle.main.url(forResource: "art.scnassets/blue_pin", withExtension: "dae") else {
                print("Could not find pin scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else if self.objectToPlace == .downArrow {
            guard let url = Bundle.main.url(forResource: "art.scnassets/arrow_down", withExtension: "dae") else {
                print("Could not find down arrow scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.scale = SCNVector3Make(0.1, 0.1, 0.1)
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else if self.objectToPlace == .upArrow {
            guard let url = Bundle.main.url(forResource: "art.scnassets/arrow_up", withExtension: "dae") else {
                print("Could not find up arrow scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.scale = SCNVector3Make(0.1, 0.1, 0.1)
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else if self.objectToPlace == .rightArrow {
            guard let url = Bundle.main.url(forResource: "art.scnassets/arrow_right", withExtension: "dae") else {
                print("Could not find right arrow scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.scale = SCNVector3Make(0.1, 0.1, 0.1)
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else if self.objectToPlace == .leftArrow {
            guard let url = Bundle.main.url(forResource: "art.scnassets/arrow_left", withExtension: "dae") else {
                print("Could not find left arrow scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.scale = SCNVector3Make(0.1, 0.1, 0.1)
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else if self.objectToPlace == .circleUpArrow {
            guard let url = Bundle.main.url(forResource: "art.scnassets/arrow_up_circle", withExtension: "dae") else {
                print("Could not find circle up arrow scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.scale = SCNVector3Make(0.1, 0.1, 0.1)
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else if self.objectToPlace == .circleDownArrow {
            guard let url = Bundle.main.url(forResource: "art.scnassets/arrow_down_circle", withExtension: "dae") else {
                print("Could not find circle down arrow scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.scale = SCNVector3Make(0.1, 0.1, 0.1)
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else if self.objectToPlace == .circleRightArrow {
            guard let url = Bundle.main.url(forResource: "art.scnassets/arrow_right_circle", withExtension: "dae") else {
                print("Could not find circle right arrow scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.scale = SCNVector3Make(0.1, 0.1, 0.1)
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else if self.objectToPlace == .circleLeftArrow {
            guard let url = Bundle.main.url(forResource: "art.scnassets/arrow_left_circle", withExtension: "dae") else {
                print("Could not find circle left arrow scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.scale = SCNVector3Make(0.1, 0.1, 0.1)
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        } else {
            guard let url = Bundle.main.url(forResource: "art.scnassets/blue_pin", withExtension: "dae") else {
                print("Could not find blue pin scene")
                return nil
            }
            
            guard let node = SCNReferenceNode(url: url) else { return nil }
            
            node.load()
            
            // Position scene
            node.position = position
            
            return node
        }
    }
    
    private func drawPolygon(_ points: [CGPoint], color: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        layer.strokeColor = color.cgColor
        layer.lineWidth = 2
        let path = UIBezierPath()
        path.move(to: points.last!)
        points.forEach { point in
            path.addLine(to: point)
        }
        layer.path = path.cgPath
        return layer
    }
    
    // MARK: - User Interaction Functions
    
    @IBAction func textDidTap(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let textView = UITextView()
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let controller = UIViewController()
        
        textView.frame = controller.view.frame
        controller.view.addSubview(textView)
        textView.font = UIFont(name: "Avenir", size: 18.0)
        textView.isEditable = false
        textView.text = stepText
        
        alert.setValue(controller, forKey: "contentViewController")
        
        let height: NSLayoutConstraint = NSLayoutConstraint(item: alert.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.1, constant: self.view.frame.height * 0.4)
        alert.view.addConstraint(height)
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    var nodesArray = Array<SCNNode>()
    
    @IBAction func nextDidTap(_ sender: UIButton) {
        for item in nodesArray {
            item.removeFromParentNode()
        }
        
        nodesArray.removeAll()
        
        stepCount += 1
        
        textButton.isHidden = true
        
        stepText = ""
        
        for step in (scene?.steps)! {
            
            if step.stepNumber.elementsEqual("step_\(stepCount)") {
                for virtualObject in step.virtualObjects {
                    let x = (referenceObject?.xCoor)! - virtualObject.xCoor
                    let y = (referenceObject?.yCoor)! - virtualObject.yCoor
                    let z = (referenceObject?.zCoor)! - virtualObject.zCoor
                    
                    if virtualObject.type == .text {
                        textButton.isHidden = false
                        stepText.append(virtualObject.text)
                    }
                    
                    let position = SCNVector3Make(x, y, z)
                    let pinNode = createObjectFromScene(position)!
                    sceneView.scene.rootNode.addChildNode(pinNode)
                    
                    nodesArray.append(pinNode)
                }
            }
            
        }
        
        if nodesArray.isEmpty {
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        if stepCount == scene?.steps.count {
            forwardButton.setImage(UIImage(named: "save"), for: .normal)
        }
        
        backButton.isHidden = false
    }
    
    @IBAction func backDidTap(_ sender: UIButton) {
        if stepCount > 1 {
            for item in nodesArray {
                item.removeFromParentNode()
            }
            
            nodesArray.removeAll()
            
            stepCount -= 1
            
            textButton.isHidden = true
            
            stepText = ""
            
            if stepCount == 1 {
                backButton.isHidden = true
            }
            
            for step in (scene?.steps)! {
                
                if step.stepNumber.elementsEqual("step_\(stepCount)") {
                    for virtualObject in step.virtualObjects {
                        let x = (referenceObject?.xCoor)! - virtualObject.xCoor
                        let y = (referenceObject?.yCoor)! - virtualObject.yCoor
                        let z = (referenceObject?.zCoor)! - virtualObject.zCoor
                        
                        if virtualObject.type == .text {
                            textButton.isHidden = false
                            stepText.append(virtualObject.text)
                        }
                        
                        let position = SCNVector3Make(x, y, z)
                        let pinNode = createObjectFromScene(position)!
                        sceneView.scene.rootNode.addChildNode(pinNode)
                        
                        nodesArray.append(pinNode)
                    }
                }
                
            }
            
            forwardButton.setImage(UIImage(named: "next"), for: .normal)
        }
    }
    
    @IBAction func homeDidTap(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}
