final class Scene {
	var name: String
	var steps: [Step]
    
    // MARK: - Initialization
	init?(name: String, steps: [Step]) {
		self.name = name
		self.steps = steps

		if name.isEmpty {
			return nil
		}
	}
}
