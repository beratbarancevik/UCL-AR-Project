
import UIKit
import SwiftMessages

// paddings for customised text field
extension UITextField {
	func setLeftPadding(_ amount: CGFloat) {
		let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
		self.leftView = paddingView
		self.leftViewMode = .always
	}
	
	func setRightPadding(_ amount: CGFloat) {
		let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
		self.rightView = paddingView
		self.rightViewMode = .always
	}
}

// customised messages using SwiftMessages
extension UIViewController {
	func showError() {
		let view = MessageView.viewFromNib(layout: .statusLine)
		view.configureTheme(.error)
		view.configureDropShadow()
		view.configureContent(body: "Ooops! Error :(")
		var config = SwiftMessages.Config()
		config.presentationStyle = .top
		config.duration = .forever
		config.dimMode = .gray(interactive: true)
		config.interactiveHide = true
		config.preferredStatusBarStyle = .lightContent
		SwiftMessages.show(config: config, view: view)
	}
	
	func showError(with message: String) {
		let view = MessageView.viewFromNib(layout: .statusLine)
		view.configureTheme(.error)
		view.configureDropShadow()
		view.configureContent(body: message)
		var config = SwiftMessages.Config()
		config.presentationStyle = .top
		config.duration = .forever
		config.dimMode = .gray(interactive: true)
		config.interactiveHide = true
		config.preferredStatusBarStyle = .lightContent
		SwiftMessages.show(config: config, view: view)
	}
}
