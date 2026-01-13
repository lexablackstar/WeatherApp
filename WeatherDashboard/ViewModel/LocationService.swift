//
//  LocationService.swift
//  WeatherDashboard
//
// Service for geocoding location names and searching for Points of Interest
// Uses MapKit's MKLocalSearch for both operations

import Foundation
import CoreLocation
import MapKit

// MARK: - Error Definitions

// Custom error types for location service operations
enum LocationServiceError: Error {
    case geocodingFailed
    case noPlacemarkFound
    case poiSearchFailed
    case noPOIsFound
    case invalidLocation
}

class LocationService {

    // MARK: - Location Verification
    
    // Verifies if a location name is valid before attempting geocoding
    // This prevents unnecessary API calls for obviously invalid inputs
    //
    // - Parameter locationName: Name of location to verify
    // - Returns: true if location exists and is valid
    // - Throws: LocationServiceError.invalidLocation if validation fails
    func verifyLocation(locationName: String) async throws -> Bool {
        // Remove white spaces before and after the location name
        let trimmedLocation = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // VALIDATION 1: Check length constraints
        // Location name must be:
        // - Not empty
        // - At least 2 characters (e.g., "NY" for New York)
        // - Maximum 64 characters
        guard !trimmedLocation.isEmpty, trimmedLocation.count >= 2, trimmedLocation.count <= 64 else {
            throw LocationServiceError.invalidLocation
        }
        
        // VALIDATION 2: Perform test search
        // Create a search request with the location name
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = trimmedLocation
        
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            
            // VALIDATION 3: Check if we got any valid results
            guard !response.mapItems.isEmpty else {
                throw LocationServiceError.invalidLocation
            }
            
            // VALIDATION 4: Verify result quality
            // Check that the first result has meaningful data
            if let firstItem = response.mapItems.first {
                let hasValidName = firstItem.name != nil && !firstItem.name!.isEmpty
                let hasValidPlacemark = firstItem.placemark.locality != nil ||
                                       firstItem.placemark.country != nil
                
                guard hasValidName || hasValidPlacemark else {
                    throw LocationServiceError.invalidLocation
                }
            }
            
            return true
        } catch {
            // Any error during verification means location is invalid
            throw LocationServiceError.invalidLocation
        }
    }

    
    // MARK: - Geocoding
    
    // Converts a location name to geographic coordinates
    // Example: "London" → (51.5072°N, 0.1276°W)
    //
    // - Parameter locationName: Name of location (city, landmark, address)
    // - Returns: CLLocationCoordinate2D with latitude and longitude
    // - Throws: LocationServiceError if geocoding fails
    func geocode(locationName: String) async throws -> CLLocationCoordinate2D {
        
        // STEP 1: Verify location exists before geocoding
        try await verifyLocation(locationName: locationName)
        
        // STEP 2: Perform geocoding search
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = locationName
                
        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()
        
        // STEP 3: Extract coordinates from first result
        guard let mapItem = response.mapItems.first else {
            throw LocationServiceError.noPlacemarkFound
        }
                
        if #available(iOS 26.0, *) {
            return mapItem.location.coordinate
        } else {
            // Fallback on earlier versions
            return mapItem.placemark.coordinate
        }
    }
    
    // MARK: - Points of Interest Search
    
    // Searches for tourist attractions near specified coordinates
    // Returns top 5 POIs within 5km radius
    //
    // - Parameter coordinate: Center point for search
    // - Returns: Array of PointOfInterest objects (max 5)
    // - Throws: LocationServiceError if search fails or no POIs found
    func searchPOIs(coordinate: CLLocationCoordinate2D) async throws -> [PointOfInterest] {
        
        // STEP 1: Configure search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "tourist attractions"    /// MapKit requests categories like: "restaurants", "hotels", "tourist attractions", etc.
        
        // Search within a 5km radius of the coordinate
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        request.region = region
        
        // STEP 2: Execute search
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        // STEP 3: Filter and map the top 5 POIs to our SwiftData model
        let pois = response.mapItems
            .prefix(5)
            .compactMap { item -> PointOfInterest? in
                guard let name = item.name else {
                    return nil
                }
                
                // STEP 4: Extract coordinates (ensure backward compatibility)
                var coordinate: CLLocationCoordinate2D!
                if #available(iOS 26.0, *) {
                    coordinate = item.location.coordinate
                } else {
                    // Fallback on earlier versions
                    coordinate = item.placemark.coordinate
                }
                
                // STEP 5: Create PointOfInterest object
                return PointOfInterest(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
        
        guard !pois.isEmpty else {
            throw LocationServiceError.noPOIsFound
        }
        
        return pois
    }
}

