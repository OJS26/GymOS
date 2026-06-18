import SwiftUI

struct YouView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingSettings = false
    @State private var showingExerciseLibrary = false
    @State private var showingRoutines = false
    @State private var showingHistory = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("You")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundColor(.white)
                                Text("\(workoutManager.workouts.count) workouts logged")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.white.opacity(0.35))
                            }

                            Spacer()

                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                        // Stats row
                        HStack(spacing: 1) {
                            StatBlock(value: "\(workoutManager.currentStreak)", label: "Streak", unit: "days")
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 1)
                            StatBlock(value: "\(totalVolume)", label: "Total vol.", unit: "kg")
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.04))
                        .overlay(Rectangle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                        .padding(.bottom, 32)

                        // Library section
                        SectionHeader(title: "Library")

                        VStack(spacing: 0) {
                            YouRow(icon: "dumbbell", title: "Exercises", subtitle: "\(workoutManager.availableExercises.count) exercises") {
                                showingExerciseLibrary = true
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 24)
                            YouRow(icon: "list.bullet", title: "Routines", subtitle: "\(workoutManager.workoutDays.count) routines") {
                                showingRoutines = true
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 24)
                            YouRow(icon: "clock", title: "History", subtitle: "\(workoutManager.workouts.count) workouts") {
                                showingHistory = true
                            }
                        }
                        .background(Color.white.opacity(0.04))
                        .overlay(Rectangle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                        .padding(.bottom, 32)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet()
                    .environmentObject(workoutManager)
            }
            .sheet(isPresented: $showingExerciseLibrary) {
                ExerciseLibraryView()
                    .environmentObject(workoutManager)
            }
            .sheet(isPresented: $showingRoutines) {
                RoutinesView()
                    .environmentObject(workoutManager)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
                    .environmentObject(workoutManager)
            }
        }
    }

    private var totalVolume: String {
        let vol = workoutManager.workouts.flatMap { $0.exercises }
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
            .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        if vol >= 1000 { return String(format: "%.1ft", vol / 1000) }
        return "\(Int(vol))"
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color.white.opacity(0.3))
            .tracking(2)
            .textCase(.uppercase)
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
    }
}

// MARK: - You Row
struct YouRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(GymOSColors.primaryPurple)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.35))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.2))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Settings Sheet
struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
                List {
                    Section {
                        HStack {
                            Text("Units")
                                .foregroundColor(.white)
                            Spacer()
                            Text("kg")
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                    } header: {
                        Text("Preferences")
                            .foregroundColor(Color.white.opacity(0.3))
                    }

                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0")
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                    } header: {
                        Text("About")
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GymOSColors.primaryPurple)
                }
            }
        }
    }
}

// MARK: - Exercise Library
struct ExerciseLibraryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showingAddExercise = false
    @State private var selectedCategory: Exercise.ExerciseCategory? = nil
    @State private var editingExercise: Exercise? = nil

    var filtered: [Exercise] {
        workoutManager.availableExercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || exercise.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { cat in
                                CategoryChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                    selectedCategory = selectedCategory == cat ? nil : cat
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }

                    List {
                        ForEach(filtered) { exercise in
                            Button {
                                editingExercise = exercise
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    HStack(spacing: 6) {
                                        Text(exercise.category.rawValue)
                                            .font(.system(size: 11))
                                            .foregroundColor(GymOSColors.primaryPurple)
                                        Text("·")
                                            .foregroundColor(Color.white.opacity(0.2))
                                        Text(exercise.muscleGroups.joined(separator: ", "))
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.white.opacity(0.35))
                                    }
                                    if !exercise.note.isEmpty {
                                        Text(exercise.note)
                                            .font(.system(size: 11))
                                            .italic()
                                            .foregroundColor(GymOSColors.primaryPurple.opacity(0.7))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.white.opacity(0.04))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    workoutManager.deleteExercise(exercise)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search exercises")
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GymOSColors.primaryPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(GymOSColors.primaryPurple)
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                            AddExerciseSheet()
                                .environmentObject(workoutManager)
                                .presentationDetents([.height(480)])
                                .presentationDragIndicator(.visible)
                        }
                        .sheet(item: $editingExercise) { exercise in
                            EditExerciseNoteSheet(exercise: exercise)
                                .environmentObject(workoutManager)
                                .presentationDetents([.height(320)])
                                .presentationDragIndicator(.visible)
                        }
                    }
                }
            }
            
// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.4))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? GymOSColors.primaryPurple : Color.white.opacity(0.06))
                .cornerRadius(20)
        }
    }
}

