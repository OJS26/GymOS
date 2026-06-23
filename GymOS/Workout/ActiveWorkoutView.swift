import SwiftUI

struct IdentifiableInt: Identifiable {
    let id = UUID()
    let value: Int
}

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var showingExercisePicker = false
    @State private var showingEndConfirm = false
    @State private var logSheet: LogSheetData? = nil
    @State private var completedWorkout: Workout? = nil
    @State private var notingExerciseIndex: Int? = nil
    @State private var showingReflection = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

            VStack(spacing: 0) {

                // Nav bar
                HStack {
                    Text(workoutManager.currentWorkout?.name ?? "Workout")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        showingReflection = true
                    } label: {
                        Text("Finish")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(GymOSColors.primaryPurple)
                            .cornerRadius(10)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.0).onEnded { _ in
                            showingEndConfirm = true
                        }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5),
                    alignment: .bottom
                )

                // Exercise list
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if let workout = workoutManager.currentWorkout {
                            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { exIndex, session in
                                ExerciseCard(
                                    session: session,
                                    exerciseIndex: exIndex,
                                    onLogSet: { setIndex in
                                        logSheet = LogSheetData(exerciseIndex: exIndex, setIndex: setIndex, session: session)
                                    },
                                    onAddSet: {
                                        workoutManager.addSet(to: exIndex)
                                    },
                                    onDeleteSet: { setIndex in
                                        workoutManager.removeSet(exerciseIndex: exIndex, setIndex: setIndex)
                                    },
                                    onRemoveExercise: {
                                        workoutManager.removeExercise(at: exIndex)
                                    },
                                    onEditNote: {
                                        notingExerciseIndex = exIndex
                                    }
                                )
                            }
                        }

                        // Add exercise button
                        Button {
                            showingExercisePicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Add exercise")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(GymOSColors.primaryPurple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(GymOSColors.primaryPurple.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(GymOSColors.primaryPurple.opacity(0.25), lineWidth: 0.5)
                            )
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 24)
                }
            }
        }
        .sheet(item: $logSheet) { data in
            LogSetSheet(
                exerciseIndex: data.exerciseIndex,
                setIndex: data.setIndex,
                session: data.session
            )
            .environmentObject(workoutManager)
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView()
                .environmentObject(workoutManager)
        }
        .confirmationDialog("End workout?", isPresented: $showingEndConfirm, titleVisibility: .visible) {
            Button("End & discard", role: .destructive) {
                workoutManager.currentWorkout = nil
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(item: $completedWorkout) { workout in
            WorkoutSummaryView(workout: workout) {
                completedWorkout = nil
                dismiss()
            }
        }
        
        .sheet(isPresented: Binding(
            get: { notingExerciseIndex != nil },
            set: { if !$0 { notingExerciseIndex = nil } }
        )) {
            if let index = notingExerciseIndex {
                SessionNoteSheet(exerciseIndex: index)
                    .environmentObject(workoutManager)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
            }
        }
        
        .fullScreenCover(isPresented: $showingReflection) {
            ReflectionView { score, notes in
                showingReflection = false
                if let finished = workoutManager.finishWorkout(reflectionScore: score, reflectionNotes: notes) {
                    completedWorkout = finished
                }
            }
        }
    }
}

// MARK: - Log Sheet Data
struct LogSheetData: Identifiable {
    let id = UUID()
    let exerciseIndex: Int
    let setIndex: Int
    let session: ExerciseSession
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    let session: ExerciseSession
    let exerciseIndex: Int
    let onLogSet: (Int) -> Void
    let onAddSet: () -> Void
    let onDeleteSet: (Int) -> Void
    let onRemoveExercise: () -> Void
    let onEditNote: () -> Void

    @EnvironmentObject var workoutManager: WorkoutManager
    
    private var lastSession: ExerciseSession? {
        workoutManager.getExerciseHistory(for: session.exercise).last
    }

    private var suggestion: String? {
        workoutManager.weightSuggestion(for: session.exercise, variation: session.variation)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        onEditNote()
                    } label: {
                        Text(session.exercise.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    if let last = lastSession {
                        Text("Last: " + last.sets.filter { $0.isCompleted }.map {
                            "\($0.weight.clean)kg × \($0.reps)"
                        }.joined(separator: ", "))
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.3))
                        .lineLimit(1)
                    }

