import UIKit

final class SceneCell: UITableViewCell {
    
    // MARK: - UI Variables
    
    @IBOutlet weak var sceneNameLabel: UILabel!
    
    // MARK: - Variables

	var scene: Scene? {
		didSet {
			updateUI()
		}
	}
    
    // MARK: - UI Manipulation
	
	func updateUI() {
		if let scene {
			sceneNameLabel.text = scene.name
		}
	}
}
