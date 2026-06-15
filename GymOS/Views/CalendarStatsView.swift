import SwiftUI
import Foundation

// MARK: - Calendar Stats View
struct CalendarStatsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedMonth = Date()
    @State private var currentStreak = 0
    @State private var longestStreak = 0
    @State private var thisMonthWorkouts = 0
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Cards
                    statsSection
                    
                    // Calendar
                    calendarSection
                    
                    // Recent Workouts Summary
                    recentWorkoutsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                calculateStats()
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Current Streak",
                    value: "\(currentStreak)",
                    subtitle: currentStreak == 1 ? "day" : "days",
                    icon: "flame.fill",
                    color: currentStreak > 0 ? GymOSColors.warningOrange : GymOSColors.tertiaryText,
                    isHighlighted: currentStreak > 0
                )
                
                StatCard(
                    title: "Longest Streak",
                    value: "\(longestStreak)",
                    subtitle: longestStreak == 1 ? "day" : "days",
                    icon: "trophy.fill",
                    color: GymOSColors.successGreen,
                    isHighlighted: longestStreak > 7
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "This Month",
                    value: "\(thisMonthWorkouts)",
                    subtitle: thisMonthWorkouts == 1 ? "workout" : "workouts",
                    icon: "dumbbell.fill",
                    color: GymOSColors.primaryPurple,
                    isHighlighted: thisMonthWorkouts > 0
                )
                
                StatCard(
                    title: "Total Workouts",
                    value: "\(workoutManager.workouts.count)",
                    subtitle: "all time",
                    icon: "chart.line.uptrend.xyaxis",
                    color: GymOSColors.infoBlue,
                    isHighlighted: workoutManager.workouts.count > 10
                )
            }
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button {
                    withAnimation(.spring()) {
                        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                        calculateMonthWorkouts()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(GymOSColors.primaryPurple)
                }
                
                Spacer()
                
                Text(selectedMonth, format: .dateTime.month(.wide).year())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(GymOSColors.primaryText)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                        calculateMonthWorkouts()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(GymOSColors.primaryPurple)
                }
            }
            .padding(.horizontal, 8)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Day headers
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(GymOSColors.tertiaryText)
                        .frame(height: 32)
                }
                
                // Calendar days
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month),
                        workoutCount: getWorkoutCount(for: date),
                        isToday: calendar.isDate(date, inSameDayAs: Date())
                    )
                }
            }
        }
        .cardStyle(padding: 20, cornerRadius: 20)
    }
    
    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(GymOSColors.primaryText)
                .padding(.horizontal, 4)
            
            if workoutManager.workouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundColor(GymOSColors.tertiaryText)
                    
                    Text("No workouts yet")
                        .font(.subheadline)
                        .foregroundColor(GymOSColors.secondaryText)
                    
                    Text("Start your first workout to see your progress here!")
                        .font(.caption)
                        .foregroundColor(GymOSColors.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .cardStyle()
            } else {
                ForEach(workoutManager.workouts.prefix(5)) { workout in
                    RecentWorkoutRow(workout: workout)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var calendarDays: [Date] {
        guard let monthStart = calendar.dateInterval(of: .month, for: selectedMonth)?.start else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let startDate = calendar.date(byAdding: .day, value: -(firstWeekday - 1), to: monthStart)!
        
        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }
    
    // MARK: - Helper Functions
    private func getWorkoutCount(for date: Date) -> Int {
        return workoutManager.workouts.filter { workoutItem in
            calendar.isDate(workoutItem.date, inSameDayAs: date)
        }.count
    }
    
    private func calculateStats() {
        calculateCurrentStreak()
        calculateLongestStreak()
        calculateMonthWorkouts()
    }
    
    private func calculateCurrentStreak() {
        let sortedWorkouts = workoutManager.workouts.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = Date()
        
        // Check if there's a workout today
        let hasWorkoutToday = sortedWorkouts.first { calendar.isDate($0.date, inSameDayAs: currentDate) } != nil
        
        if hasWorkoutToday {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        } else {
            // Check if there was a workout yesterday
            let hasWorkoutYesterday = sortedWorkouts.first { calendar.isDate($0.date, inSameDayAs: currentDate.addingTimeInterval(-86400)) } != nil
            if !hasWorkoutYesterday {
                currentStreak = 0
                return
            }
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        // Count consecutive days with workouts
        while let _ = sortedWorkouts.first(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        currentStreak = streak
    }
    
    private func calculateLongestStreak() {
        let workoutDates = Set(workoutManager.workouts.map {
            calendar.startOfDay(for: $0.date)
        })
        
        var maxStreak = 0
        var currentStreakCount = 0
        let sortedDates = workoutDates.sorted()
        
        for date in sortedDates {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: date)!
            
            if workoutDates.contains(previousDay) {
                currentStreakCount += 1
            } else {
                currentStreakCount = 1
            }
            
            maxStreak = max(maxStreak, currentStreakCount)
        }
        
        longestStreak = maxStreak
    }
    
    private func calculateMonthWorkouts() {
        thisMonthWorkouts = workoutManager.workouts.filter { workoutItem in
            calendar.isDate(workoutItem.date, equalTo: selectedMonth, toGranularity: .month)
        }.count
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isCurrentMonth: Bool
    let workoutCount: Int
    let isToday: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .bold : .medium))
                .foregroundColor(dayTextColor)
            
            // Workout indicator
            Group {
                if workoutCount > 0 {
                    Circle()
                        .fill(workoutIndicatorColor)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(width: 32, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(dayBackgroundColor)
        )
    }
    
    private var dayTextColor: Color {
        if isToday {
            return .white
        } else if isCurrentMonth {
            return GymOSColors.primaryText
        } else {
            return GymOSColors.tertiaryText
        }
    }
    
    private var dayBackgroundColor: Color {
        if isToday {
            return GymOSColors.primaryPurple
        } else {
            return Color.clear
        }
    }
    
    private var workoutIndicatorColor: Color {
        switch workoutCount {
        case 1:
            return GymOSColors.successGreen
        case 2:
            return GymOSColors.warningOrange
        case 3...:
            return GymOSColors.dangerRed
        default:
            return Color.clear
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isHighlighted: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if isHighlighted {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(GymOSColors.primaryText)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(GymOSColors.secondaryText)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(GymOSColors.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(GymOSColors.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isHighlighted ? color.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: colorScheme == .dark ?
                        Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - Recent Workout Row
struct RecentWorkoutRow: View {
    let workout: Workout
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Date circle
            VStack {
                Text("\(Calendar.current.component(.day, from: workout.date))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(GymOSColors.primaryPurple)
                
                Text(workout.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundColor(GymOSColors.tertiaryText)
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(GymOSColors.primaryPurple.opacity(0.1))
            )
            
            // Workout info
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(GymOSColors.primaryText)
                
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
                .foregroundColor(GymOSColors.secondaryText)
            }
            
            Spacer()
            
            // Workout day indicator
            if let workoutDay = workout.workoutDay {
                Circle()
                    .fill(Color.color(named: workoutDay.color))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(GymOSColors.elevatedBackground(for: colorScheme))
        )
    }
}

#Preview {
    CalendarStatsView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.dark)
}
