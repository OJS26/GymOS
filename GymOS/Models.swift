import SwiftUI
import Foundation

// MARK: - Rest Timer Settings
struct RestTimerSettings: Codable {
    var isEnabled: Bool = true
    var autoStart: Bool = true
    var showMilestoneHaptics: Bool = true // Haptic feedback at 1min, 1.5min, 2min
    
    // Custom initializer for default values
    init(isEnabled: Bool = true, autoStart: Bool = true, showMilestoneHaptics: Bool = true) {
        self.isEnabled = isEnabled
        self.autoStart = autoStart
        self.showMilestoneHaptics = showMilestoneHaptics
    }
}

// MARK: - Exercise Model
struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: ExerciseCategory
    let muscleGroups: [String]
    let isCustom: Bool // Track if user created this exercise
    var note: String = "" // Persistent note - shows every time (e.g. form cues)
    
    init(name: String, category: ExerciseCategory, muscleGroups: [String], isCustom: Bool = false, note: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.isCustom = isCustom
        self.note = note
    }
    
    enum ExerciseCategory: String, CaseIterable, Codable {
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case arms = "Arms"
        case legs = "Legs"
        case core = "Core"
        case cardio = "Cardio"
    }
}

// MARK: - Workout Day Template
struct WorkoutDay: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
    var color: String // Store color as hex string
    
    init(name: String, exercises: [Exercise] = [], color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.color = color
    }
    
    var uiColor: Color {
        Color(hex: color) ?? .blue
    }
}

// MARK: - Workout Set
struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var reps: Int
    var weight: Double
    var isCompleted: Bool = false
    var restTime: TimeInterval?
    
    init(reps: Int, weight: Double, isCompleted: Bool = false, restTime: TimeInterval? = nil) {
        self.id = UUID()
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.restTime = restTime
    }
}

// MARK: - Exercise Session
struct ExerciseSession: Identifiable, Codable {
    let id: UUID
    let exercise: Exercise
    var sets: [WorkoutSet]
    var notes: String = ""
    
    init(exercise: Exercise, sets: [WorkoutSet], notes: String = "") {
        self.id = UUID()
        self.exercise = exercise
        self.sets = sets
        self.notes = notes
    }
}

// MARK: - Workout
struct Workout: Identifiable, Codable {
    let id: UUID
    let date: Date
    var name: String
    var exercises: [ExerciseSession]
    var duration: TimeInterval = 0
    var isActive: Bool = false
    var workoutDay: WorkoutDay? // Link to the day template used
    var reflectionScore: Int? = nil // 1-10 how the session felt
    var reflectionNotes: String = ""
    
    init(date: Date, name: String, exercises: [ExerciseSession] = [], duration: TimeInterval = 0, isActive: Bool = false, workoutDay: WorkoutDay? = nil, reflectionScore: Int? = nil, reflectionNotes: String = "") {
        self.id = UUID()
        self.date = date
        self.name = name
        self.exercises = exercises
        self.duration = duration
        self.isActive = isActive
        self.workoutDay = workoutDay
        self.reflectionScore = reflectionScore
        self.reflectionNotes = reflectionNotes
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Helper to get common colors by name
    static func color(named name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .blue
        }
    }
}

// MARK: - Running Models
struct RunningSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    var distance: Double // km
    var duration: TimeInterval // seconds
    var notes: String = ""
    var isActive: Bool = false
    
    init(date: Date = Date(), distance: Double = 0, duration: TimeInterval = 0, notes: String = "", isActive: Bool = false) {
        self.id = UUID()
        self.date = date
        self.distance = distance
        self.duration = duration
        self.notes = notes
        self.isActive = isActive
    }
    
    var pace: TimeInterval {
        distance > 0 ? duration / distance : 0
    }
    
    // REPLACE the old paceString with this improved version:
    var paceString: String {
        if distance > 0 {
            // Real pace calculation when distance is available
            let minutes = Int(pace) / 60
            let seconds = Int(pace) % 60
            return String(format: "%d:%02d /km", minutes, seconds)
        } else {
            // For treadmill running without distance tracking
            let totalMinutes = duration / 60
            let minutes = Int(totalMinutes)
            let seconds = Int((totalMinutes - Double(minutes)) * 60)
            return String(format: "%d:%02d total", minutes, seconds)
        }
    }
    
    // ADD this new property:
    var averagePace: TimeInterval {
        duration / 60 // Simple time-based calculation for gym running
    }
}

extension Double {
    var clean: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ?
            String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}


