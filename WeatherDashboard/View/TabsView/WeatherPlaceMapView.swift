//
//  WeatherPlaceMapView.swift
//  WeatherDashboard
//
// Displays interactive map with Points of Interest (POIs)
// This is Tab 3 - Shows tourist attractions on a map with search integration
import SwiftUI
import MapKit

struct WeatherPlaceMapView: View {
    @EnvironmentObject var viewModel: WeatherViewModel          /// Access to shared weather view model
    
    // MARK: - State Properties
    
    @State private var mapRegion: MKCoordinateRegion            /// Current map region (center coordinate and zoom level)
    @State private var selectedPOI: PointOfInterest?            /// Currently selected POI (for potential detail view)
    
    
    // MARK: - Initialization
    // Initializes map centered on London (default location)
    init() {
        // Initialize with London's default coordinate
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: Background
            // Full-screen gradient background (blue to red fade)
            GradientBackground(color1: Color.green.opacity(0.8), color2: Color.blue.opacity(0.7))
            
            VStack {
                // Interactive Map
                Map(coordinateRegion: $mapRegion, annotationItems: viewModel.pointsOfInterest) { poi in
                    MapAnnotation(coordinate: poi.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                                .onTapGesture {
                                    // Tapping a map pin zooms the map out (500m region)
                                    mapRegion = MKCoordinateRegion(
                                        center: poi.coordinate,
                                        latitudinalMeters: 500,
                                        longitudinalMeters: 500
                                    )
                                }
                                .onLongPressGesture {
                                    // Long-pressing opens Google search
                                    openGoogleSearch(for: poi.name)
                                }
                            Text(poi.name)
                                .font(.caption)
                                .background(.white.opacity(0.8))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .onAppear {
                    mapRegion.center = viewModel.currentCoordinate
                }
                
                // MARK: - Section Header
                Text("Top 5 Tourist Attractions in \(viewModel.currentLocationName)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                                    
                // MARK: - POI List
                // Scrollable list of POIs below the map
                // Provides alternative navigation method to map pins
                ZStack {
                    Image("sky3")
                        .resizable()
                    List(viewModel.pointsOfInterest, id: \.name) { poi in
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.orange)
                            
                            Text(poi.name)
                                .onTapGesture {
                                    // Tapping a list item centers the map on the pin
                                    withAnimation {
                                        mapRegion.center = poi.coordinate
                                        mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                    }
                                }
                                .onLongPressGesture {
                                    // Long-pressing opens Google search
                                    openGoogleSearch(for: poi.name)
                                }
                                .listRowBackground(Color.clear)
                                .foregroundColor(.white)
                                .font(.footnote)
                        }
                        .listRowBackground(Color.clear)
                        .frame(height: 25)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        // Update map region when the current location changes
        .onChange(of: viewModel.currentCoordinate) { oldValue, newValue in
            withAnimation {
                mapRegion.center = newValue
                mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            }
        }
    }
    
    // MARK: - Helper Methods
    // Opens Google search in Safari for the given query
    // Used for both map pins and list items on long press
    // - Parameter query: Search term (POI name)
    private func openGoogleSearch(for query: String) {
        let searchString = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.google.com/search?q=\(searchString)"
        if let url = URL(string: urlString) {
            // Open the URL in the default browser
            UIApplication.shared.open(url)
        }
    }
}

