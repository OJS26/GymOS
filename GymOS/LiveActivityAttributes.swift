import ActivityKit
import Foundation

public struct GymOSActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var workoutName: String
        public var isActive: Bool
        
        public init(workoutName: String, isActive: Bool) {
            self.workoutName = workoutName
            self.isActive = isActive
        }
    }
    
    public var startTime: Date
    
    public init(startTime: Date) {
        self.startTime = startTime
    }
}
