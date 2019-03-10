
// This code is taken from (GitHub, 2018)
// GitHub, (2018). ARKitRectangleDetection. [online]. Available at: https://github.com/mludowise/ARKitRectangleDetection [Accessed: 20 April 2018].
// Some modifications to the code might have been made to adjust this code for the application's needs

import Foundation

// messages for AR scenes
enum Message {
    
    // instruct the user to move their phone to identify a surface
    case helpFindSurface
    
    // instruct the user to tap & hold on a rectangle to identify it
    case helpTapHoldRect
    
    // instruct the user to release their finger to select the rectangle
    case helpTapReleaseRect
    
    // no rectangle is detected
    case errNoRect
    
    // no surface cannot be found for the identified rectangle
    case errNoPlaneForRect
}

// messages for AR scenes
extension Message {
    var localizedString: String {
        get {
            switch(self) {
            case .helpFindSurface:
                return NSLocalizedString("Move your phone until you see a blue grid covering the surface of your rectangle.", comment: "")
            case .helpTapHoldRect:
                return NSLocalizedString("Tap and hold to select a rectangle.", comment: "")
            case .helpTapReleaseRect:
                return NSLocalizedString("Release your finger to finalize your selection.", comment: "")
            case .errNoRect:
                return NSLocalizedString("The rectangle couldn't be identified. Try moving your phone to another angle.", comment: "")
            case .errNoPlaneForRect:
                return String(format: NSLocalizedString("The rectangle's surface wasn't found. %@", comment: ""), Message.helpFindSurface.localizedString)
            }
        }
    }
}
