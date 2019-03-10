
import Foundation

class Scene {
    
    // MARK: - Variables
	
	var name: String
	var steps: Array<Step>
    
    // MARK: - Initialization
	
	init?(name: String, steps: Array<Step>) {
		self.name = name
		self.steps = steps

		if name.isEmpty {
			return nil
		}
	}
}
