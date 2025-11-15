//
//  SleepSenseApp.swift
//  SleepSense
//
//  Created by Rushan Chanuka on 2025-11-15.
//

import SwiftUI

@main
struct SleepSenseApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
