//
//  GradientBackground.swift
//  WeatherDashboard
//
// Reusable gradient background component used across all views
// Provides consistent visual styling throughout the app
import SwiftUI

struct GradientBackground: View {
    // MARK: - Properties
    let color1: Color
    let color2: Color
    
    // MARK: - Initialization
    
    // Creates a gradient background with customizable colors
    // Defaults to blue-to-red gradient if no colors specified
    // - Parameters:
    //   - color1: Starting color (top-left)
    //   - color2: Ending color (bottom-right)
    init(color1: Color = .blue.opacity(0.8), color2: Color = .red.opacity(0.3)) {
        self.color1 = color1
        self.color2 = color2
    }

    // MARK: - Body
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [color1, color2]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
