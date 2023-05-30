import UIKit

final class AddNameViewController: UIViewController, UITextFieldDelegate {
	
	// MARK: - UI Properties

	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var proceedButton: UIButton!
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		nameTextField.setLeftPadding(20)
		nameTextField.setRightPadding(20)
		nameTextField.delegate = self
		nameTextField.addTarget(
            self,
            action: #selector(textFieldDidChange),
            for: .editingChanged
        )
		nameTextField.becomeFirstResponder()
		
		proceedButton.layer.cornerRadius = 25
		proceedButton.isEnabled = false
		proceedButton.setTitleColor(.gray, for: .disabled)
		proceedButton.addTarget(self, action: #selector(proceedButtonDidTap), for: .touchUpInside)
    }
	
	// MARK: User Interaction
	
	@objc func textFieldDidChange(_ textField: UITextField) {
		if let name = nameTextField.text {
            proceedButton.isEnabled = !name.isEmpty
		}
	}
	
	@objc func proceedButtonDidTap(_ sender: UIButton) {
		UIView.animate(withDuration: 0.1, animations: { sender.alpha = 0.3 }) { _ in
			sender.alpha = 1.0
		}
	}
	
	// MARK: - Segue
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "create_new_scene_segue"),
           let destinationViewController = segue.destination as? CreateSceneViewController,
           let sceneName = nameTextField.text {
            destinationViewController.sceneName = sceneName
        }
    }
}
