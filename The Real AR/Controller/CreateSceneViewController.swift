
import UIKit
import SceneKit
import ARKit
import Vision
import Firebase

class CreateSceneViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - UI Variables
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageView: UIView!
    
    // MARK: - Variables
    
    var sceneName: String?
    
    var isReferenceSet = false
    
    var referenceObject: VirtualObject? {
        didSet {
            isReferenceSet = true
        }
    }
    
    var stepNumber = 1
    
    var virtualObjects = [VirtualObject]()
    
    var objectToPlace: VirtualObjectType = .pin
    
    var enteredTexts = [String]()
    
    var enteredTextsIndexHolder = 0
    
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
    private var rectangleNodes = [VNRectangleObservation: RectangleNode]()
    
    // Used to lookup SurfaceNodes by planeAnchor and update them
    private var surfaceNodes = [ARPlaneAnchor: SurfaceNode]()
    
    // MARK: - Debug properties
    
    var showDebugOptions = false {
        didSet {
            if showDebugOptions {
                sceneView.debugOptions = [
                    ARSCNDebugOptions.showFeaturePoints,
                    ARSCNDebugOptions.showWorldOrigin
                ]
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
    
    var sceneCoordinates = [String]()
    var stringCoordinates = [String]()
    var floatCoordinates = [Float]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the view's delegates
        sceneView.delegate = self
        
        // comment out to disable rectangle tracking
        sceneView.session.delegate = self
        
        // enable default lighting
        sceneView.autoenablesDefaultLighting = true
        
        // create a new scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // don't display message
        message = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        
        // create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // run the sceneView session
        sceneView.session.run(configuration)
        
        // tell user to find the a surface if we don't know of any
        if surfaceNodes.isEmpty {
            message = .helpFindSurface
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
        
        // pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let currentFrame = sceneView.session.currentFrame else {
                return
        }
        
        currTouchLocation = touch.location(in: sceneView)
        
        if isReferenceSet {
            // perform hit test
            let results = sceneView.hitTest(currTouchLocation!, types: .existingPlaneUsingExtent)
            
            // if a hit was received, get position of
            if let result = results.first {
                placePin(result)
                
                let transform = result.worldTransform
                let x = (referenceObject?.xCoor)! - transform.columns.3.x
                let y = (referenceObject?.yCoor)! - transform.columns.3.y
                let z = (referenceObject?.zCoor)! - transform.columns.3.z
                let virtualObject = VirtualObject(type: objectToPlace, xCoor: x, yCoor: y, zCoor: z)
                virtualObjects.append(virtualObject!)
            }
        }
        
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
    
    // Update selected rectangle if it's been more than 1 second and the screen is still being
    // touched
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
    
    // Updates selectedRectangleObservation with the the rectangle found in the given ARFrame at the
    // given location
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
                    
                    // Access the first result in the array after casting the array as a
                    // VNClassificationObservation array
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
                    let points = [
                        selectedRect.topLeft,
                        selectedRect.topRight,
                        selectedRect.bottomRight,
                        selectedRect.bottomLeft
                    ]
                    let convertedPoints = points.map {
                        self.sceneView.convertFromCamera($0)
                    }
                    self.selectedRectangleOutlineLayer = self.drawPolygon(
                        convertedPoints,
                        color: UIColor.red)
                    self.sceneView.layer.addSublayer(self.selectedRectangleOutlineLayer!)
                    
                    // Track the selected rectangle and when it was found
                    self.selectedRectangleObservation = selectedRect
                    self.selectedRectangleLastUpdated = Date()
                    
                    // Check if the user stopped touching the screen while we were in the background
                    // If so, then we should add the planeRect here instead of waiting for touches
                    // to end
                    if self.currTouchLocation == nil {
                        // Create a planeRect and add a RectangleNode
                        self.addPlaneRect(for: selectedRect)
                    }
                }
            })
            
            // Don't limit resulting number of observations
            request.maximumObservations = 0
            
            // Perform request
            let handler = VNImageRequestHandler(
                cvPixelBuffer: currentFrame.capturedImage,
                options: [:])
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
        
        // add reference point rectangle
        let rectangleNode = RectangleNode(planeRectangle)
        rectangleNodes[observedRect] = rectangleNode
        addPin(for: planeRectangle)
    }
    
    private func addPin(for planeRectangle: PlaneRectangle) {
        let position = SCNVector3Make(
            planeRectangle.position.x,
            planeRectangle.position.y,
            planeRectangle.position.z)
        let pinNode = createGreenPinFromScene(position)!
        sceneView.scene.rootNode.addChildNode(pinNode)
        
        referenceObject = VirtualObject(
            type: objectToPlace,
            xCoor: planeRectangle.position.x,
            yCoor: planeRectangle.position.y,
            zCoor: planeRectangle.position.z)
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
    
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        // Get tap location
        let tapLocation = sender.location(in: sceneView)
        
        // Perform hit test
        let results = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        // If a hit was received, get position of
        if let result = results.first {
            placePin(result)
        } else {
            print("CANNOT PLACE PIN")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { }
        }
    }
    
    var x: Float = 0.0
    var y: Float = 0.0
    var z: Float = 0.0
    
    private func placePin(_ result: ARHitTestResult) {
        
        // Get transform of result
        let transform = result.worldTransform
        
        // Get position from transform (4th column of transformation matrix)
        let planePosition = SCNVector3Make(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z)
        
        guard let pinNode = createObjectFromScene(planePosition) else {
            return
        }
        
        sceneView.scene.rootNode.addChildNode(pinNode)
        
        nodesArray.append(pinNode)
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
    
    
    // MARK: button actions
    
    @IBAction func saveDidTap(_ sender: Any) {
        if !virtualObjects.isEmpty {
            let ref: DatabaseReference = Database.database().reference()
            
            var counter = 1
            for virtualObject in virtualObjects {
                let scenePath = "scenes/\(sceneName!)/step_\(stepNumber)/object_\(counter)"
                
                let typeInt = typeGenerator(from: virtualObject.type)
                
                if typeInt != 10 {
                    ref.child(scenePath).setValue(["t": typeInt, "x": virtualObject.xCoor, "y": virtualObject.yCoor, "z": virtualObject.zCoor]) { (error, ref) in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                } else {
                    ref.child(scenePath).setValue(["t": typeInt, "x": virtualObject.xCoor, "y": virtualObject.yCoor, "z": virtualObject.zCoor, "text": enteredTexts[enteredTextsIndexHolder]]) { (error, ref) in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    
                    enteredTextsIndexHolder += 1
                }
                
                counter += 1
            }
        } else {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func typeGenerator(from type: VirtualObjectType) -> Int {
        switch type {
        case .pin:
            return 1
        case .upArrow:
            return 2
        case .downArrow:
            return 3
        case .rightArrow:
            return 4
        case .leftArrow:
            return 5
        case .circleUpArrow:
            return 6
        case .circleDownArrow:
            return 7
        case .circleRightArrow:
            return 8
        case .circleLeftArrow:
            return 9
        case .text:
            return 10
        }
    }
    
    var nodesArray = [SCNNode]()
    
    @IBAction func undoDidTap(_ sender: UIButton) {
        if !nodesArray.isEmpty {
            if virtualObjects.last?.type != .text {
                nodesArray.last?.removeFromParentNode()
                nodesArray.removeLast()
            } else {
                enteredTexts.removeLast()
            }
            virtualObjects.removeLast()
        }
    }
    
    @IBAction func nextDidTap(_ sender: UIButton) {
        if !virtualObjects.isEmpty {
            let ref: DatabaseReference = Database.database().reference()
            
            var counter = 1
            for virtualObject in virtualObjects {
                let scenePath = "scenes/\(sceneName!)/step_\(stepNumber)/object_\(counter)"
                let typeInt = typeGenerator(from: virtualObject.type)
                
                if typeInt != 10 {
                    ref.child(scenePath).setValue(["t": typeInt, "x": virtualObject.xCoor, "y": virtualObject.yCoor, "z": virtualObject.zCoor]) { (error, ref) in
                        
                    }
                } else {
                    ref.child(scenePath).setValue(["t": typeInt, "x": virtualObject.xCoor, "y": virtualObject.yCoor, "z": virtualObject.zCoor, "text": enteredTexts[enteredTextsIndexHolder]]) { (error, ref) in
                        
                    }
                    
                    enteredTextsIndexHolder += 1
                }
                
                
                counter += 1
            }
            
            
            for item in nodesArray {
                item.removeFromParentNode()
            }
            
            
            // clear arrays
            virtualObjects.removeAll()
            enteredTexts.removeAll()
            
            // reset index
            enteredTextsIndexHolder = 0
            
            // increment step number
            stepNumber += 1
        }
    }
    
    @IBAction func objectDidTap(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Select Object", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Pin", style: .default, handler: { (action) in
            self.objectToPlace = .pin
        }))
        alertController.addAction(UIAlertAction(title: "Up Arrow", style: .default, handler: { (action) in
            self.objectToPlace = .upArrow
        }))
        alertController.addAction(UIAlertAction(title: "Down Arrow", style: .default, handler: { (action) in
            self.objectToPlace = .downArrow
        }))
        alertController.addAction(UIAlertAction(title: "Right Arrow", style: .default, handler: { (action) in
            self.objectToPlace = .rightArrow
        }))
        alertController.addAction(UIAlertAction(title: "Left Arrow", style: .default, handler: { (action) in
            self.objectToPlace = .leftArrow
        }))
        alertController.addAction(UIAlertAction(title: "Circle Up Arrow", style: .default, handler: { (action) in
            self.objectToPlace = .circleUpArrow
        }))
        alertController.addAction(UIAlertAction(title: "Circle Down Arrow", style: .default, handler: { (action) in
            self.objectToPlace = .circleDownArrow
        }))
        alertController.addAction(UIAlertAction(title: "Circle Right Arrow", style: .default, handler: { (action) in
            self.objectToPlace = .circleRightArrow
        }))
        alertController.addAction(UIAlertAction(title: "Circle Left Arrow", style: .default, handler: { (action) in
            self.objectToPlace = .circleLeftArrow
        }))
        alertController.addAction(UIAlertAction(title: "Text", style: .default, handler: { (action) in
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            let textView = UITextView()
            textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            let controller = UIViewController()
            
            textView.frame = controller.view.frame
            controller.view.addSubview(textView)
            textView.font = UIFont(name: "Avenir", size: 18.0)
            
            alert.setValue(controller, forKey: "contentViewController")
            
            let height: NSLayoutConstraint = NSLayoutConstraint(item: alert.view as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.1, constant: self.view.frame.height * 0.4)
            alert.view.addConstraint(height)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                guard let enteredText = textView.text else {
                    return
                }
                
                self.virtualObjects.append(VirtualObject(type: .text, xCoor: 0.0, yCoor: 0.0, zCoor: 0.0)!)
                self.enteredTexts.append(enteredText)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
            
            textView.becomeFirstResponder()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func homeDidTap(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}
