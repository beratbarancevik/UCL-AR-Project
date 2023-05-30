import UIKit

final class SceneCell: UITableViewCell {
    
    // MARK: - UI Properties
    
    @IBOutlet weak var sceneNameLabel: UILabel!
    
    // MARK: - Properties

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
