import SwiftUI
import Foundation

// MARK: - Rest Timer View
struct RestTimerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("REST TIMER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(workoutManager.restTimerExercise)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("SET \(workoutManager.restTimerSetNumber)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Timer display - counting UP
                VStack {
                    Text(formatRestTime(workoutManager.restTimeElapsed))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    
                    Text("elapsed")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Timer controls
            HStack(spacing: 16) {
                // Stop button (main action)
                Button {
                    let restTime = workoutManager.stopRestTimer()
                    // Could store this rest time for analytics
                    print("Rest completed: \(restTime) seconds")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Finish Rest")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                // Rest time indicator
                VStack(alignment: .trailing, spacing: 2) {
                    if workoutManager.restTimeElapsed >= 60 {
                        let minutes = Int(workoutManager.restTimeElapsed) / 60
                        Text("\(minutes)min+")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Visual indicator for common rest ranges
                    restRangeIndicator
                }
            }
        }
        .padding(20)
    }
    
    private var restRangeIndicator: some View {
        HStack(spacing: 4) {
            // 1 minute mark
            Circle()
                .fill(workoutManager.restTimeElapsed >= 60 ? Color.green : Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // 1.5 minute mark
            Circle()
                .fill(workoutManager.restTimeElapsed >= 90 ? Color.yellow : Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // 2 minute mark
            Circle()
                .fill(workoutManager.restTimeElapsed >= 120 ? Color.orange : Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // 3+ minute mark
            Circle()
                .fill(workoutManager.restTimeElapsed >= 180 ? Color.red : Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
        }
    }
    
    private func formatRestTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%01d:%02d", minutes, seconds)
    }
}

// MARK: - Workout Settings View
struct WorkoutSettingsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var settings = RestTimerSettings()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Enable Rest Timer", isOn: $settings.isEnabled)
                        .tint(GymOSColors.primaryPurple)
                    
                    if settings.isEnabled {
                        Toggle("Auto-start after completing set", isOn: $settings.autoStart)
                            .tint(GymOSColors.primaryPurple)
                        
                        Toggle("Milestone haptic feedback", isOn: $settings.showMilestoneHaptics)
                            .tint(GymOSColors.primaryPurple)
                    }
                } header: {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(GymOSColors.primaryPurple)
                        Text("Rest Timer")
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(GymOSColors.infoBlue)
                            Text("How it works")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("The rest timer counts up from 0:00 when you complete a set. You control when to stop it and move to the next set. This gives you complete flexibility while tracking your actual rest times.")
                            .font(.caption)
                            .foregroundColor(GymOSColors.secondaryText)
                        
                        if settings.showMilestoneHaptics {
                            Text("You'll get gentle haptic feedback at 1min, 1.5min, and 2min intervals.")
                                .font(.caption)
                                .foregroundColor(GymOSColors.tertiaryText)
                                .italic()
                        }
                    }
                } header: {
                    Text("About Rest Timer")
                }
                
                // Preview section
                if settings.isEnabled {
                    Section("Preview") {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(GymOSColors.primaryPurple)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Rest Timer Active")
                                    .font(.headline)
                                    .foregroundColor(GymOSColors.primaryText)
                                
                                Text("Counts up: 0:00, 0:01, 0:02...")
                                    .font(.caption)
                                    .foregroundColor(GymOSColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Text("2:45")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(GymOSColors.primaryPurple)
                                .monospacedDigit()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GymOSColors.primaryPurple.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(GymOSColors.primaryPurple.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .navigationTitle("Workout Settings")
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
                        workoutManager.updateRestTimerSettings(settings)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(GymOSColors.primaryPurple)
                }
            }
            .onAppear {
                settings = workoutManager.restTimerSettings
            }
        }
    }
}

#Preview {
    RestTimerView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.dark)
}
