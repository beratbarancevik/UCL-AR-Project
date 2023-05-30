
import UIKit
import FirebaseDatabase
import SwiftMessages

class MainTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    // firebase db reference
    var ref: DatabaseReference!
    
    // store scenes
    var scenes = [Scene]()
    
    // MARK: - View Controller Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // remove empty cells
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
        setNeedsStatusBarAppearanceUpdate()
        
        // clean scenes array
        scenes.removeAll()
        
        // get all scenes form Firebase
        getAllScenes()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SwiftMessages.hideAll()
    }
    
    // MARK: - Data Functions
    
    // get all scenes from Firebase
    func getAllScenes() {
        ref = Database.database().reference()
        
        ref.child("scenes").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let scenesDictionary = snapshot.value as? NSDictionary else {
                print("E1")
                self.showError()
                return
            }
            
            // scenes loop
            for sceneItem in scenesDictionary {
                var steps = [Step]()
                guard let stepsDictionary = sceneItem.value as? NSDictionary else {
                    print("E2")
                    self.showError()
                    return
                }
                
                // steps loop
                for stepItem in stepsDictionary {
                    var virtualObjects = [VirtualObject]()
                    guard let virtualObjectsDictionary = stepItem.value as? NSDictionary else {
                        print("E3")
                        self.showError()
                        return
                    }
                    
                    // virtual objects loop
                    for virtualObjectItem in virtualObjectsDictionary {
                        guard let coordinatesDictionary =
                            virtualObjectItem.value as? NSDictionary else {
                                print("E4")
                                self.showError()
                                return
                        }
                        
                        var xCoor: Float?
                        var yCoor: Float?
                        var zCoor: Float?
                        
                        var typeInt: Int?
                        
                        var text: String?
                        
                        // virtual object coordinates loop
                        for coordinatesItem in coordinatesDictionary {
                            if coordinatesItem.key as! String == "x" {
                                xCoor = coordinatesItem.value as? Float
                            } else if coordinatesItem.key as! String == "y" {
                                yCoor = coordinatesItem.value as? Float
                            } else if coordinatesItem.key as! String == "z" {
                                zCoor = coordinatesItem.value as? Float
                            } else if coordinatesItem.key as! String == "t" {
                                typeInt = coordinatesItem.value as? Int
                            } else if coordinatesItem.key as! String == "text" {
                                text = coordinatesItem.value as? String
                            }
                        }
                        
                        if xCoor == nil {
                            xCoor = 0.0
                        }
                        
                        if yCoor == nil {
                            yCoor = 0.0
                        }
                        
                        if zCoor == nil {
                            zCoor = 0.0
                        }
                        
                        if text == nil {
                            text = ""
                        }
                        
                        guard let virtualObject = VirtualObject(
                            type: self.generateType(from: typeInt!),
                            xCoor: xCoor!,
                            yCoor: yCoor!,
                            zCoor: zCoor!,
                            text: text!
                            ) else {
                                print("E5")
                                self.showError()
                                return
                        }
                        virtualObjects.append(virtualObject)
                    }
                    
                    let stepNumber = stepItem.key
                    guard let step = Step(
                        stepNumber: stepNumber as! String,
                        virtualObjects: virtualObjects
                        ) else {
                            print("E6")
                            self.showError()
                            return
                    }
                    steps.append(step)
                }
                
                let sceneName = sceneItem.key
                guard let scene = Scene(name: sceneName as! String, steps: steps) else {
                    print("E7")
                    self.showError()
                    return
                }
                self.scenes.append(scene)
            }
            self.tableView.reloadData()
        }) { (error) in self.showError(); print("Firebase error: \(error.localizedDescription)") }
    }
    
    func generateType(from integer: Int) -> VirtualObjectType {
        switch integer {
        case 1:
            return .pin
        case 2:
            return .upArrow
        case 3:
            return .downArrow
        case 4:
            return .rightArrow
        case 5:
            return .leftArrow
        case 6:
            return .circleUpArrow
        case 7:
            return .circleDownArrow
        case 8:
            return .circleRightArrow
        case 9:
            return .circleLeftArrow
        case 10:
            return .text
        default:
            return .text
        }
    }
    
    // MARK: - Table View Controller Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scenes.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell {
        let cellIdentifier = "cell"
        let cell = tableView.dequeueReusableCell(
            withIdentifier: cellIdentifier,
            for: indexPath) as! SceneCell
        cell.sceneNameLabel.text = scenes[indexPath.row].name
        return cell
    }
    
    // MARK: - Segue Functions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "rectangle_segue") {
            if let destinationViewController = segue.destination as? RectangleViewController {
                if let selectedItemIndex = tableView.indexPathForSelectedRow {
                    destinationViewController.scene = scenes[selectedItemIndex.row]
                    destinationViewController.index = selectedItemIndex.row
                }
            }
        }
    }
}
