//
//  SafeMeshApp.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI
import Foundation

@main
struct SafeMeshApp: App {
    init() {
        // Defer non-critical initialization to avoid blocking app launch
        // This helps prevent CA Event App Launch Metrics errors
        DispatchQueue.global(qos: .background).async {
            // Initialize analytics, crash reporting, etc. here if needed
            // Any heavy initialization should be done in the background
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
