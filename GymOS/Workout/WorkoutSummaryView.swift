import SwiftUI

struct WorkoutSummaryView: View {
    let workout: Workout
    let onDismiss: () -> Void
    
    private var totalSets: Int {
        workout.exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }
    
    private var totalVolume: Double {
        workout.exercises.flatMap { $0.sets }
            .filter { $0.isCompleted }
            .reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    private var duration: String {
        let mins = Int(workout.duration / 60)
        if mins < 60 { return "\(mins)m" }
        return "\(mins / 60)h \(mins % 60)m"
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Done")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GymOSColors.primaryPurple)
                        .tracking(2)
                        .textCase(.uppercase)
                    
                    Text(workout.name)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(formattedDate)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 36)
                
                // Stats
                HStack(spacing: 1) {
                    SummaryStatBlock(value: "\(totalSets)", label: "Sets")
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 1)
                    SummaryStatBlock(value: "\(Int(totalVolume))kg", label: "Volume")
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 1)
                    SummaryStatBlock(value: duration, label: "Time")
                }
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.04))
                .overlay(Rectangle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                .padding(.bottom, 32)
                
                // Exercise breakdown
                Text("Exercises")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.3))
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, session in
                            let completed = session.sets.filter { $0.isCompleted }
                            if !completed.isEmpty {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.exercise.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Text(completed.map { "\($0.weight.clean)kg × \($0.reps)" }.joined(separator: "  ·  "))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.3))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text("\(completed.count) sets")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.25))
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                
                                if index < workout.exercises.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.06))
                                        .padding(.leading, 24)
                                }
                            }
                        }
                    }
                    .background(Color.white.opacity(0.04))
                    .overlay(Rectangle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                }
                
                Spacer()
                
                // Done button
                Button(action: onDismiss) {
                    Text("Back to home")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(GymOSColors.primaryPurple)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: workout.date)
    }
}

struct SummaryStatBlock: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.3))
                .tracking(1.5)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }
}
