//
//  PadelHitsApp.swift
//  PadelHits
//
//  Created by Cristian Di Cillo on 26/03/26.
//

import SwiftUI
import SwiftData

@main
struct PadelHitsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // per preparare il database ad ospitare questi tipi di dati
        .modelContainer(for: SessionePadel.self)
    }
}
