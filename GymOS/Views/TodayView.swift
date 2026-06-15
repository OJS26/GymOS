import SwiftUI

struct TodayView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingWorkout = false
    @State private var selectedDay: WorkoutDay? = nil

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var weeklyCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return workoutManager.workouts.filter { $0.date >= weekStart }.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(greeting)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(GymOSColors.primaryPurple)
                                .tracking(2)
                                .textCase(.uppercase)

                            Text("OJ")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)

                            Text(dayName)
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.35))
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
                            
                            StatBlock(value: "\(weeklyCount)", label: "This week", unit: "sessions")
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.04))
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                        .padding(.bottom, 32)

                        // Start button
                        Button {
                            selectedDay = nil
                            showingWorkout = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Start workout")
                                    .font(.system(size: 16, weight: .semibold))
                                    .tracking(0.3)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(GymOSColors.primaryPurple)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                        // Routines
                        if !workoutManager.workoutDays.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Routines")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.3))
                                    .tracking(2)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 14)

                                VStack(spacing: 0) {
                                    ForEach(Array(workoutManager.workoutDays.enumerated()), id: \.element.id) { index, day in
                                        RoutineRow(day: day) {
                                            selectedDay = day
                                            showingWorkout = true
                                        }

                                        if index < workoutManager.workoutDays.count - 1 {
                                            Divider()
                                                .background(Color.white.opacity(0.06))
                                                .padding(.leading, 24)
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.04))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                                )
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            Text("Workout")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea())
        }
    }
}

// MARK: - Stat Block
struct StatBlock: View {
    let value: String
    let label: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.3))
                .tracking(1.5)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

// MARK: - Routine Row
struct RoutineRow: View {
    let day: WorkoutDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Rectangle()
                    .fill(Color.color(named: day.color))
                    .frame(width: 3)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 5) {
                    Text(day.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(day.exercises.count) exercises")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.35))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.25))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(WorkoutManager())
        .environmentObject(ThemeManager())
}
