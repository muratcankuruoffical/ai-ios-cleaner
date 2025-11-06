//
//  AI_CleanerApp.swift
//  AI Cleaner
//
//  Created by MACBOOK PRO on 6.11.2025.
//

import SwiftUI
import CoreData

@main
struct AI_CleanerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