                    if !session.exercise.note.isEmpty {
                        Text(session.exercise.note)
                            .font(.system(size: 12))
                            .italic()
                            .foregroundColor(GymOSColors.primaryPurple.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    // Variation + mode tags
                    HStack(spacing: 6) {
                        if !session.variation.isEmpty {
                            Text(session.variation)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.5))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(6)
                        }
                        
                        let modes = Set(session.sets.map { $0.mode })
                        ForEach(Array(modes), id: \.self) { mode in
                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(mode == .strength ? GymOSColors.primaryPurple : .orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(mode == .strength ? GymOSColors.primaryPurple.opacity(0.12) : Color.orange.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                    
                    if !session.notes.isEmpty {
                        Text("📝 " + session.notes)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.5))
                            .lineLimit(2)
                    }
                }

                Spacer()

                if let s = suggestion {
                    Text("Try \(s)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GymOSColors.primaryPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(GymOSColors.primaryPurple.opacity(0.12))
                        .cornerRadius(8)
                }

                Menu {
                    Button(role: .destructive) {
                        onRemoveExercise()
                    } label: {
                        Label("Remove exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.3))
                        .padding(.leading, 8)
                }
            }

            // Column headers
            HStack {
                Text("SET")
                    .frame(width: 36, alignment: .leading)
                Spacer()
                Text("KG")
                    .frame(width: 60, alignment: .center)
                Spacer()
                Text("REPS")
                    .frame(width: 60, alignment: .center)
                Spacer()
                Text("")
                    .frame(width: 32)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(Color.white.opacity(0.2))
            .tracking(1.5)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Sets
            List {
                ForEach(Array(session.sets.enumerated()), id: \.element.id) { setIndex, set in
                    SetRow(
                        setNumber: setIndex + 1,
                        set: set,
                        onTap: { onLogSet(setIndex) },
                        onDelete: { onDeleteSet(setIndex) }
                    )
                    .listRowBackground(set.isCompleted ? GymOSColors.primaryPurple.opacity(0.05) : Color.white.opacity(0.04))
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .frame(height: CGFloat(session.sets.count) * 50)

            // Add set
            Button(action: onAddSet) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Add set")
                        .font(.system(size: 13))
                }
                .foregroundColor(Color.white.opacity(0.3))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.04))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - Set Row
struct SetRow: View {
    let setNumber: Int
    let set: WorkoutSet
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.white.opacity(0.3))
                .frame(width: 36, alignment: .leading)

            Spacer()

            Text(set.isCompleted ? set.weight.clean : "—")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(set.isCompleted ? .white : Color.white.opacity(0.2))
                .frame(width: 60, alignment: .center)

            Spacer()

            Text(set.isCompleted ? "\(set.reps)" : "—")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(set.isCompleted ? .white : Color.white.opacity(0.2))
                .frame(width: 60, alignment: .center)

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(set.mode == .strength ? GymOSColors.primaryPurple : .orange)
                    .frame(width: 6, height: 6)
                    .opacity(set.isCompleted ? 1 : 0)
                
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(set.isCompleted ? GymOSColors.primaryPurple : Color.white.opacity(0.2))
            }
            .frame(width: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(set.isCompleted ? GymOSColors.primaryPurple.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Log Set Sheet
struct LogSetSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedMode: SetMode = .strength
    @State private var variationText: String = ""
    @State private var showingNewVariation: Bool = false
    
    let exerciseIndex: Int
    let setIndex: Int
    let session: ExerciseSession
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    private var lastSet: WorkoutSet? {
        workoutManager.getExerciseHistory(for: session.exercise).last?.sets.last { $0.isCompleted }
    }
    
    private var suggestion: String? {
        workoutManager.weightSuggestion(for: session.exercise, variation: session.variation)
    }
    
    private var previousVariations: [String] {
        workoutManager.previousVariations(for: session.exercise)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.exercise.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Set \(setIndex + 1)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                
                // Last session + suggestion
                if lastSet != nil || suggestion != nil {
                    HStack(spacing: 16) {
                        if let last = lastSet {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LAST TIME")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.25))
                                    .tracking(1.5)
                                Text("\(last.weight.clean)kg × \(last.reps)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                        }
                        
                        if let s = suggestion {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SUGGESTED")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.25))
                                    .tracking(1.5)
                                Text(s)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(GymOSColors.primaryPurple)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                }
                
                // Variation input
                // Variation picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("VARIATION (OPTIONAL)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(1.5)
                    
                    // previousVariations is now a computed property above
                    
                    if !previousVariations.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // None option
                                Button {
                                    variationText = ""
                                } label: {
                                    Text("None")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(variationText.isEmpty ? .white : Color.white.opacity(0.4))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(variationText.isEmpty ? GymOSColors.primaryPurple : Color.white.opacity(0.06))
                                        .cornerRadius(20)
                                }
                                
                                ForEach(previousVariations, id: \.self) { variation in
                                    Button {
                                        variationText = variation
                                    } label: {
                                        Text(variation)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(variationText == variation ? .white : Color.white.opacity(0.4))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(variationText == variation ? GymOSColors.primaryPurple : Color.white.opacity(0.06))
                                            .cornerRadius(20)
                                    }
                                }
                                
                                // New variation option
                                Button {
                                    variationText = ""
                                    showingNewVariation = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text("New")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(GymOSColors.primaryPurple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(GymOSColors.primaryPurple.opacity(0.1))
                                    .cornerRadius(20)
                                }
                            }
                        }
                        
                        if showingNewVariation {
                            TextField("e.g. Low to High", text: $variationText)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(10)
                        }
                    } else {
                        TextField("e.g. Low to High, Single Arm", text: $variationText)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                    }
                }
                
                // Mode toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("MODE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(1.5)
                    
                    HStack(spacing: 0) {
                        ForEach(SetMode.allCases, id: \.self) { mode in
                            Button {
                                selectedMode = mode
                            } label: {
                                Text(mode.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedMode == mode ? .white : Color.white.opacity(0.35))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedMode == mode ? GymOSColors.primaryPurple : Color.clear)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                }
                
                // Inputs
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WEIGHT (KG)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.25))
                            .tracking(1.5)
                        
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REPS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.25))
                            .tracking(1.5)
                        
                        TextField("0", text: $repsText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                    }
                }
                
                // Confirm button
                Button {
                    let weight = Double(weightText) ?? 0
                    let reps = Int(repsText) ?? 0
                    workoutManager.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps, weight: weight)
                    workoutManager.currentWorkout?.exercises[exerciseIndex].sets[setIndex].mode = selectedMode
                    workoutManager.currentWorkout?.exercises[exerciseIndex].variation = variationText
                    workoutManager.completeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                    dismiss()
                } label: {
                    Text("Log set")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(GymOSColors.primaryPurple)
                        .cornerRadius(14)
                }
                .disabled(weightText.isEmpty || repsText.isEmpty)
            }
            .padding(24)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            let currentSet = workoutManager.currentWorkout?.exercises[exerciseIndex].sets[setIndex]
            weightText = currentSet?.weight == 0 ? "" : currentSet?.weight.clean ?? ""
            repsText = currentSet?.reps == 0 ? "" : "\(currentSet?.reps ?? 0)"
            selectedMode = currentSet?.mode ?? .strength
            variationText = workoutManager.currentWorkout?.exercises[exerciseIndex].variation ?? ""
        }
    }
}

