//
//  MukkiPlayerApp.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import SwiftUI
import CoreData

@main
struct MukkiPlayerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
