
import UIKit

class SceneCell: UITableViewCell {

	var scene: Scene? {
		didSet {
			updateUI()
		}
	}
	
	@IBOutlet weak var sceneNameLabel: UILabel!
	
	func updateUI() {
		if let scene = self.scene {
			sceneNameLabel.text = scene.name
		}
	}
}
