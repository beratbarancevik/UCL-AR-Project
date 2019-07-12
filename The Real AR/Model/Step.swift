
import Foundation

class Step {
    
    // MARK: - Variables
	
	var stepNumber: String
	var virtualObjects: [VirtualObject]
    
    // MARK: - Initialization
	
	init?(stepNumber: String, virtualObjects: [VirtualObject]) {
		self.stepNumber = stepNumber
		self.virtualObjects = virtualObjects
		
		if stepNumber.isEmpty {
			return nil
		}
	}
}

