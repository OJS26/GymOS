import SwiftUI
import Foundation

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingExerciseSelector = false
    @State private var showingWorkoutSettings = false
    @State private var showingDaySelector = false
    @State private var workoutTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var elapsedTime: TimeInterval = 0
    @Environment(\.colorScheme) var colorScheme
    @State private var distanceText = ""
    @State private var showingCreateExercise = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let currentWorkout = workoutManager.currentWorkout {
                    activeWorkoutView(currentWorkout)
                } else if let currentRun = workoutManager.currentRunningSession {
                    activeRunningView(currentRun)
                } else {
                    startWorkoutView
                }
            }
            .navigationTitle("GymOS")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if workoutManager.currentWorkout != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingWorkoutSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .foregroundColor(GymOSColors.primaryPurple)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingExerciseSelector) {
                ExerciseSelectorView()
            }
            .sheet(isPresented: $showingDaySelector) {
                WorkoutDaySelectorView { workoutDay in
                    workoutManager.startWorkout(name: workoutDay?.name ?? "New Workout", workoutDay: workoutDay)
                    elapsedTime = 0
                }
            }
            .sheet(isPresented: $showingWorkoutSettings) {
                WorkoutSettingsView()
            }
            .onReceive(workoutTimer) { _ in
                if workoutManager.currentWorkout?.isActive == true || workoutManager.currentRunningSession?.isActive == true {
                    elapsedTime += 1
                }
            }
        } // ADD this closing brace - it closes the NavigationView
    }// ADD this closing brace - it closes the body property
    
    private func activeRunningView(_ currentRun: RunningSession) -> some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: [
                    GymOSColors.primaryPurple.opacity(0.3),
                    GymOSColors.lightPurple.opacity(0.2),
                    GymOSColors.infoBlue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Pulsing circles animation
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(GymOSColors.primaryPurple.opacity(0.2), lineWidth: 2)
                    .frame(width: CGFloat(100 + index * 50))
                    .scaleEffect(1 + sin(elapsedTime + Double(index)) * 0.1)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: elapsedTime)
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Running status with icon
                HStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.title)
                        .foregroundColor(GymOSColors.primaryPurple)
                        .scaleEffect(1 + sin(elapsedTime * 2) * 0.1)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: elapsedTime)
                    
                    Text("RUNNING")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(GymOSColors.primaryText)
                }
                
                // Giant timer with glow effect
                VStack(spacing: 8) {
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 84, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(GymOSColors.primaryPurple)
                        .shadow(color: GymOSColors.primaryPurple.opacity(0.3), radius: 10, x: 0, y: 0)
                    
                    Text("elapsed time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(GymOSColors.secondaryText)
                }
                
                // Stats cards
                // Replace the existing HStack with stats cards:
                HStack(spacing: 20) {
                    StatCardView(
                        title: "Time",
                        value: "\(Int(elapsedTime / 60))m",
                        icon: "clock.fill",
                        color: GymOSColors.infoBlue
                    )
                    
                    StatCardView(
                        title: "Distance",
                        value: currentRun.distance > 0 ? String(format: "%.1f km", currentRun.distance) : "0.0 km",
                        icon: "location.fill",
                        color: GymOSColors.successGreen
                    )
                    
                    if currentRun.distance > 0 {
                        StatCardView(
                            title: "Pace",
                            value: String(format: "%.1f min/km", elapsedTime / 60 / currentRun.distance),
                            icon: "speedometer",
                            color: GymOSColors.warningOrange
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // Progress comparison
                if let lastRun = workoutManager.runningSessions.first {
                    comparisonView(lastRun: lastRun)
                }
                
                Spacer()
                
                // ADD this before the "End Run" button:
                VStack(spacing: 12) {
                    Text("Enter distance when finished")
                        .font(.subheadline)
                        .foregroundColor(GymOSColors.secondaryText)
                    
                    HStack {
                        TextField("0.0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("km")
                            .foregroundColor(GymOSColors.secondaryText)
                    }
                }
                
                // Animated end button
                Button(action: {
                    workoutManager.endRunningSession(distance: Double(distanceText) ?? 0)
                    elapsedTime = 0
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                        Text("End Run")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [GymOSColors.dangerRed, GymOSColors.warningOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: GymOSColors.dangerRed.opacity(0.4), radius: 15, x: 0, y: 8)
                    )
                }
                .scaleEffect(1 + sin(elapsedTime) * 0.02)
                .animation(.easeInOut(duration: 2).repeatForever(), value: elapsedTime)
                .padding(.bottom, 50)
            }
        }
    }
    // MARK: - Active Workout View
    private func activeWorkoutView(_ currentWorkout: Workout) -> some View {
        VStack(spacing: 20) {
            // Workout day indicator
            if let workoutDay = currentWorkout.workoutDay {
                HStack {
                    Circle()
                        .fill(Color.color(named: workoutDay.color))
                        .frame(width: 12, height: 12)
                    Text(workoutDay.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(GymOSColors.primaryText)
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            PurpleButton("Start Run", variant: .filled, icon: "figure.run") {
                workoutManager.startRunningSession()
                elapsedTime = 0
            }
            // Rest Timer (if active)
            if workoutManager.isRestTimerActive {
                RestTimerView()
                    .padding(.horizontal, 20)
                    .restTimer(timeRemaining: workoutManager.restTimeElapsed)
            }
            
            // Workout Timer
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.title2)
                Text(formatTime(elapsedTime))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .workoutTimer()
            
            // Exercise list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(currentWorkout.exercises.enumerated()), id: \.element.id) { index, exerciseSession in
                        ExerciseSessionCard(
                            exerciseSession: exerciseSession,
                            exerciseIndex: index
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for floating buttons
            }
            
            Spacer()
            
            // Floating action buttons
            VStack(spacing: 12) {
                PurpleButton("Add Exercise", variant: .bordered, icon: "plus") {
                    showingExerciseSelector = true
                }
                
                PurpleButton("End Workout", variant: .filled, icon: "stop.fill") {
                    workoutManager.endWorkout()
                    elapsedTime = 0
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    // MARK: - Start Workout View
    private var startWorkoutView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Hero section
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(GymOSColors.purpleGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: GymOSColors.primaryPurple.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("Ready to workout?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(GymOSColors.primaryText)
                    
                    Text("Choose how you want to start")
                        .font(.title3)
                        .foregroundColor(GymOSColors.secondaryText)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                PurpleButton("Start with Template", variant: .filled, icon: "calendar") {
                    showingDaySelector = true
                }
                
                PurpleButton("Quick Start", variant: .bordered, icon: "bolt.fill") {
                    workoutManager.startWorkout()
                    elapsedTime = 0
                }
                
                PurpleButton("Start Run", variant: .filled, icon: "figure.run") {
                    workoutManager.startRunningSession()
                    elapsedTime = 0
                }
                // Quick template buttons
                if !workoutManager.workoutDays.isEmpty {
                    VStack(spacing: 8) {
                        Text("Quick Templates")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(GymOSColors.secondaryText)
                        
                        HStack(spacing: 12) {
                            ForEach(workoutManager.workoutDays.prefix(3)) { day in
                                Button {
                                    workoutManager.startWorkout(name: day.name, workoutDay: day)
                                    elapsedTime = 0
                                } label: {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.color(named: day.color))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text("\(day.exercises.count)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text(day.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(GymOSColors.primaryText)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
            
    // MARK: - Helper Functions
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Exercise Session Card
struct ExerciseSessionCard: View {
    let exerciseSession: ExerciseSession
    let exerciseIndex: Int
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showingHistory = false
    @State private var exerciseNotes = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseSession.exercise.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(GymOSColors.primaryText)
                    
                    Text(exerciseSession.exercise.muscleGroups.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(GymOSColors.secondaryText)
                }
                
                Spacer()
                
                // ADD this after the exercise header HStack:
                // Exercise notes
                HStack {
                    TextField("Notes (machine position, technique, etc.)", text: $exerciseNotes)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(GymOSColors.elevatedBackground(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(GymOSColors.tertiaryText.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .padding(.bottom, 8)
                
                // History button
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundColor(GymOSColors.primaryPurple)
                }
                
                // Previous best
                if let bestSet = workoutManager.getBestSet(for: exerciseSession.exercise) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BEST")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(GymOSColors.successGreen)
                        Text("\(Int(bestSet.weight))kg × \(bestSet.reps)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(GymOSColors.primaryText)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(GymOSColors.successGreen.opacity(0.1))
                    )
                }
            }
            
            // Sets
            VStack(spacing: 12) {
                ForEach(Array(exerciseSession.sets.enumerated()), id: \.element.id) { setIndex, set in
                    SetRowView(
                        set: set,
                        setNumber: setIndex + 1,
                        exerciseIndex: exerciseIndex,
                        setIndex: setIndex
                    )
                }
            }
            
            // Add set button
            Button {
                workoutManager.addSet(to: exerciseIndex)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Set")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(GymOSColors.primaryPurple)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(GymOSColors.primaryPurple.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(GymOSColors.primaryPurple.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .cardStyle(padding: 20, cornerRadius: 20)
        .sheet(isPresented: $showingHistory) {
            ExerciseHistoryView(exercise: exerciseSession.exercise)
        }
    }
}

// MARK: - Set Row View
struct SetRowView: View {
    let set: WorkoutSet
    let setNumber: Int
    let exerciseIndex: Int
    let setIndex: Int
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.colorScheme) var colorScheme
    @State private var repsText: String = ""
    @State private var weightText: String = ""
    
    // Get the exercise for this set row
    private var exercise: Exercise? {
        guard let currentWorkout = workoutManager.currentWorkout,
              exerciseIndex < currentWorkout.exercises.count else { return nil }
        return currentWorkout.exercises[exerciseIndex].exercise
    }
    
    // Get the last completed set for this exercise and set number
    private var lastCompletedSet: WorkoutSet? {
        guard let exercise = exercise else { return nil }
        let history = workoutManager.getExerciseHistory(for: exercise)
        
        // Look through recent sessions for a completed set at this set number
        for session in history.reversed() {
            if setNumber <= session.sets.count {
                let historicalSet = session.sets[setNumber - 1]
                if historicalSet.isCompleted {
                    return historicalSet
                }
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Set number badge
                Text("\(setNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(set.isCompleted ? GymOSColors.successGreen : GymOSColors.primaryPurple)
                    )
                
                // Weight input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(GymOSColors.tertiaryText)
                    
                    HStack {
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(GymOSColors.elevatedBackground(for: colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                set.isCompleted ? GymOSColors.successGreen : GymOSColors.primaryPurple.opacity(0.3),
                                                lineWidth: set.isCompleted ? 2 : 1
                                            )
                                    )
                            )
                            .onChange(of: weightText) { _, newValue in
                                if let weight = Double(newValue) {
                                    workoutManager.updateSet(
                                        exerciseIndex: exerciseIndex,
                                        setIndex: setIndex,
                                        reps: set.reps,
                                        weight: weight
                                    )
                                }
                            }
                        
                        Text("kg")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(GymOSColors.tertiaryText)
                    }
                }
                .frame(width: 80)
                
                // Reps input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(GymOSColors.tertiaryText)
                    
                    TextField("0", text: $repsText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(GymOSColors.elevatedBackground(for: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            set.isCompleted ? GymOSColors.successGreen : GymOSColors.primaryPurple.opacity(0.3),
                                            lineWidth: set.isCompleted ? 2 : 1
                                        )
                                )
                        )
                        .onChange(of: repsText) { _, newValue in
                            if let reps = Int(newValue) {
                                workoutManager.updateSet(
                                    exerciseIndex: exerciseIndex,
                                    setIndex: setIndex,
                                    reps: reps,
                                    weight: set.weight
                                )
                            }
                        }
                }
                .frame(width: 60)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    // Complete button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            workoutManager.completeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                        }
                    }) {
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(set.isCompleted ? GymOSColors.successGreen : GymOSColors.tertiaryText)
                            .scaleEffect(set.isCompleted ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: set.isCompleted)
                    }
                    
                    // Manual rest timer button
                    if set.isCompleted && workoutManager.restTimerSettings.isEnabled && !workoutManager.isRestTimerActive {
                        Button(action: {
                            if let exerciseName = exercise?.name {
                                workoutManager.startRestTimer(for: exerciseName, setNumber: setNumber)
                            }
                        }) {
                            Image(systemName: "timer")
                                .font(.title3)
                                .foregroundColor(GymOSColors.warningOrange)
                        }
                    }
                }
            }
            
            // Show previous set data if available
            if let lastSet = lastCompletedSet, !set.isCompleted {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundColor(GymOSColors.infoBlue)
                        
                        Text("Last: \(Int(lastSet.weight))kg × \(lastSet.reps)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(GymOSColors.infoBlue)
                    }
                    .padding(.leading, 36) // Align with inputs
                    
                    Spacer()
                    
                    // Quick copy button
                    Button("Copy") {
                        weightText = "\(Int(lastSet.weight))"
                        repsText = "\(lastSet.reps)"
                        workoutManager.updateSet(
                            exerciseIndex: exerciseIndex,
                            setIndex: setIndex,
                            reps: lastSet.reps,
                            weight: lastSet.weight
                        )
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(GymOSColors.infoBlue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(GymOSColors.infoBlue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(GymOSColors.infoBlue)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    set.isCompleted ?
                        GymOSColors.successGreen.opacity(0.05) :
                        GymOSColors.elevatedBackground(for: colorScheme)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            set.isCompleted ?
                                GymOSColors.successGreen.opacity(0.2) :
                                Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            repsText = set.reps > 0 ? "\(set.reps)" : ""
            weightText = set.weight > 0 ? "\(Int(set.weight))" : ""
        }
    }
}

// MARK: - Exercise Selector View
struct ExerciseSelectorView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedCategory: Exercise.ExerciseCategory?
    @State private var showingCreateExercise = false
    
    var filteredExercises: [Exercise] {
        var exercises = workoutManager.availableExercises
        
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return exercises.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(GymOSColors.tertiaryText)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Search exercises...", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(GymOSColors.primaryText)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(GymOSColors.tertiaryText)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GymOSColors.elevatedBackground(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(GymOSColors.primaryPurple.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                // ADD this after the search bar section:
                Button(action: {
                    showingCreateExercise = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(GymOSColors.primaryPurple)
                            .font(.title2)
                        
                        Text("Create New Exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(GymOSColors.primaryPurple)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(GymOSColors.tertiaryText)
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(GymOSColors.primaryPurple.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(GymOSColors.primaryPurple.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button("All") {
                            selectedCategory = nil
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedCategory == nil ? .white : GymOSColors.primaryPurple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == nil ? GymOSColors.primaryPurple : GymOSColors.primaryPurple.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(GymOSColors.primaryPurple.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedCategory == category ? .white : GymOSColors.primaryPurple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedCategory == category ? GymOSColors.primaryPurple : GymOSColors.primaryPurple.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(GymOSColors.primaryPurple.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Exercise list
                List(filteredExercises) { exercise in
                    Button(action: {
                        workoutManager.addExercise(exercise)
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(categoryColor(for: exercise.category))
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(GymOSColors.primaryText)
                                
                                Text(exercise.muscleGroups.joined(separator: " • "))
                                    .font(.subheadline)
                                    .foregroundColor(GymOSColors.secondaryText)
                                
                                Text(exercise.category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(categoryColor(for: exercise.category))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(categoryColor(for: exercise.category).opacity(0.1))
                                    )
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(GymOSColors.primaryPurple)
                                .font(.title2)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(GymOSColors.primaryPurple)
                }
            }
                .sheet(isPresented: $showingCreateExercise) {  // ADD this entire section
                QuickCreateExerciseView { exercise in
                workoutManager.addExercise(exercise)
                dismiss()
                }
            }
        }
    }
    private func categoryColor(for category: Exercise.ExerciseCategory) -> Color {
        switch category {
        case .chest: return GymOSColors.dangerRed
        case .back: return GymOSColors.successGreen
        case .shoulders: return GymOSColors.warningOrange
        case .arms: return GymOSColors.primaryPurple
        case .legs: return GymOSColors.infoBlue
        case .core: return Color.pink
        case .cardio: return Color.cyan
        }
    }
}

// MARK: - Workout Day Selector View
struct WorkoutDaySelectorView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let onStartWorkout: (WorkoutDay?) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose Workout Day")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(GymOSColors.primaryText)
                    
                    Text("Select a workout template to get started")
                        .font(.subheadline)
                        .foregroundColor(GymOSColors.secondaryText)
                }
                .padding(.top, 20)
                
                if workoutManager.workoutDays.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(GymOSColors.tertiaryText)
                        
                        Text("No workout days yet")
                            .font(.headline)
                            .foregroundColor(GymOSColors.primaryText)
                        
                        Text("Create workout day templates in the Library tab to get started faster.")
                            .font(.subheadline)
                            .foregroundColor(GymOSColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // Workout days grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(workoutManager.workoutDays) { day in
                                WorkoutDayCard(day: day) {
                                    onStartWorkout(day)
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                // Empty workout option
                PurpleButton("Start Empty Workout", variant: .bordered, icon: "plus") {
                    onStartWorkout(nil)
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(GymOSColors.primaryPurple)
                }
            }
        }
    }
}

// MARK: - Workout Day Card
struct WorkoutDayCard: View {
    let day: WorkoutDay
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Color circle with exercise count
                ZStack {
                    Circle()
                        .fill(Color.color(named: day.color))
                        .frame(width: 60, height: 60)
                    
                    Text("\(day.exercises.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Day info
                VStack(spacing: 4) {
                    Text(day.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(GymOSColors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("\(day.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(GymOSColors.secondaryText)
                }
                
                // Sample exercises
                if !day.exercises.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(day.exercises.prefix(3), id: \.id) { exercise in
                            Text(exercise.name)
                                .font(.caption2)
                                .foregroundColor(GymOSColors.tertiaryText)
                                .lineLimit(1)
                        }
                        
                        if day.exercises.count > 3 {
                            Text("+ \(day.exercises.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(GymOSColors.tertiaryText)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(GymOSColors.cardBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.color(named: day.color).opacity(0.3), lineWidth: 1)
                    )
                    .shadow(
                        color: colorScheme == .dark ?
                            Color.black.opacity(0.3) : Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Running Helper Views
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(GymOSColors.primaryText)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(GymOSColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(GymOSColors.cardBackground(for: colorScheme))
                .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

extension WorkoutView {
    private func formatPace(_ time: TimeInterval) -> String {
        let avgPace = time / 60 // Simple calculation for treadmill
        let minutes = Int(avgPace)
        let seconds = Int((avgPace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func comparisonView(lastRun: RunningSession) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.right.circle.fill")
                .foregroundColor(elapsedTime > lastRun.duration ? GymOSColors.successGreen : GymOSColors.warningOrange)
            
            Text("Last run: \(Int(lastRun.duration / 60))m")
                .font(.subheadline)
                .foregroundColor(GymOSColors.tertiaryText)
            
            Text(elapsedTime > lastRun.duration ? "Beating your record!" : "Keep going!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(elapsedTime > lastRun.duration ? GymOSColors.successGreen : GymOSColors.primaryPurple)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(GymOSColors.elevatedBackground(for: colorScheme))
        )
    }
}

// MARK: - Quick Create Exercise View
struct QuickCreateExerciseView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var exerciseName = ""
    @State private var selectedCategory: Exercise.ExerciseCategory = .chest
    let onExerciseCreated: (Exercise) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Name")
                        .font(.headline)
                        .foregroundColor(GymOSColors.primaryText)
                    
                    TextField("Enter exercise name", text: $exerciseName)
                        .font(.system(size: 16))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GymOSColors.elevatedBackground(for: colorScheme))
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(GymOSColors.primaryText)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Quick Create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(GymOSColors.primaryPurple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create & Add") {
                        let exercise = Exercise(
                            name: exerciseName,
                            category: selectedCategory,
                            muscleGroups: ["Unknown"], // Can be edited later
                            isCustom: true
                        )
                        workoutManager.availableExercises.append(exercise)
                        onExerciseCreated(exercise)
                    }
                    .disabled(exerciseName.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(GymOSColors.primaryPurple)
                }
            }
        }
    }
}
#Preview {
    WorkoutView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.dark)
}
