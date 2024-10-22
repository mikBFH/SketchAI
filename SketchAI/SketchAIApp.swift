//
//  SketchAIApp.swift
//  SketchAI
//
//  Created by Kevin Fred  on 22/10/24.
//

import SwiftUI

@main
struct SketchAIApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
