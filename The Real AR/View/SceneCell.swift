
import UIKit

class SceneCell: UITableViewCell {
    
    // MARK: - UI Variables
    
    @IBOutlet weak var sceneNameLabel: UILabel!
    
    // MARK: - Variables

	var scene: Scene? {
		didSet {
			updateUI()
		}
	}
    
    // MARK: - UI Manipulation Functions
	
	func updateUI() {
		if let scene = self.scene {
			sceneNameLabel.text = scene.name
		}
	}
}
