//
//  ContentView.swift
//  WeatherDashboard
//

import SwiftUI
import SwiftData        // Data persistence framework (replacement for Core Data)
import Speech           // For speech recognition capabilities

// MARK: - Main Content View
// The root view of the weather application that manages tab navigation and search functionality
struct ContentView: View {
    
    // MARK: - Environment Properties
    @Environment(\.modelContext) private var modelContext   /// Model context for database operations
    @EnvironmentObject var viewModel: WeatherViewModel      /// Shared view model for weather data management
    

    @State private var searchText: String = ""              /// Current text in search field
    @State private var selectedTab: Int = 0                 /// Selected tab intex (0 to 3)
    @State private var isListening: Bool = false            /// Flag indicating if voice recording is active
    @State private var showPermissionAlert: Bool = false    /// Flag for displaying permission alert (microphone access)
    
    // Application title - displayed in the navigation bar
    private var appTitle: String = "Westminster's Smart Weather"
    
    // Speech recognizer object that handles voice-to-text conversion
    // StateObject ensures this persists across view updates
    @StateObject private var speechRecognizer = SpeechRecognizer()

    // MARK: - Body
    var body: some View {

        // TabView manages the four main screens of the app
        TabView (selection: $selectedTab) {
            
            // MARK: - Tab 1: Current Weather
            NavigationStack {
                WeatherNowView()
                    .applyNavigation(title: appTitle, searchText: $searchText, isListening: $isListening, onSearch: handleSearch, onVoiceSearch: handleVoiceSearch)
            }
            .tabItem {
                Label("Now", systemImage: "sun.max.fill")
            }
            .tag(0)     /// Identifier for programatic tab selection
            
            
            // MARK: - Tab 2: 8-Day Forecast
            NavigationStack {
                Weather8DaysForecastView()
                    .applyNavigation(title: appTitle, searchText: $searchText, isListening: $isListening, onSearch: handleSearch, onVoiceSearch: handleVoiceSearch)
            }
            .tabItem {
                Label("Forecast", systemImage: "calendar")
            }
            .tag(1)     /// Identifier for programatic tab selection
            
            // MARK: - Tab 3: Map View
            NavigationStack {
                WeatherPlaceMapView()
                    .applyNavigation(title: appTitle, searchText: $searchText, isListening: $isListening, onSearch: handleSearch, onVoiceSearch: handleVoiceSearch)
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            .tag(2)     /// Identifier for programatic tab selection
            
            // MARK: - Tab 4: Saved Locations
            NavigationStack {
                WeatherStoredPlacesView(selectedTab: $selectedTab, searchText: $searchText)
                    .applyNavigation(title: appTitle, searchText: $searchText, isListening: $isListening, onSearch: handleSearch, onVoiceSearch: handleVoiceSearch)
            }
            .tabItem {
                Label("Saved", systemImage: "globe")
            }
            .tag(3)     /// Identifier for programatic tab selection
        }
        .onAppear {
            viewModel.setModelContext(modelContext)     /// Called when view appears for the first time on the screen
            speechRecognizer.requestAuthorization()     /// Request microphone and speech recognition permissions
        }
        .onChange(of: speechRecognizer.transcript) { _, newValue in
            searchText = newValue
        }
        .onChange(of: speechRecognizer.isRecording) { oldValue, newValue in
            /// Debug only: logs to track state changes
            print("🎤 isRecording changed: \(oldValue) → \(newValue)")
            print("🎤 searchText: '\(searchText)'")
            print("🎤 searchText.isEmpty: \(searchText.isEmpty)")
            
            isListening = newValue
            
            // Trigger search when:
            // 1. Recording just stopped (oldValue: true → newValue: false)
            // 2. We have captured text to search
            if oldValue == true && newValue == false && !searchText.isEmpty {
                print("✅ Calling handleSearch()")
                handleSearch()
            } else {
                print("❌ NOT calling handleSearch - condition not met")
            }
        }
        .environmentObject(viewModel)                   /// Pass view model down to child view
        
        // Alert for errors or confirmation messages
        .alert(
            viewModel.errorMessage ?? viewModel.confirmationMessage ?? "",
            isPresented: .init(
                get: { viewModel.errorMessage != nil || viewModel.confirmationMessage != nil },
                set: { _ in
                    viewModel.errorMessage = nil
                    viewModel.confirmationMessage = nil
                }
            )
        ) {
            Button("OK", role: .cancel) { }
        }
        
        // Permission request alert (when voice search is attended without permissions)
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone and speech recognition permissions in Settings to use voice search.")
        }
    }
    
    // MARK: - Private methods
    
    // Handles search action (triggered by submit or voice end)
    // It loads weather data for the searched location
    private func handleSearch() {
        print("🔍 handleSearch called with: '\(searchText)'")
        Task {
            await viewModel.loadLocation(name: searchText, coordinate: defaultCoordinate, isInitialLoad: false)
        }
    }
    
    // Handles voice search button tap
    // It manages recording state and permission checks
    private func handleVoiceSearch() {
        guard speechRecognizer.isAuthorized else {
            showPermissionAlert = true              /// Show alert prompting user to enable permissions
            return
        }
        
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            searchText = ""                         /// Clear previous text
            speechRecognizer.startRecording()
        }
    }
    
}

// MARK: - View Extension
// ----------------------------------------------------------------------------
// Custom ViewModifier to avoid repetition of Search control (.searchable)
// This extension provides a reusable navigation configuration
// ----------------------------------------------------------------------------
extension View {
    // Applies consistent navigation elements across all tabs
    // - Parameters:
    //   - title: Navigation bar title text
    //   - searchText: Binding to search field text
    //   - isListening: Binding to voice recording state
    //   - onSearch: Callback when search is submitted
    //   - onVoiceSearch: Callback when voice button is tapped
    func applyNavigation(
        title: String,
        searchText: Binding<String>,
        isListening: Binding<Bool>,
        onSearch: @escaping () -> Void,
        onVoiceSearch: @escaping () -> Void
    ) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: searchText, prompt: "Change Location")
            .onSubmit(of: .search, onSearch)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onVoiceSearch) {
                        Image(systemName: isListening.wrappedValue ? "mic.fill" : "mic")
                            .foregroundColor(isListening.wrappedValue ? .red : .blue)
                            .font(.title3)
                    }
                }
            }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(WeatherViewModel())
}
