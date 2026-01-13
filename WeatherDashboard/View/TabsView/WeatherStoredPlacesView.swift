//
//  WeatherStoredPlacesView.swift
//  WeatherDashboard
//
// Displays list of previously saved locations with management features
// This is Tab 4 - Shows saved locations with tap/long-press/swipe interactions
import SwiftUI
import SwiftData

struct WeatherStoredPlacesView: View {
    @EnvironmentObject var viewModel: WeatherViewModel  /// Access to shared weather view model

    // MARK: - Bindings
    
    // Binding to parent's selectedTab to enable tab switching and parent's searchText field
    @Binding var selectedTab: Int           /// Modified when user taps a location (switches to "Now" tab)
    @Binding var searchText: String         /// Modified when user taps a location (populates search bar)
    
    // Automatically fetches all SavedLocation entities from database
    // Sorted by savedDate in reverse (most recent first)
    // Updates automatically when database changes
    @Query(sort: \SavedLocation.savedDate, order: .reverse) private var savedLocations: [SavedLocation]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: Background
            // Full-screen gradient background (blue to red fade)
            GradientBackground(color1: Color.green.opacity(0.8), color2: Color.black.opacity(0.7))
            
            VStack {
                Text("Visited Locations")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.4))
                    .padding(.vertical)
                
                List {
                    ForEach(savedLocations) { location in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "pin.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(location.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Text("Lat: \(location.latitude, specifier: "%.4f"), Lon: \(location.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .onTapGesture {
                            // Tapping loads location and switches to "Now" tab
                            Task {
                                await viewModel.loadLocation(name: location.name, coordinate: location.coordinate)
                                
                                searchText = location.name // Change search text
                                selectedTab = 0 // Switch to "Now" tab
                            }
                        }
                        .onLongPressGesture {
                            // Long-pressing opens Google search
                            openGoogleSearch(for: location.name)
                        }
                        .swipeActions {
                            // Swipe-to-delete
                            Button("Delete", role: .destructive) {
                                do {
                                    try viewModel.deleteLocation(location: location)
                                } catch {
                                    viewModel.errorMessage = "Failed to delete location: \(error.localizedDescription)"
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    // MARK: - Helper Methods
    // Opens Google search in Safari for the given location
    // - Parameter query: Location name to search
    private func openGoogleSearch(for query: String) {
        let searchString = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.google.com/search?q=\(searchString)"
        if let url = URL(string: urlString) {
            // Open the URL in the default browser
            UIApplication.shared.open(url)
        }
    }
}

