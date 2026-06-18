import SwiftUI

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var showingExercisePicker = false
    @State private var showingEndConfirm = false
    @State private var logSheet: LogSheetData? = nil
    @State private var completedWorkout: Workout? = nil

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

            VStack(spacing: 0) {

                // Nav bar
                HStack {
                    Button("Cancel") {
                        showingEndConfirm = true
                    }
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.4))

                    Spacer()

                    Text(workoutManager.currentWorkout?.name ?? "Workout")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button("Finish") {
                        workoutManager.endWorkout()
                        completedWorkout = workoutManager.workouts.first
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(GymOSColors.primaryPurple)
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

    @EnvironmentObject var workoutManager: WorkoutManager
    
    private var lastSession: ExerciseSession? {
        workoutManager.getExerciseHistory(for: session.exercise).last
    }

    private var suggestion: String? {
        workoutManager.weightSuggestion(for: session.exercise)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.exercise.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    if let last = lastSession {
                        Text("Last: " + last.sets.filter { $0.isCompleted }.map {
                            "\($0.weight.clean)kg × \($0.reps)"
                        }.joined(separator: ", "))
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.3))
                        .lineLimit(1)
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

            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(set.isCompleted ? GymOSColors.primaryPurple : Color.white.opacity(0.2))
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

    let exerciseIndex: Int
    let setIndex: Int
    let session: ExerciseSession

    @State private var weightText: String = ""
    @State private var repsText: String = ""

    private var lastSet: WorkoutSet? {
        workoutManager.getExerciseHistory(for: session.exercise).last?.sets.last { $0.isCompleted }
    }

    private var suggestion: String? {
        workoutManager.weightSuggestion(for: session.exercise)
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
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }
                            }
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
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }
                            }
                    }
                }

                // Confirm button
                Button {
                    let weight = Double(weightText) ?? 0
                    let reps = Int(repsText) ?? 0
                    workoutManager.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: reps, weight: weight)
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
    }
}

// MARK: - Exercise Picker
struct ExercisePickerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

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

                List(filtered) { exercise in
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
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search exercises")
            }
            .navigationTitle("Add Exercise")
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

