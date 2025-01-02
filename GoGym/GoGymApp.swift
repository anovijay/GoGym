//
//  GoGymApp.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//

import SwiftUI

@main
struct GoGymApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