// MARK: - Exercise Picker
struct ExercisePickerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showingCreateExercise = false

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
                    Button {
                        showingCreateExercise = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(GymOSColors.primaryPurple)
                            Text("Create new exercise")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(GymOSColors.primaryPurple)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(GymOSColors.primaryPurple.opacity(0.08))

                    ForEach(filtered) { exercise in
                        Button {
                            workoutManager.addExercise(exercise)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                Text(exercise.category.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.35))
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search exercises")
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GymOSColors.primaryPurple)
                }
            }
            .sheet(isPresented: $showingCreateExercise) {
                CreateExerciseInWorkoutSheet { newExercise in
                    workoutManager.addExercise(newExercise)
                    dismiss()
                }
                .environmentObject(workoutManager)
                .presentationDetents([.height(480)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Create Exercise In Workout Sheet
struct CreateExerciseInWorkoutSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    let onCreated: (Exercise) -> Void

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
                    let newExercise = Exercise(name: name, category: selectedCategory, muscleGroups: muscles, isCustom: true)
                    workoutManager.availableExercises.append(newExercise)
                    workoutManager.persistExercises()
                    onCreated(newExercise)
                } label: {
                    Text("Create & add")
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
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Session Note Sheet
// MARK: - Session Note Sheet
struct SessionNoteSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    let exerciseIndex: Int
    @State private var noteText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text(workoutManager.currentWorkout?.exercises[exerciseIndex].exercise.name ?? "")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTE FOR TODAY")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(1.5)

                    TextEditor(text: $noteText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .frame(height: 120)
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                        .focused($isFocused)
                }

                Button {
                    workoutManager.currentWorkout?.exercises[exerciseIndex].notes = noteText
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

                Spacer()
            }
            .padding(24)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            noteText = workoutManager.currentWorkout?.exercises[exerciseIndex].notes ?? ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

// MARK: - Reflection View
struct ReflectionView: View {
    let onComplete: (Int, String) -> Void
    @State private var score: Int = 7
    @State private var notes: String = ""

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Session check-in")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("How did that feel?")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(GymOSColors.primaryPurple)
                        Text("/ 10")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.3))
                    }

                    Slider(value: Binding(
                        get: { Double(score) },
                        set: { score = Int($0) }
                    ), in: 1...10, step: 1)
                    .tint(GymOSColors.primaryPurple)

                    HStack {
                        Text("Rough one")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.3))
                        Spacer()
                        Text("Crushed it")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTES (OPTIONAL)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(1.5)

                    TextEditor(text: $notes)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .frame(height: 120)
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                }

                Spacer()

                Button {
                    onComplete(score, notes)
                } label: {
                    Text("Save & finish")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(GymOSColors.primaryPurple)
                        .cornerRadius(14)
                }
                .padding(.bottom, 20)
            }
            .padding(24)
        }
    }
}