// MARK: - Add Exercise Sheet
struct AddExerciseSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedCategory: Exercise.ExerciseCategory = .chest
    @State private var muscleGroupsText = ""

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("New Exercise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("NAME")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(1.5)
                    TextField("e.g. Cable Fly", text: $name)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(1.5)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { cat in
                                CategoryChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                    selectedCategory = cat
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("MUSCLE GROUPS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(1.5)
                    TextField("e.g. Chest, Triceps", text: $muscleGroupsText)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                }

                Button {
                    let muscles = muscleGroupsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    workoutManager.addCustomExercise(name: name, category: selectedCategory, muscleGroups: muscles)
                    dismiss()
                } label: {
                    Text("Add exercise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(GymOSColors.primaryPurple)
                        .cornerRadius(14)
                }
                .disabled(name.isEmpty)
            }
            .padding(24)
        }
    }
}

            // MARK: - Edit Exercise Note Sheet
struct EditExerciseNoteSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    let exercise: Exercise
    @State private var noteText: String = ""

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text(exercise.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(1.5)
                    Text("Shows every time you do this exercise — good for form cues or reminders.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.3))

                    TextEditor(text: $noteText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                }

                Button {
                    workoutManager.updateExerciseNote(exercise, note: noteText)
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(GymOSColors.primaryPurple)
                        .cornerRadius(14)
                }
            }
            .padding(24)
        }
        .onAppear {
                    noteText = exercise.note
                }
            }
        }

        // MARK: - Routines View
struct RoutinesView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAddRoutine = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

                List {
                    ForEach(workoutManager.workoutDays) { day in
                        NavigationLink(destination: EditRoutineView(day: day).environmentObject(workoutManager)) {
                            HStack(spacing: 14) {
                                Rectangle()
                                    .fill(Color.color(named: day.color))
                                    .frame(width: 3, height: 36)
                                    .cornerRadius(2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(day.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("\(day.exercises.count) exercises")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.35))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                workoutManager.deleteWorkoutDay(day)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GymOSColors.primaryPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRoutine = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(GymOSColors.primaryPurple)
                    }
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineView()
                    .environmentObject(workoutManager)
            }
        }
    }
}

// MARK: - Add Routine View
struct AddRoutineView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedColor = "blue"
    @State private var selectedExercises: Set<UUID> = []
    @State private var searchText = ""

    let colors = ["blue", "green", "orange", "purple", "red", "pink", "yellow", "cyan"]

    var filtered: [Exercise] {
        if searchText.isEmpty { return workoutManager.availableExercises }
        return workoutManager.availableExercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

                List {
                    Section {
                        TextField("e.g. Push Day", text: $name)
                            .foregroundColor(.white)
                            .listRowBackground(Color.white.opacity(0.04))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(Color.color(named: color))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                        )
                                        .onTapGesture { selectedColor = color }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                    } header: {
                        Text("Routine Info")
                            .foregroundColor(Color.white.opacity(0.3))
                    }

                    Section {
                        ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { category in
                            let categoryExercises = filtered.filter { $0.category == category }
                            if !categoryExercises.isEmpty {
                                DisclosureGroup {
                                    ForEach(categoryExercises) { exercise in
                                        HStack {
                                            Image(systemName: selectedExercises.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedExercises.contains(exercise.id) ? GymOSColors.primaryPurple : Color.white.opacity(0.3))
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(exercise.name)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.white)
                                                Text(exercise.muscleGroups.joined(separator: ", "))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.white.opacity(0.35))
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if selectedExercises.contains(exercise.id) {
                                                selectedExercises.remove(exercise.id)
                                            } else {
                                                selectedExercises.insert(exercise.id)
                                            }
                                        }
                                        .listRowBackground(Color.white.opacity(0.04))
                                    }
                                } label: {
                                    HStack {
                                        Text(category.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        let selectedCount = categoryExercises.filter { selectedExercises.contains($0.id) }.count
                                        if selectedCount > 0 {
                                            Text("\(selectedCount)")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(GymOSColors.primaryPurple)
                                        }
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.04))
                            }
                        }
                    } header: {
                        Text("Exercises")
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search exercises")
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(GymOSColors.primaryPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let exercises = workoutManager.availableExercises.filter { selectedExercises.contains($0.id) }
                        workoutManager.addWorkoutDay(name: name, exercises: exercises, color: selectedColor)
                        dismiss()
                    }
                    .disabled(name.isEmpty || selectedExercises.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(GymOSColors.primaryPurple)
                }
            }
        }
    }
}

