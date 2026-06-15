import SwiftUI
import Foundation

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selectedTimeRange: TimeRange = .all
    
    enum TimeRange: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
    }
    
    var filteredWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return workoutManager.workouts.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return workoutManager.workouts.filter { $0.date >= monthAgo }
        case .all:
            return workoutManager.workouts
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Statistics
                if !filteredWorkouts.isEmpty {
                    statisticsView
                }
                
                // Workout list
                List(filteredWorkouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutRowView(workout: workout)
                    }
                }
            }
            .navigationTitle("Workout History")
        }
    }
    
    // MARK: - Statistics View
    private var statisticsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                HistoryStatCard(
                    title: "Workouts",
                    value: "\(filteredWorkouts.count)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                HistoryStatCard(
                    title: "Total Sets",
                    value: "\(totalSets)",
                    icon: "list.number",
                    color: .green
                )
                
                HistoryStatCard(
                    title: "Avg Duration",
                    value: averageDuration,
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            HStack(spacing: 20) {
                HistoryStatCard(
                    title: "Total Volume",
                    value: "\(Int(totalVolume))kg",
                    icon: "scalemass.fill",
                    color: .purple
                )
                
                HistoryStatCard(
                    title: "Most Trained",
                    value: mostTrainedMuscle,
                    icon: "figure.strengthtraining.traditional",
                    color: .red
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    private var totalSets: Int {
        filteredWorkouts.flatMap { $0.exercises }.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }
    
    private var averageDuration: String {
        let totalDuration = filteredWorkouts.reduce(0) { $0 + $1.duration }
        let avgMinutes = totalDuration / Double(max(filteredWorkouts.count, 1)) / 60
        return "\(Int(avgMinutes))min"
    }
    
    private var totalVolume: Double {
        filteredWorkouts.flatMap { $0.exercises }
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
            .reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    private var mostTrainedMuscle: String {
        let muscleCount = filteredWorkouts
            .flatMap { $0.exercises }
            .flatMap { $0.exercise.muscleGroups }
            .reduce(into: [String: Int]()) { counts, muscle in
                counts[muscle, default: 0] += 1
            }
        
        return muscleCount.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
}

// MARK: - History Stat Card
struct HistoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Workout Row View
struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            // Workout day indicator
            if let workoutDay = workout.workoutDay {
                Circle()
                    .fill(Color.color(named: workoutDay.color))
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                
                HStack {
                    Text("\(workout.exercises.count) exercises")
                    
                    if workout.duration > 0 {
                        Text("•")
                        Text("\(Int(workout.duration / 60))min")
                    }
                    
                    let completedSets = workout.exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
                    if completedSets > 0 {
                        Text("•")
                        Text("\(completedSets) sets")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(workout.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workout: Workout
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        List {
            // Workout info section
            Section("Workout Info") {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(workout.date, style: .date)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Duration")
                    Spacer()
                    Text(workout.duration > 0 ? "\(Int(workout.duration / 60))min" : "N/A")
                        .foregroundColor(.secondary)
                }
                
                if let workoutDay = workout.workoutDay {
                    HStack {
                        Text("Workout Day")
                        Spacer()
                        HStack {
                            Circle()
                                .fill(Color.color(named: workoutDay.color))
                                .frame(width: 12, height: 12)
                            Text(workoutDay.name)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                let totalVolume = workout.exercises.flatMap { $0.sets }
                    .filter { $0.isCompleted }
                    .reduce(0) { $0 + ($1.weight * Double($1.reps)) }
                
                if totalVolume > 0 {
                    HStack {
                        Text("Total Volume")
                        Spacer()
                        Text("\(Int(totalVolume))kg")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Exercises
            ForEach(workout.exercises) { exerciseSession in
                Section(exerciseSession.exercise.name) {
                    ForEach(Array(exerciseSession.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                            
                            Spacer()
                            
                            if set.isCompleted {
                                Text("\(Int(set.weight))kg × \(set.reps)")
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            } else {
                                Text("Not completed")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                    
                    if !exerciseSession.notes.isEmpty {
                        HStack {
                            Text("Notes:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(exerciseSession.notes)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Exercise History View
struct ExerciseHistoryView: View {
    let exercise: Exercise
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    var exerciseHistory: [ExerciseSession] {
        workoutManager.getExerciseHistory(for: exercise).reversed() // Most recent first
    }
    
    var body: some View {
        NavigationView {
            List {
                // Personal Records Section
                if let bestSet = workoutManager.getBestSet(for: exercise) {
                    Section("Personal Records") {
                        HStack {
                            Text("Best Set")
                            Spacer()
                            Text("\(Int(bestSet.weight))kg × \(bestSet.reps)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Max Weight")
                            Spacer()
                            let maxWeight = exerciseHistory.flatMap { $0.sets }
                                .filter { $0.isCompleted }
                                .max { $0.weight < $1.weight }?.weight ?? 0
                            Text("\(Int(maxWeight))kg")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Max Reps")
                            Spacer()
                            let maxReps = exerciseHistory.flatMap { $0.sets }
                                .filter { $0.isCompleted }
                                .max { $0.reps < $1.reps }?.reps ?? 0
                            Text("\(maxReps)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Best Volume")
                            Spacer()
                            Text("\(Int(bestSet.weight * Double(bestSet.reps)))kg")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // Progress Chart (Simple text-based for now)
                if exerciseHistory.count >= 3 {
                    Section("Progress Trend") {
                        let recentSessions = Array(exerciseHistory.prefix(5))
                        let weights = recentSessions.compactMap { session in
                            session.sets.filter { $0.isCompleted }.map { $0.weight }.max()
                        }
                        
                        if weights.count >= 2 {
                            let trend = weights.last! > weights.first! ? "↗️ Increasing" :
                                       weights.last! < weights.first! ? "↘️ Decreasing" : "➡️ Stable"
                            
                            HStack {
                                Text("Weight Trend")
                                Spacer()
                                Text(trend)
                                    .foregroundColor(weights.last! > weights.first! ? .green :
                                                   weights.last! < weights.first! ? .red : .secondary)
                            }
                        }
                    }
                }
                
                // Recent Sessions
                Section("Recent Sessions (\(exerciseHistory.count) total)") {
                    ForEach(Array(exerciseHistory.prefix(20).enumerated()), id: \.element.id) { sessionIndex, session in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session \(sessionIndex + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            let completedSets = session.sets.enumerated().filter { $0.element.isCompleted }
                            
                            if completedSets.isEmpty {
                                Text("No sets completed")
                                    .font(.caption)
                                    .italic()
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(completedSets, id: \.offset) { index, set in
                                    HStack {
                                        Text("Set \(index + 1):")
                                            .font(.caption)
                                        Spacer()
                                        Text("\(Int(set.weight))kg × \(set.reps)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text("(\(Int(set.weight * Double(set.reps)))kg)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            if !session.notes.isEmpty {
                                Text("Notes: \(session.notes)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("\(exercise.name) History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(WorkoutManager())
}
