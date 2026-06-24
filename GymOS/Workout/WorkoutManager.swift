import SwiftUI
import Foundation
import ActivityKit

// MARK: - Workout Manager
class WorkoutManager: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var currentWorkout: Workout? {
        didSet {
            saveCurrentWorkout()
        }
    }
    @Published var availableExercises: [Exercise] = []
    @Published var workoutDays: [WorkoutDay] = []
    
    private var liveActivity: Activity<GymOSActivityAttributes>?
    
    init() {
        loadSampleExercises()
        loadSampleWorkoutDays()
        loadData()
        loadCurrentWorkout()
    }
    

    
    // MARK: - Sample Data Loading
    private func loadSampleExercises() {
        guard availableExercises.isEmpty else { return }
        
        availableExercises = [
            // CHEST
            Exercise(name: "Chest Press", category: .chest, muscleGroups: ["Upper Chest", "Mid Chest", "Front Delt", "Tricep"]),
            Exercise(name: "Pec Fly", category: .chest, muscleGroups: ["Mid Chest", "Lower Chest"]),
            Exercise(name: "Cable Fly", category: .chest, muscleGroups: ["Upper Chest", "Mid Chest", "Lower Chest"]),
            Exercise(name: "Converging Chest Press", category: .chest, muscleGroups: ["Upper Chest", "Mid Chest", "Front Delt", "Tricep"]),
            
            // BICEPS
            Exercise(name: "Preacher Curl", category: .arms, muscleGroups: ["Bicep"]),
            Exercise(name: "Hammer Curl", category: .arms, muscleGroups: ["Bicep", "Forearm"]),
            Exercise(name: "Bayesian Curl", category: .arms, muscleGroups: ["Bicep"]),
            Exercise(name: "Triple 7", category: .arms, muscleGroups: ["Bicep"], isFixedReps: true),
            Exercise(name: "Bicep Curl", category: .arms, muscleGroups: ["Bicep"]),
            
            // FOREARMS
            Exercise(name: "Forearm Curl Palm Down", category: .arms, muscleGroups: ["Forearm"]),
            Exercise(name: "Forearm Curl Palm Up", category: .arms, muscleGroups: ["Forearm"]),
            
            // CORE
            Exercise(name: "Ab Crunch Machine", category: .core, muscleGroups: ["Abs"]),
            Exercise(name: "Rope Cable Crunches", category: .core, muscleGroups: ["Abs"]),
            Exercise(name: "Leg Raises", category: .core, muscleGroups: ["Abs", "Hip Flexors"]),
            
            // BACK
            Exercise(name: "Cable Row", category: .back, muscleGroups: ["Lats", "Mid Back", "Upper Back"]),
            Exercise(name: "Single Arm Cable Row", category: .back, muscleGroups: ["Lats", "Mid Back"]),
            Exercise(name: "Lat Pulldown", category: .back, muscleGroups: ["Lats", "Mid Back", "Upper Back", "Bicep"]),
            Exercise(name: "Single Arm Lat Pulldown", category: .back, muscleGroups: ["Lats", "Mid Back", "Bicep"]),
            Exercise(name: "Lat Pullover", category: .back, muscleGroups: ["Lats"]),
            Exercise(name: "Kelso Shrug", category: .back, muscleGroups: ["Upper Back", "Mid Back"]),
            Exercise(name: "Dumbbell Row", category: .back, muscleGroups: ["Lats", "Mid Back", "Bicep"]),
            
            // TRICEPS
            Exercise(name: "Single Arm Cable Pushdown", category: .arms, muscleGroups: ["Tricep"]),
            Exercise(name: "Tricep Cable Pushdown", category: .arms, muscleGroups: ["Tricep"]),
            Exercise(name: "Overhead Tricep Extension", category: .arms, muscleGroups: ["Tricep"]),
            Exercise(name: "Tricep Dip Machine", category: .arms, muscleGroups: ["Tricep", "Lower Chest", "Front Delt"]),
            Exercise(name: "Tricep Extension Machine", category: .arms, muscleGroups: ["Tricep"]),
            
            // SHOULDERS
            Exercise(name: "Cable Lateral Raise", category: .shoulders, muscleGroups: ["Side Delt"]),
            Exercise(name: "Machine Lateral Raise", category: .shoulders, muscleGroups: ["Side Delt"]),
            Exercise(name: "Face Pulls", category: .shoulders, muscleGroups: ["Rear Delt", "Upper Back"]),
            Exercise(name: "Reverse Fly", category: .shoulders, muscleGroups: ["Rear Delt", "Upper Back"]),
            Exercise(name: "Cable Archer", category: .shoulders, muscleGroups: ["Rear Delt"]),
            
            // LEGS - GLUTES
            Exercise(name: "Glute Extension", category: .legs, muscleGroups: ["Glutes", "Lower Back"]),
            
            // LEGS - QUADS
            Exercise(name: "Quad Extension Machine", category: .legs, muscleGroups: ["Quads"]),
            Exercise(name: "Split Squat", category: .legs, muscleGroups: ["Quads", "Glutes", "Hip Flexors"]),
            Exercise(name: "Hack Squat", category: .legs, muscleGroups: ["Quads", "Glutes"]),
            Exercise(name: "Leg Press", category: .legs, muscleGroups: ["Quads", "Glutes", "Hamstrings"]),
            
            // LEGS - HAMSTRINGS
            Exercise(name: "RDL", category: .legs, muscleGroups: ["Hamstrings", "Glutes", "Lower Back"]),
            Exercise(name: "Hamstring Curl Machine", category: .legs, muscleGroups: ["Hamstrings"]),
            Exercise(name: "Goblet Squat", category: .legs, muscleGroups: ["Quads", "Glutes", "Hamstrings"]),
            Exercise(name: "Leg Press High Foot", category: .legs, muscleGroups: ["Hamstrings", "Glutes"]),
            
            // LEGS - HIPS
            Exercise(name: "Abductor Machine", category: .legs, muscleGroups: ["Hip Flexors"]),
            Exercise(name: "Adductor Machine", category: .legs, muscleGroups: ["Hip Flexors"]),
            
            // LEGS - CALVES
            Exercise(name: "Calf Raise Machine", category: .legs, muscleGroups: ["Calves"]),
        ]
    }
    
    private func loadSampleWorkoutDays() {
        guard workoutDays.isEmpty else { return }
    }
    
    // MARK: - Exercise Management
    func addCustomExercise(name: String, category: Exercise.ExerciseCategory, muscleGroups: [String]) {
        let exercise = Exercise(name: name, category: category, muscleGroups: muscleGroups, isCustom: true)
        availableExercises.append(exercise)
        saveData()
    }
    
    func persistExercises() {
        saveData()
    }
    
    func deleteExercise(_ exercise: Exercise) {
        availableExercises.removeAll { $0.id == exercise.id }
        saveData()
    }
    
    func updateExerciseNote(_ exercise: Exercise, note: String) {
        if let index = availableExercises.firstIndex(where: { $0.id == exercise.id }) {
            availableExercises[index].note = note
            saveData()
        }
    }
    
    // MARK: - Workout Day Management
    func addWorkoutDay(name: String, exercises: [Exercise], color: String) {
        let workoutDay = WorkoutDay(name: name, exercises: exercises, color: color)
        workoutDays.append(workoutDay)
        saveData()
    }
    
    func updateWorkoutDay(_ workoutDay: WorkoutDay, name: String, exercises: [Exercise], color: String) {
        if let index = workoutDays.firstIndex(where: { $0.id == workoutDay.id }) {
            workoutDays[index].name = name
            workoutDays[index].exercises = exercises
            workoutDays[index].color = color
            saveData()
        }
    }
    
    func deleteWorkoutDay(_ workoutDay: WorkoutDay) {
        workoutDays.removeAll { $0.id == workoutDay.id }
        saveData()
    }
    
    // MARK: - Workout Management
    func startWorkout(name: String = "New Workout", workoutDay: WorkoutDay? = nil) {
        var workout = Workout(
            date: Date(),
            name: name,
            exercises: [],
            isActive: true,
            workoutDay: workoutDay
        )
        
        // If starting from a template, add those exercises
        if let day = workoutDay {
            for exercise in day.exercises {
                let session = ExerciseSession(
                    exercise: exercise,
                    sets: [WorkoutSet(reps: 0, weight: 0)]
                )
                workout.exercises.append(session)
            }
        }
        
        currentWorkout = workout
        startLiveActivity(workoutName: name)
    }
    
    func finishWorkout(reflectionScore: Int, reflectionNotes: String) -> Workout? {
        guard var workout = currentWorkout else { return nil }
        workout.isActive = false
        workout.reflectionScore = reflectionScore
        workout.reflectionNotes = reflectionNotes
        workouts.insert(workout, at: 0)
        currentWorkout = nil
        stopLiveActivity()
        saveData()
        return workout
    }
    
    func addExercise(_ exercise: Exercise) {
        guard currentWorkout != nil else { return }
        let session = ExerciseSession(
            exercise: exercise,
            sets: [WorkoutSet(reps: 0, weight: 0)]
        )
        currentWorkout?.exercises.append(session)
    }
    
    func removeExercise(at index: Int) {
        guard currentWorkout != nil else { return }
        currentWorkout?.exercises.remove(at: index)
    }
    
    func moveExercise(from source: IndexSet, to destination: Int) {
        currentWorkout?.exercises.move(fromOffsets: source, toOffset: destination)
    }
    
    // MARK: - Set Management
    func addSet(to exerciseIndex: Int) {
        guard currentWorkout != nil else { return }
        let newSet = WorkoutSet(reps: 0, weight: 0)
        currentWorkout?.exercises[exerciseIndex].sets.append(newSet)
    }
    
    func updateSet(exerciseIndex: Int, setIndex: Int, reps: Int, weight: Double) {
        guard currentWorkout != nil else { return }
        currentWorkout?.exercises[exerciseIndex].sets[setIndex].reps = reps
        currentWorkout?.exercises[exerciseIndex].sets[setIndex].weight = weight
    }
    
    func completeSet(exerciseIndex: Int, setIndex: Int) {
        guard currentWorkout != nil else { return }
        currentWorkout?.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
    }
    
    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard currentWorkout != nil else { return }
        currentWorkout?.exercises[exerciseIndex].sets.remove(at: setIndex)
    }
    
    // MARK: - Data Analysis
    func getExerciseHistory(for exercise: Exercise, variation: String = "") -> [ExerciseSession] {
        return workouts.flatMap { workout in
            workout.exercises.filter {
                $0.exercise.name == exercise.name &&
                (variation.isEmpty || $0.variation == variation)
            }
        }
        .sorted { a, b in
            let aDate = workouts.first { $0.exercises.contains { $0.id == a.id } }?.date ?? Date.distantPast
            let bDate = workouts.first { $0.exercises.contains { $0.id == b.id } }?.date ?? Date.distantPast
            return aDate < bDate
        }
    }
    
    func getBestSet(for exercise: Exercise) -> WorkoutSet? {
        let history = getExerciseHistory(for: exercise)
        return history.flatMap { $0.sets }
            .filter { $0.isCompleted }
            .max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }
    
    // MARK: - Data Analysis
    var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        
        while true {
            let workoutsOnDay = workouts.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }
            if workoutsOnDay.isEmpty { break }
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }
    
    func getLastWorkoutSet(for exercise: Exercise) -> WorkoutSet? {
        let history = getExerciseHistory(for: exercise)
        return history.last?.sets.last { $0.isCompleted }
    }
    
    func getWorkouts(for date: Date) -> [Workout] {
        return workouts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func getWorkoutsByDay() -> [String: [Workout]] {
        var groupedWorkouts: [String: [Workout]] = [:]
        
        for workout in workouts {
            let dayKey = DateFormatter().string(from: workout.date)
            if groupedWorkouts[dayKey] == nil {
                groupedWorkouts[dayKey] = []
            }
            groupedWorkouts[dayKey]?.append(workout)
        }
        
        return groupedWorkouts
    }
    
    func weightSuggestion(for exercise: Exercise, variation: String) -> String? {
        guard !exercise.isFixedReps else { return nil }
        
        // Get history filtered to this specific exercise AND variation
        let history = getExerciseHistory(for: exercise, variation: variation)
        guard let lastSession = history.last else { return nil }
        
        // Only look at strength sets for progression
        let strengthSets = lastSession.sets.filter { $0.isCompleted && $0.mode == .strength }
        guard !strengthSets.isEmpty else { return nil }
        
        let avgWeight = strengthSets.map { $0.weight }.reduce(0, +) / Double(strengthSets.count)
        let avgReps = strengthSets.map { $0.reps }.reduce(0, +) / strengthSets.count
        
        let suggested = avgReps >= 10 ? avgWeight + 2.5 : avgWeight
        return "\(suggested.clean)kg"
    }
    
    func startLiveActivity(workoutName: String) {
        // Write to shared UserDefaults for lock screen widget
        let shared = UserDefaults(suiteName: "group.com.OJStrachan.GymOS")
        shared?.set(true, forKey: "workoutActive")
        shared?.set(workoutName, forKey: "workoutName")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = GymOSActivityAttributes(startTime: Date())
        let state = GymOSActivityAttributes.ContentState(workoutName: workoutName, isActive: true)
        do {
            liveActivity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil), pushType: nil)
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }

    func stopLiveActivity() {
        let shared = UserDefaults(suiteName: "group.com.OJStrachan.GymOS")
        shared?.set(false, forKey: "workoutActive")
        shared?.removeObject(forKey: "workoutName")
        
        Task {
            for activity in Activity<GymOSActivityAttributes>.activities {
                await activity.end(.init(state: .init(workoutName: "", isActive: false), staleDate: nil), dismissalPolicy: .immediate)
            }
        }
    }
    
    // MARK: - Data Persistence
    private func saveCurrentWorkout() {
        if let workout = currentWorkout, let encoded = try? JSONEncoder().encode(workout) {
            UserDefaults.standard.set(encoded, forKey: "currentWorkout")
            print("✅ Saved current workout: \(workout.name), exercises: \(workout.exercises.count)")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentWorkout")
            print("🗑️ Cleared current workout")
        }
    }

    private func loadCurrentWorkout() {
        if let data = UserDefaults.standard.data(forKey: "currentWorkout"),
           let decoded = try? JSONDecoder().decode(Workout.self, from: data) {
            currentWorkout = decoded
            print("📦 Loaded current workout: \(decoded.name), exercises: \(decoded.exercises.count)")
        } else {
            print("❌ No saved workout found")
            stopLiveActivity()
        }
    }

    private func saveData() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: "workouts")
        }
        
        if let encoded = try? JSONEncoder().encode(availableExercises) {
            UserDefaults.standard.set(encoded, forKey: "exercises")
        }
        
        if let encoded = try? JSONEncoder().encode(workoutDays) {
            UserDefaults.standard.set(encoded, forKey: "workoutDays")
        }
        
        print("Data saved to UserDefaults")
    }
    
    private func loadData() {
        // Load workouts
        
        if let data = UserDefaults.standard.data(forKey: "workouts"),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
        
        // Load exercises
        if let data = UserDefaults.standard.data(forKey: "exercises"),
           let decoded = try? JSONDecoder().decode([Exercise].self, from: data) {
            availableExercises = decoded
        }
        
        // Load workout days
        if let data = UserDefaults.standard.data(forKey: "workoutDays"),
           let decoded = try? JSONDecoder().decode([WorkoutDay].self, from: data) {
            workoutDays = decoded
        }
        
        print("Data loaded from UserDefaults")
            }
            
            func previousVariations(for exercise: Exercise) -> [String] {
                let history = getExerciseHistory(for: exercise)
                let variations = history.compactMap { session -> String? in
                    session.variation.isEmpty ? nil : session.variation
                }
                // Return unique variations preserving order
                var seen = Set<String>()
                return variations.filter { seen.insert($0).inserted }
            }
        }
