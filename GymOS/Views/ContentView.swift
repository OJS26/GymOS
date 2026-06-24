//
//  ContentView.swift
//  GymOS
//
//  Created by OJ Strachan on 15/06/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Today")
                }
            
            BodyTabView()
                .tabItem {
                    Image(systemName: "figure.arms.open")
                    Text("Body")
                }
            
            YouView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("You")
                }
        }
        .tint(GymOSColors.primaryPurple)
    }
}
