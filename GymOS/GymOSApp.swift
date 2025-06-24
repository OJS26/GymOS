//
//  GymOSApp.swift
//  GymOS
//
//  Created by OJ Strachan on 24/06/2025.
//

import SwiftUI

@main
struct GymOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
