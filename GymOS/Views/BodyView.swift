import SwiftUI
import MuscleMap

struct BodyTabView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var side: BodySide = .front
    @State private var selectedMuscle: Muscle? = nil

    private var weeklyMuscleIntensities: [MuscleIntensity] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        let weeklyWorkouts = workoutManager.workouts.filter { $0.date >= weekStart }
        var muscleVolume: [String: Double] = [:]

        for workout in weeklyWorkouts {
            for session in workout.exercises {
                let completedSets = session.sets.filter { $0.isCompleted }
                let volume = completedSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                for muscle in session.exercise.muscleGroups {
                    muscleVolume[muscle, default: 0] += volume
                }
            }
        }

        var intensities: [MuscleIntensity] = []
        for (muscleName, volume) in muscleVolume {
            guard let muscle = muscleMapping[muscleName] else { continue }
            let intensity = min(volume / 2000.0, 1.0)
            intensities.append(MuscleIntensity(muscle: muscle, intensity: intensity))
        }
        return intensities
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("This week")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(GymOSColors.primaryPurple)
                            .tracking(2)
                            .textCase(.uppercase)

                        Text("Body")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                    // Front/Back toggle
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { side = .front }
                        } label: {
                            Text("Front")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(side == .front ? .white : Color.white.opacity(0.35))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(side == .front ? GymOSColors.primaryPurple : Color.clear)
                        }
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { side = .back }
                        } label: {
                            Text("Back")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(side == .back ? .white : Color.white.opacity(0.35))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(side == .back ? GymOSColors.primaryPurple : Color.clear)
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    // Body map
                    BodyView(gender: .male, side: side)
                        .heatmap(weeklyMuscleIntensities, colorScale: HeatmapColorScale(colors: [
                            Color(red: 0.23, green: 0.23, blue: 0.28),
                            Color(red: 0.18, green: 0.6, blue: 0.9),
                            Color(red: 1.0, green: 0.85, blue: 0.2),
                            Color(red: 0.2, green: 0.78, blue: 0.35),
                            Color(red: 0.95, green: 0.25, blue: 0.25)
                        ]))
                        .bodyStyle(BodyViewStyle(
                            defaultFillColor: Color(red: 0.23, green: 0.23, blue: 0.28),
                            strokeColor: Color(red: 0.15, green: 0.15, blue: 0.2),
                            strokeWidth: 0.5,
                            selectionColor: GymOSColors.primaryPurple,
                            selectionStrokeColor: GymOSColors.primaryPurple,
                            selectionStrokeWidth: 1.5,
                            headColor: Color(red: 0.18, green: 0.18, blue: 0.22),
                            hairColor: Color(red: 0.12, green: 0.12, blue: 0.15),
                            shadowColor: .clear,
                            shadowRadius: 0,
                            shadowOffset: .zero
                        ))
                        .onMuscleSelected { muscle, _ in
                            selectedMuscle = muscle
                        }
                        .frame(maxHeight: 420)
                        .padding(.horizontal, 24)

                    // Legend
                    HStack(spacing: 12) {
                        ForEach([
                            ("None", Color(red: 0.23, green: 0.23, blue: 0.28)),
                            ("Light", Color(red: 0.18, green: 0.6, blue: 0.9)),
                            ("Moderate", Color(red: 1.0, green: 0.85, blue: 0.2)),
                            ("Good", Color(red: 0.2, green: 0.78, blue: 0.35)),
                            ("Heavy", Color(red: 0.95, green: 0.25, blue: 0.25))
                        ], id: \.0) { label, color in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 8, height: 8)
                                Text(label)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.vertical, 12)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedMuscle) { muscle in
                MuscleDetailSheet(muscle: muscle)
                    .environmentObject(workoutManager)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Muscle Detail Sheet
struct MuscleDetailSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    let muscle: Muscle

    private var relatedExercises: [Exercise] {
        let muscleNames = reverseMuscleMapping[muscle] ?? []
        return workoutManager.availableExercises.filter { exercise in
            exercise.muscleGroups.contains { muscleNames.contains($0) }
        }
    }

    private var recentSets: [(exerciseName: String, set: WorkoutSet, date: Date)] {
        let muscleNames = reverseMuscleMapping[muscle] ?? []
        var results: [(String, WorkoutSet, Date)] = []

        for workout in workoutManager.workouts.prefix(10) {
            for session in workout.exercises {
                if session.exercise.muscleGroups.contains(where: { muscleNames.contains($0) }) {
                    for set in session.sets where set.isCompleted {
                        results.append((session.exercise.name, set, workout.date))
                    }
                }
            }
        }
        return results.prefix(8).map { $0 }
    }

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(muscle.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                if recentSets.isEmpty {
                    Text("No sets logged this week for this muscle group.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.horizontal, 24)
                } else {
                    List {
                        ForEach(Array(recentSets.enumerated()), id: \.offset) { _, item in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.exerciseName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Text(formattedDate(item.date))
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.white.opacity(0.35))
                                }
                                Spacer()
                                Text("\(item.set.weight.clean)kg × \(item.set.reps)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                Text(item.set.mode.rawValue)
                                    .font(.system(size: 10))
                                    .foregroundColor(item.set.mode == .strength ? GymOSColors.primaryPurple : .orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(item.set.mode == .strength ? GymOSColors.primaryPurple.opacity(0.12) : Color.orange.opacity(0.12))
                                    .cornerRadius(5)
                            }
                            .listRowBackground(Color.white.opacity(0.04))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}

// MARK: - Muscle Mapping
let muscleMapping: [String: Muscle] = [
    "Upper Chest": .upperChest,
    "Mid Chest": .chest,
    "Lower Chest": .lowerChest,
    "Front Delt": .deltoids,
    "Side Delt": .deltoids,
    "Rear Delt": .rearDeltoid,
    "Bicep": .biceps,
    "Tricep": .triceps,
    "Forearm": .forearm,
    "Abs": .abs,
    "Lats": .upperBack,
    "Mid Back": .rhomboids,
    "Upper Back": .trapezius,
    "Lower Back": .lowerBack,
    "Glutes": .gluteal,
    "Quads": .quadriceps,
    "Hamstrings": .hamstring,
    "Hip Flexors": .hipFlexors,
    "Calves": .calves
]

let reverseMuscleMapping: [Muscle: [String]] = {
    var dict: [Muscle: [String]] = [:]
    for (name, muscle) in muscleMapping {
        dict[muscle, default: []].append(name)
    }
    return dict
}()

