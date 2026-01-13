//
//  WeatherDashboardApp.swift
//  WeatherDashboard
//

import SwiftUI
import SwiftData

// MARK: - App Entry Point
// The @main attribute marks this as the entry point of the application
@main
struct WeatherDashboardApp: App {

    // MARK: - State Management
    @StateObject private var weatherViewModel = WeatherViewModel()
    
    // MARK: - Scene Configuration
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(weatherViewModel)
        }
        .modelContainer(for: [SavedLocation.self, PointOfInterest.self], inMemory: true)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(WeatherViewModel())
}
