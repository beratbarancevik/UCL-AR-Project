import FirebaseCore
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - UI Properties

	var window: UIWindow?

    // MARK: - UIApplicationDelegate

	func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
		FirebaseApp.configure()
		return true
	}
}
