import SwiftUI

// MARK: - Workout Day Detail View
struct WorkoutDayDetailView: View {
    let day: WorkoutDay
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingEditDay = false
    
    var body: some View {
        List {
            Section("Day Info") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(day.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Color")
                    Spacer()
                    Circle()
                        .fill(Color.color(named: day.color))
                        .frame(width: 20, height: 20)
                }
                
                HStack {
                    Text("Exercises")
                    Spacer()
                    Text("\(day.exercises.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Exercises") {
                ForEach(day.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                        
                        Text(exercise.muscleGroups.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(exercise.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditDay = true
                }
            }
        }
        .sheet(isPresented: $showingEditDay) {
            EditWorkoutDayView(day: day)
        }
    }
}

// MARK: - Edit Workout Day View
struct EditWorkoutDayView: View {
    let day: WorkoutDay
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @State private var dayName = ""
    @State private var selectedExercises: Set<UUID> = []
    @State private var selectedColor = "blue"
    @State private var searchText = ""
    
    let colors = ["blue", "green", "orange", "purple", "red", "pink", "yellow", "cyan"]
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return workoutManager.availableExercises
        } else {
            return workoutManager.availableExercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Day Info") {
                    TextField("Day Name", text: $dayName)
                    
                    VStack(alignment: .leading) {
                        Text("Color")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(Color.color(named: color))
                                        .frame(width: 35, height: 35)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("Select Exercises") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    ForEach(filteredExercises) { exercise in
                        HStack {
                            Button(action: {
                                if selectedExercises.contains(exercise.id) {
                                    selectedExercises.remove(exercise.id)
                                } else {
                                    selectedExercises.insert(exercise.id)
                                }
                            }) {
                                Image(systemName: selectedExercises.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedExercises.contains(exercise.id) ? .blue : .gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.headline)
                                
                                Text(exercise.muscleGroups.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(exercise.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(3)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Edit Workout Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(GymOSColors.primaryPurple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let exercises = workoutManager.availableExercises.filter { selectedExercises.contains($0.id) }
                        workoutManager.updateWorkoutDay(day, name: dayName, exercises: exercises, color: selectedColor)
                        dismiss()
                    }
                    .disabled(dayName.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(GymOSColors.primaryPurple)
                }
            }
        }
        .onAppear {
            dayName = day.name
            selectedColor = day.color
            selectedExercises = Set(day.exercises.map { $0.id })
        }
    }
}

#Preview {
    WorkoutDayDetailView(day: WorkoutDay(name: "Upper Body", exercises: [], color: "blue"))
        .environmentObject(WorkoutManager())
}
