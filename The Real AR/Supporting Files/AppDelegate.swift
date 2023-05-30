import FirebaseCore
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - UI Variables

	var window: UIWindow?
    
    // MARK: - App Delegate Methods

	func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
		FirebaseApp.configure()
		return true
	}
}
