//
//  PersistenceModel.swift
//  WeatherDashboard
//
import Foundation
import SwiftData
import CoreLocation

// MARK: - SavedLocation Model
// Represents a saved weather location with geographic coordinates
// This is the primary entity that users interact with when saving locations
@Model
final class SavedLocation {
    
    // MARK: - Properties
    @Attribute(.unique) var name: String        /// Use location name as ID (unique) in database
    var latitude: Double
    var longitude: Double
    var savedDate: Date
    
    // Cascade delete: if a location is deleted, all its POIs are also deleted.
    @Relationship(deleteRule: .cascade)
    var pointsOfInterest: [PointOfInterest]?
    
    // MARK: - Initialization
    init(name: String, latitude: Double, longitude: Double, savedDate: Date = Date()) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.savedDate = savedDate
    }
    
    // MARK: - Helper for MapKit/CoreLocation
    // Converts stored lat/long into a CLLocationCoordinate2D for MapKit/CoreLocation
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - PointOfInterest Model
// Represents a notable place within a saved location (landmark, attraction, etc.)
// Examples: "Big Ben", "Tower Bridge", "Hyde Park"
@Model
final class PointOfInterest {
    
    // MARK: - Properties
    var name: String
    var latitude: Double
    var longitude: Double
    // Inverse relationship to the parent location
    var location: SavedLocation?
    
    // MARK: - Initialization
    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // MARK: - Helper for MapKit/CoreLocation
    // Converts stored lat/long into a CLLocationCoordinate2D for MapKit/CoreLocation
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