// MARK: - Edit Routine View
    struct EditRoutineView: View {
        let day: WorkoutDay
        @EnvironmentObject var workoutManager: WorkoutManager
        @Environment(\.dismiss) var dismiss
        @State private var name: String
        @State private var selectedColor: String
        @State private var selectedExercises: Set<UUID>
        @State private var searchText = ""
        
        let colors = ["blue", "green", "orange", "purple", "red", "pink", "yellow", "cyan"]
        
        init(day: WorkoutDay) {
            self.day = day
            _name = State(initialValue: day.name)
            _selectedColor = State(initialValue: day.color)
            _selectedExercises = State(initialValue: Set(day.exercises.map { $0.id }))
        }
        
        var filtered: [Exercise] {
            if searchText.isEmpty { return workoutManager.availableExercises }
            return workoutManager.availableExercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        var body: some View {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
                
                List {
                    Section {
                        TextField("Routine name", text: $name)
                            .foregroundColor(.white)
                            .listRowBackground(Color.white.opacity(0.04))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(Color.color(named: color))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                        )
                                        .onTapGesture { selectedColor = color }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                    } header: {
                        Text("Routine Info").foregroundColor(Color.white.opacity(0.3))
                    }
                    
                    Section {
                        ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { category in
                            let categoryExercises = filtered.filter { $0.category == category }
                            if !categoryExercises.isEmpty {
                                DisclosureGroup {
                                    ForEach(categoryExercises) { exercise in
                                        HStack {
                                            Image(systemName: selectedExercises.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedExercises.contains(exercise.id) ? GymOSColors.primaryPurple : Color.white.opacity(0.3))
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(exercise.name)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.white)
                                                Text(exercise.muscleGroups.joined(separator: ", "))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.white.opacity(0.35))
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if selectedExercises.contains(exercise.id) {
                                                selectedExercises.remove(exercise.id)
                                            } else {
                                                selectedExercises.insert(exercise.id)
                                            }
                                        }
                                        .listRowBackground(Color.white.opacity(0.04))
                                    }
                                } label: {
                                    HStack {
                                        Text(category.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        let selectedCount = categoryExercises.filter { selectedExercises.contains($0.id) }.count
                                        if selectedCount > 0 {
                                            Text("\(selectedCount)")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(GymOSColors.primaryPurple)
                                        }
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.04))
                            }
                        }
                    } header: {
                        Text("Exercises")
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                }
                .listStyle(.insetGrouped)  .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, prompt: "Search exercises")
                }
                .navigationTitle(name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            let exercises = workoutManager.availableExercises.filter { selectedExercises.contains($0.id) }
                            workoutManager.updateWorkoutDay(day, name: name, exercises: exercises, color: selectedColor)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(GymOSColors.primaryPurple)
                    }
                }
            }
        }
        
        // MARK: - History View
        struct HistoryView: View {
            @EnvironmentObject var workoutManager: WorkoutManager
            @Environment(\.dismiss) var dismiss
            
            var body: some View {
                NavigationView {
                    ZStack {
                        Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
                        
                        List {
                            ForEach(workoutManager.workouts) { workout in
                                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(workout.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        HStack(spacing: 8) {
                                            Text(formattedDate(workout.date))
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.white.opacity(0.35))
                                            Text("·")
                                                .foregroundColor(Color.white.opacity(0.2))
                                            Text("\(workout.exercises.count) exercises")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.white.opacity(0.35))
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color.white.opacity(0.04))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                    .navigationTitle("History")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") { dismiss() }
                                .foregroundColor(GymOSColors.primaryPurple)
                        }
                    }
                }
            }
            
            private func formattedDate(_ date: Date) -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, MMM d"
                return formatter.string(from: date)
            }
        }
        
        // MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

            List {
                if let score = workout.reflectionScore {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Session check-in")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.4))
                                if !workout.reflectionNotes.isEmpty {
                                    Text(workout.reflectionNotes)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                        .padding(.top, 2)
                                }
                            }
                            Spacer()
                            Text("\(score)/10")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(GymOSColors.primaryPurple)
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                        .padding(.vertical, 6)
                    }
                }

                ForEach(workout.exercises) { session in
                    Section {
                        ForEach(Array(session.sets.enumerated()), id: \.element.id) { index, set in
                            if set.isCompleted {
                                HStack {
                                    Text("Set \(index + 1)")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.white.opacity(0.4))
                                    Spacer()
                                    Text("\(set.weight.clean)kg × \(set.reps)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .listRowBackground(Color.white.opacity(0.04))
                            }
                        }
                        if !session.notes.isEmpty {
                            Text("📝 " + session.notes)
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.5))
                                .listRowBackground(Color.white.opacity(0.04))
                        }
                    } header: {
                        Text(session.exercise.name)
                            .foregroundColor(GymOSColors.primaryPurple)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
        
        #Preview {
            YouView()
                .environmentObject(WorkoutManager())
        }
