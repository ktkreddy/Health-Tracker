//
//  Health_TrackerApp.swift
//  Health Tracker
//
//  Created by Tarun Krishna Reddy Kolli on 8/10/24.
//

import SwiftUI

@main
struct Health_TrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
