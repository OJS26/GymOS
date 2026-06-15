//
//  GymOSApp.swift
//  GymOS
//
//  Created by OJ Strachan on 24/06/2025.
//

import SwiftUI

@main
struct GymOSApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
                .environmentObject(themeManager)
        }
    }
}
