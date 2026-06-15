import SwiftUI

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground()
            
            TabView {
                WorkoutView()
                    .tabItem {
                        Image(systemName: "dumbbell.fill")
                        Text("Workout")
                    }
                
                CalendarStatsView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Progress")
                    }
                
                HistoryView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("History")
                    }

                ExercisesView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Library")
                    }
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
            .environmentObject(workoutManager)
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .tint(GymOSColors.primaryPurple)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemeSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(GymOSColors.primaryPurple)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text("Theme")
                                .font(.headline)
                            Text("Current: \(themeManager.currentTheme.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingThemeSettings = true
                    }
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(GymOSColors.infoBlue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text("GymOS")
                                .font(.headline)
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingThemeSettings) {
                ThemeSettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
