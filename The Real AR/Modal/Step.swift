
import Foundation

class Step {
    
    // MARK: - Variables
	
	var stepNumber: String
	var virtualObjects: Array<VirtualObject>
    
    // MARK: - Initialization
	
	init?(stepNumber: String, virtualObjects: Array<VirtualObject>) {
		self.stepNumber = stepNumber
		self.virtualObjects = virtualObjects
		
		if stepNumber.isEmpty {
			return nil
		}
	}
}

