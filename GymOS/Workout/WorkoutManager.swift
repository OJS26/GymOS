import SwiftUI
import Foundation

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
    @Published var runningSessions: [RunningSession] = []
    @Published var currentRunningSession: RunningSession?
    
    // Rest Timer Properties
    @Published var restTimerSettings = RestTimerSettings()
    @Published var isRestTimerActive = false
    @Published var restTimeElapsed: TimeInterval = 0
    @Published var restTimerExercise: String = ""
    @Published var restTimerSetNumber: Int = 0
    
    private var restTimer: Timer?
    
    init() {
        loadSampleExercises()
        loadSampleWorkoutDays()
        loadData()
        loadRunningData() 
        loadRestTimerSettings()
        loadCurrentWorkout()
    }
    
    // MARK: - Rest Timer Functions
    func startRestTimer(for exercise: String, setNumber: Int, duration: TimeInterval? = nil) {
        guard restTimerSettings.isEnabled else { return }
        
        restTimeElapsed = 0
        restTimerExercise = exercise
        restTimerSetNumber = setNumber
        isRestTimerActive = true
        
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.restTimeElapsed += 1
            
            // Optional: Add haptic feedback at common rest intervals
            if self.restTimeElapsed == 60 || self.restTimeElapsed == 90 || self.restTimeElapsed == 120 {
                self.sendRestMilestoneNotification()
            }
        }
    }
    
    func stopRestTimer() -> TimeInterval {
        let finalRestTime = restTimeElapsed
        
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerActive = false
        restTimeElapsed = 0
        restTimerExercise = ""
        restTimerSetNumber = 0
        
        return finalRestTime // Return the actual rest time for analytics
    }
    
    func pauseRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
    }
    
    func resumeRestTimer() {
        guard isRestTimerActive else { return }
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.restTimeElapsed += 1
            
            if self.restTimeElapsed == 60 || self.restTimeElapsed == 90 || self.restTimeElapsed == 120 {
                self.sendRestMilestoneNotification()
            }
        }
    }
    
    private func sendRestMilestoneNotification() {
        // Gentle haptic feedback at rest milestones
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func updateRestTimerSettings(_ settings: RestTimerSettings) {
        restTimerSettings = settings
        saveRestTimerSettings()
    }
    
    // MARK: - Sample Data Loading
    private func loadSampleExercises() {
        availableExercises = [
            Exercise(name: "Bench Press", category: .chest, muscleGroups: ["Chest", "Triceps", "Shoulders"]),
            Exercise(name: "Squat", category: .legs, muscleGroups: ["Quadriceps", "Glutes", "Hamstrings"]),
            Exercise(name: "Deadlift", category: .back, muscleGroups: ["Back", "Hamstrings", "Glutes"]),
            Exercise(name: "Pull-ups", category: .back, muscleGroups: ["Lats", "Biceps", "Rhomboids"]),
            Exercise(name: "Overhead Press", category: .shoulders, muscleGroups: ["Shoulders", "Triceps", "Core"]),
            Exercise(name: "Barbell Row", category: .back, muscleGroups: ["Lats", "Rhomboids", "Biceps"]),
            Exercise(name: "Dips", category: .chest, muscleGroups: ["Chest", "Triceps", "Shoulders"]),
            Exercise(name: "Lunges", category: .legs, muscleGroups: ["Quadriceps", "Glutes", "Hamstrings"]),
            Exercise(name: "Incline Bench Press", category: .chest, muscleGroups: ["Upper Chest", "Triceps", "Shoulders"]),
            Exercise(name: "Romanian Deadlift", category: .legs, muscleGroups: ["Hamstrings", "Glutes", "Lower Back"]),
            Exercise(name: "Lat Pulldown", category: .back, muscleGroups: ["Lats", "Biceps", "Rhomboids"]),
            Exercise(name: "Leg Press", category: .legs, muscleGroups: ["Quadriceps", "Glutes"]),
            Exercise(name: "Tricep Dips", category: .arms, muscleGroups: ["Triceps", "Chest"]),
            Exercise(name: "Bicep Curls", category: .arms, muscleGroups: ["Biceps"]),
            Exercise(name: "Leg Curls", category: .legs, muscleGroups: ["Hamstrings"]),
            Exercise(name: "Calf Raises", category: .legs, muscleGroups: ["Calves"])
        ]
    }
    
    private func loadSampleWorkoutDays() {
        let upperExercises = availableExercises.filter {
            $0.category == .chest || $0.category == .back || $0.category == .shoulders || $0.category == .arms
        }
        let lowerExercises = availableExercises.filter {
            $0.category == .legs
        }
        
        workoutDays = [
            WorkoutDay(name: "Upper Body", exercises: Array(upperExercises.prefix(6)), color: "blue"),
            WorkoutDay(name: "Lower Body", exercises: Array(lowerExercises.prefix(6)), color: "green"),
            WorkoutDay(name: "Push", exercises: [
                availableExercises.first { $0.name == "Bench Press" }!,
                availableExercises.first { $0.name == "Overhead Press" }!,
                availableExercises.first { $0.name == "Dips" }!,
                availableExercises.first { $0.name == "Tricep Dips" }!
            ], color: "orange"),
            WorkoutDay(name: "Pull", exercises: [
                availableExercises.first { $0.name == "Deadlift" }!,
                availableExercises.first { $0.name == "Pull-ups" }!,
                availableExercises.first { $0.name == "Barbell Row" }!,
                availableExercises.first { $0.name == "Bicep Curls" }!
            ], color: "purple")
        ]
    }
    
    // MARK: - Exercise Management
    func addCustomExercise(name: String, category: Exercise.ExerciseCategory, muscleGroups: [String]) {
        let exercise = Exercise(name: name, category: category, muscleGroups: muscleGroups, isCustom: true)
        availableExercises.append(exercise)
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
    }
    
    func endWorkout() {
        guard var workout = currentWorkout else { return }
        workout.isActive = false
        workouts.insert(workout, at: 0)
        currentWorkout = nil
        _ = stopRestTimer()
        // Could save this to the workout or log it // Stop any active rest timer
        saveData()
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
        
        // Start rest timer if set was just completed (not uncompleted)
        if currentWorkout?.exercises[exerciseIndex].sets[setIndex].isCompleted == true && restTimerSettings.autoStart {
            let exerciseName = currentWorkout?.exercises[exerciseIndex].exercise.name ?? ""
            startRestTimer(for: exerciseName, setNumber: setIndex + 1)
        }
    }
    
    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard currentWorkout != nil else { return }
        currentWorkout?.exercises[exerciseIndex].sets.remove(at: setIndex)
    }
    
    // MARK: - Data Analysis
    func getExerciseHistory(for exercise: Exercise) -> [ExerciseSession] {
        return workouts.flatMap { workout in
            workout.exercises.filter { $0.exercise.name == exercise.name }
        }.sorted { $0.id.uuidString < $1.id.uuidString }
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
    
    func weightSuggestion(for exercise: Exercise) -> String? {
        let history = getExerciseHistory(for: exercise)
        guard let lastSession = history.last else { return nil }
        
        let completedSets = lastSession.sets.filter { $0.isCompleted }
        guard !completedSets.isEmpty else { return nil }
        
        let avgWeight = completedSets.map { $0.weight }.reduce(0, +) / Double(completedSets.count)
        let avgReps = completedSets.map { $0.reps }.reduce(0, +) / completedSets.count
        
        // If they got 10+ reps on average, suggest a weight increase
        let suggested = avgReps >= 10 ? avgWeight + 2.5 : avgWeight
        return "\(suggested.clean)kg"
    }
    
    func startRunningSession() {
        currentRunningSession = RunningSession(isActive: true)
    }

    func endRunningSession(distance: Double, notes: String = "") {
        guard var session = currentRunningSession else { return }
        session.isActive = false
        session.distance = distance
        session.notes = notes
        runningSessions.insert(session, at: 0)
        currentRunningSession = nil
        saveRunningData()
    }

    private func saveRunningData() {
        if let encoded = try? JSONEncoder().encode(runningSessions) {
            UserDefaults.standard.set(encoded, forKey: "runningSessions")
        }
    }

    private func loadRunningData() {
        if let data = UserDefaults.standard.data(forKey: "runningSessions"),
           let decoded = try? JSONDecoder().decode([RunningSession].self, from: data) {
            runningSessions = decoded
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
    
    private func saveRestTimerSettings() {
        if let encoded = try? JSONEncoder().encode(restTimerSettings) {
            UserDefaults.standard.set(encoded, forKey: "restTimerSettings")
        }
    }
    
    private func loadRestTimerSettings() {
        if let data = UserDefaults.standard.data(forKey: "restTimerSettings"),
           let decoded = try? JSONDecoder().decode(RestTimerSettings.self, from: data) {
            restTimerSettings = decoded
        } else {
            restTimerSettings = RestTimerSettings()
        }
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
}
