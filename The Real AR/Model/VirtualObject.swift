final class VirtualObject {
    
    // MARK: - Variables
	
	var type: VirtualObjectType
	var xCoor: Float
	var yCoor: Float
	var zCoor: Float
	var text: String
    
    // MARK: - Initialization
	
	// for all virtual objects apart from text
	init?(type: VirtualObjectType, xCoor: Float, yCoor: Float, zCoor: Float) {
		self.type = type
		self.xCoor = xCoor
		self.yCoor = yCoor
		self.zCoor = zCoor
		self.text = ""
	}
	
	// for text
	init?(type: VirtualObjectType, xCoor: Float, yCoor: Float, zCoor: Float, text: String) {
		self.type = type
		self.xCoor = xCoor
		self.yCoor = yCoor
		self.zCoor = zCoor
		self.text = text
	}
}

enum VirtualObjectType {
	case pin
	case downArrow
	case upArrow
	case rightArrow
	case leftArrow
	case circleUpArrow
	case circleDownArrow
	case circleRightArrow
	case circleLeftArrow
	case text
}
