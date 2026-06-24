import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget
struct GymOSLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymOSActivityAttributes.self) { context in
            // Lock screen / banner UI
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 16, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.workoutName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Workout in progress — tap to log")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(timerInterval: context.attributes.startTime...Date.distantFuture, countsDown: false)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.purple)
                    .monospacedDigit()
                    .frame(width: 50)
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.05, blue: 0.07))
            .activityBackgroundTint(Color(red: 0.05, green: 0.05, blue: 0.07))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view (long press)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.purple)
                            .font(.system(size: 16))
                        Text(context.state.workoutName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startTime...Date.distantFuture, countsDown: false)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.purple)
                        .monospacedDigit()
                        .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Tap to log your next set")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 8)
                }
                
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 12))
                    .padding(.leading, 4)
                    
            } compactTrailing: {
                Text(timerInterval: context.attributes.startTime...Date.distantFuture, countsDown: false)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.purple)
                    .monospacedDigit()
                    .frame(width: 36)
                    
            } minimal: {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 12))
            }
        }
    }
}

