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
                .onAppear {
                    SyncService.shared.syncLastNight(completion: nil)
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
