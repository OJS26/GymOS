import SwiftUI
import WebKit

// MARK: - Exercises View with Days Integration
struct ExercisesView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selectedTab: ExerciseTab = .exercises
    @State private var selectedCategory: Exercise.ExerciseCategory?
    @State private var showingAddExercise = false
    @State private var searchText = ""
    @State private var showExerciseAdded = false
    @State private var addedExerciseName = ""
    
    enum ExerciseTab: String, CaseIterable {
        case exercises = "Library"
        case bodyMap = "Body Map"
        case days = "Workout Days"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    ForEach(ExerciseTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .exercises:
                        exercisesContent
                    case .bodyMap:
                        bodyMapContent 
                    case .days:
                        workoutDaysContent
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
                if selectedTab == .exercises {
                    AddCustomExerciseView()
                } else {
                    AddWorkoutDayView()
                }
            }
        }
    }
    
    // MARK: - Exercises Content
    private var exercisesContent: some View {
        VStack(spacing: 0) {
            // Search bar
            ExerciseSearchBar(text: $searchText)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            // Category filter
            categoryFilterView
                .padding(.bottom, 16)
            
            // Exercise list
            List {
                ForEach(filteredExercises) { exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        ExerciseRowView(exercise: exercise)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteExercises)
            }
            .listStyle(.plain)
        }
    }
    
    // MARK: - Workout Days Content
    private var workoutDaysContent: some View {
        WorkoutDaysContent()
    }
    
    // MARK: - Category Filter View
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryButton(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var bodyMapContent: some View {
        VStack {
            MuscleWikiWebView(onExerciseSelected: { exerciseName in
                let newExercise = createExerciseFromMuscleWiki(exerciseName)
                workoutManager.availableExercises.append(newExercise)
                showExerciseAdded = true
                addedExerciseName = exerciseName
            })
            
            // TEST BUTTON - remove this later
            Button("Test: Add Bench Press") {
                let newExercise = createExerciseFromMuscleWiki("Bench Press")
                workoutManager.availableExercises.append(newExercise)
                showExerciseAdded = true
                addedExerciseName = "Bench Press"
            }
            .padding()
        }
        .overlay(
            // Toast notification
            Group {
                if showExerciseAdded {
                    VStack {
                        Spacer()
                        Text("Added \(addedExerciseName) to Library!")
                            .padding()
                            .background(GymOSColors.successGreen)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .transition(.move(edge: .bottom))
                    }
                    .animation(.spring(), value: showExerciseAdded)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showExerciseAdded = false
                        }
                    }
                }
            }
        )
    }
    // MARK: - Filtered Exercises
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
    
    private func deleteExercises(offsets: IndexSet) {
        for index in offsets {
            let exercise = filteredExercises[index]
            if exercise.isCustom {
                workoutManager.deleteExercise(exercise)
            }
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : GymOSColors.primaryPurple)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? GymOSColors.primaryPurple : GymOSColors.primaryPurple.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(GymOSColors.primaryPurple.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Workout Days Content
struct WorkoutDaysContent: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingAddDay = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Create workout day templates to quickly start focused training sessions.")
                    .font(.subheadline)
                    .foregroundColor(GymOSColors.secondaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button {
                    showingAddDay = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(GymOSColors.primaryPurple)
                }
            }
            .padding(.horizontal, 20)
            
            // Workout Days List
            if workoutManager.workoutDays.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(GymOSColors.tertiaryText)
                    
                    Text("No workout days yet")
                        .font(.headline)
                        .foregroundColor(GymOSColors.primaryText)
                    
                    Text("Create workout day templates like 'Upper Body', 'Lower Body', or 'Push/Pull' to organize your training.")
                        .font(.subheadline)
                        .foregroundColor(GymOSColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    PurpleButton("Create Workout Day", variant: .filled, icon: "plus") {
                        showingAddDay = true
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 80)
            } else {
                List {
                    ForEach(workoutManager.workoutDays) { day in
                        NavigationLink(destination: WorkoutDayDetailView(day: day)) {
                            WorkoutDayRowView(day: day)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteDay)
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAddDay) {
            AddWorkoutDayView()
        }
    }
    
    private func deleteDay(offsets: IndexSet) {
        for index in offsets {
            workoutManager.deleteWorkoutDay(workoutManager.workoutDays[index])
        }
    }
}

// MARK: - Workout Day Row View
struct WorkoutDayRowView: View {
    let day: WorkoutDay
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Color indicator with exercise count
            ZStack {
                Circle()
                    .fill(Color.color(named: day.color))
                    .frame(width: 50, height: 50)
                
                Text("\(day.exercises.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Day information
            VStack(alignment: .leading, spacing: 6) {
                Text(day.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(GymOSColors.primaryText)
                
                Text("\(day.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundColor(GymOSColors.secondaryText)
                
                if !day.exercises.isEmpty {
                    Text(day.exercises.prefix(3).map { $0.name }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(GymOSColors.tertiaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Usage count
            let usageCount = getUsageCount(for: day)
            if usageCount > 0 {
                VStack {
                    Text("\(usageCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(GymOSColors.primaryPurple)
                    
                    Text("used")
                        .font(.caption2)
                        .foregroundColor(GymOSColors.tertiaryText)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(GymOSColors.cardBackground(for: colorScheme))
                .shadow(
                    color: colorScheme == .dark ?
                        Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private func getUsageCount(for day: WorkoutDay) -> Int {
        return workoutManager.workouts.filter { workoutItem in
            workoutItem.workoutDay?.id == day.id
        }.count
    }
}

// MARK: - Enhanced Exercise Row View
struct ExerciseRowView: View {
    let exercise: Exercise
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise category indicator
            Circle()
                .fill(categoryColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(GymOSColors.primaryText)
                    
                    if exercise.isCustom {
                        Text("CUSTOM")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(GymOSColors.successGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(GymOSColors.successGreen.opacity(0.1))
                            )
                    }
                    
                    Spacer()
                }
                
                Text(exercise.muscleGroups.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundColor(GymOSColors.secondaryText)
                
                Text(exercise.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(categoryColor.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(GymOSColors.cardBackground(for: colorScheme))
                .shadow(
                    color: colorScheme == .dark ?
                        Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private var categoryColor: Color {
        switch exercise.category {
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

// MARK: - Search Bar
struct ExerciseSearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(GymOSColors.tertiaryText)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search exercises...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(GymOSColors.primaryText)
            
            if !text.isEmpty {
                Button {
                    text = ""
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
    }
}

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: Exercise
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.colorScheme) var colorScheme
    
    var exerciseHistory: [ExerciseSession] {
        workoutManager.getExerciseHistory(for: exercise)
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Exercise header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(GymOSColors.primaryText)
                            
                            HStack {
                                Text(exercise.category.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(categoryColor)
                                    )
                                
                                if exercise.isCustom {
                                    Text("CUSTOM")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(GymOSColors.successGreen)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(GymOSColors.successGreen.opacity(0.1))
                                        )
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Muscle groups
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Muscles")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(GymOSColors.primaryText)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(exercise.muscleGroups, id: \.self) { muscle in
                                Text(muscle)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(GymOSColors.primaryPurple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(GymOSColors.primaryPurple.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(GymOSColors.primaryPurple.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            if let bestSet = workoutManager.getBestSet(for: exercise) {
                Section("Personal Record") {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Best Set")
                                    .font(.subheadline)
                                    .foregroundColor(GymOSColors.secondaryText)
                                Text("\(Int(bestSet.weight))kg × \(bestSet.reps)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(GymOSColors.primaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Volume")
                                    .font(.subheadline)
                                    .foregroundColor(GymOSColors.secondaryText)
                                Text("\(Int(bestSet.weight * Double(bestSet.reps)))kg")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(GymOSColors.successGreen)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            if !exerciseHistory.isEmpty {
                Section("Recent History") {
                    ForEach(exerciseHistory.prefix(10)) { session in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(GymOSColors.tertiaryText)
                            
                            let completedSets = session.sets.enumerated().filter { $0.element.isCompleted }
                            
                            if completedSets.isEmpty {
                                Text("No sets completed")
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundColor(GymOSColors.tertiaryText)
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(completedSets, id: \.offset) { index, set in
                                        HStack {
                                            Text("Set \(index + 1):")
                                                .font(.subheadline)
                                                .foregroundColor(GymOSColors.secondaryText)
                                            Spacer()
                                            Text("\(Int(set.weight))kg × \(set.reps)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(GymOSColors.primaryText)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Exercise Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var categoryColor: Color {
        switch exercise.category {
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

// MARK: - Add Custom Exercise View
struct AddCustomExerciseView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var exerciseName = ""
    @State private var selectedCategory: Exercise.ExerciseCategory = .chest
    @State private var muscleGroups: [String] = []
    @State private var newMuscleGroup = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Exercise Name", text: $exerciseName)
                        .font(.system(size: 16))
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                } header: {
                    Text("Exercise Details")
                }
                
                Section {
                    if !muscleGroups.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(muscleGroups, id: \.self) { muscle in
                                HStack(spacing: 4) {
                                    Text(muscle)
                                        .font(.subheadline)
                                    
                                    Button {
                                        muscleGroups.removeAll { $0 == muscle }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(GymOSColors.primaryPurple.opacity(0.1))
                                )
                                .foregroundColor(GymOSColors.primaryPurple)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    HStack {
                        TextField("Add muscle group", text: $newMuscleGroup)
                            .font(.system(size: 16))
                        
                        Button("Add") {
                            if !newMuscleGroup.isEmpty && !muscleGroups.contains(newMuscleGroup) {
                                muscleGroups.append(newMuscleGroup)
                                newMuscleGroup = ""
                            }
                        }
                        .disabled(newMuscleGroup.isEmpty)
                        .foregroundColor(GymOSColors.primaryPurple)
                    }
                } header: {
                    Text("Muscle Groups")
                }
                
                Section("Quick Add") {
                    let commonMuscles = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quadriceps", "Hamstrings", "Glutes", "Calves", "Core", "Lats", "Rhomboids"]
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(commonMuscles, id: \.self) { muscle in
                            Button(muscle) {
                                if !muscleGroups.contains(muscle) {
                                    muscleGroups.append(muscle)
                                }
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(muscleGroups.contains(muscle) ? GymOSColors.primaryPurple : GymOSColors.elevatedBackground(for: colorScheme))
                            )
                            .foregroundColor(muscleGroups.contains(muscle) ? .white : GymOSColors.primaryText)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Exercise")
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
                        workoutManager.addCustomExercise(
                            name: exerciseName,
                            category: selectedCategory,
                            muscleGroups: muscleGroups
                        )
                        dismiss()
                    }
                    .disabled(exerciseName.isEmpty || muscleGroups.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(GymOSColors.primaryPurple)
                }
            }
        }
    }
}

// MARK: - Add Workout Day View
struct AddWorkoutDayView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
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
                        .font(.system(size: 16))
                    
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
                    ExerciseSearchBar(text: $searchText)
                    
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
                                    .foregroundColor(selectedExercises.contains(exercise.id) ? GymOSColors.primaryPurple : .gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundColor(GymOSColors.primaryText)
                                
                                Text(exercise.muscleGroups.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(GymOSColors.secondaryText)
                                
                                Text(exercise.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(GymOSColors.primaryPurple.opacity(0.1))
                                    .foregroundColor(GymOSColors.primaryPurple)
                                    .cornerRadius(3)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Add Workout Day")
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
                        workoutManager.addWorkoutDay(name: dayName, exercises: exercises, color: selectedColor)
                        dismiss()
                    }
                    .disabled(dayName.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(GymOSColors.primaryPurple)
                }
            }
        }
    }
}
// ADD this function:
private func createExerciseFromMuscleWiki(_ name: String) -> Exercise {
    // Simple exercise creation - we can make this smarter later
    return Exercise(
        name: name,
        category: .chest, // Default category for now
        muscleGroups: ["Unknown"],
        isCustom: true
    )
}
