
import UIKit

class AddNameViewController: UIViewController, UITextFieldDelegate {
	
	// MARK: - UI Variables

	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var proceedButton: UIButton!
	
	// MARK: - View Controller Life Cycle Methods
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		nameTextField.setLeftPadding(20)
		nameTextField.setRightPadding(20)
		nameTextField.delegate = self
		nameTextField.addTarget(
            self,
            action: #selector(textFieldDidChange(_:)),
            for: .editingChanged)
		nameTextField.becomeFirstResponder()
		
		proceedButton.layer.cornerRadius = 25
		proceedButton.isEnabled = false
		proceedButton.setTitleColor(UIColor.gray, for: .disabled)
		proceedButton.addTarget(self, action: #selector(proceedButtonDidTap), for: .touchUpInside)
    }
	
	// MARK: User Interaction Functions
	
	@objc func textFieldDidChange(_ textField: UITextField) {
		if let name = nameTextField.text {
			if !name.isEmpty {
				proceedButton.isEnabled = true
			} else {
				proceedButton.isEnabled = false
			}
		}
	}
	
	@objc func proceedButtonDidTap(_ sender: UIButton) {
		UIView.animate(withDuration: 0.1, animations: { sender.alpha = 0.3 }) { (finished) in
			sender.alpha = 1.0
		}
	}
	
	// MARK: - Segue Functions
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "create_new_scene_segue") {
			if let destinationViewController = segue.destination as? CreateSceneViewController {
				if let sceneName = nameTextField.text {
					destinationViewController.sceneName = sceneName
				}
			}
		}
	}
}
