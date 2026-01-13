//
//  WeatherModel.swift
//  WeatherDashboard
//
import Foundation

// MARK: - API Response Root
// Top-level response from OpenWeatherMap One Call API 3.0
// Contains all weather data: current conditions + 8-day forecast
struct WeatherAPIResponse: Codable {
    let lat: Double
    let lon: Double
    let timezone: String
    let timezone_offset: Int
    let current: CurrentWeather
    let daily: [DailyForecast]
}

// MARK: - Current Weather Conditions
// Represents real-time weather data for a specific location
struct CurrentWeather: Codable {
    var id: TimeInterval { dt.timeIntervalSince1970 }
    
    let dt: Date                        /// Time of data calculation, unix, UTC
    let temp: Double                    /// Current temperature
    let pressure: Int                   /// Pressure in hPa
    let humidity: Int                   /// Humidity percentage
    let windSpeed: Double
    let sunrise: Date                   /// Sunrise time, UTC
    let sunset: Date                    /// Sunset time, UTC
    let weather: [WeatherCondition]     /// Array of weather conditions
    
    // MARK: - Custom Coding Keys
    
    /// Maps Swift property names to JSON keys from API
    /// Necessary because Swift uses camelCase while API uses snake_case
    enum CodingKeys: String, CodingKey {
        case dt = "dt"
        case temp = "temp"
        case pressure = "pressure"
        case humidity = "humidity"
        case windSpeed = "wind_speed"
        case sunrise = "sunrise"
        case sunset = "sunset"
        case weather
    }
}

// MARK: - Daily Forecast
// Weather forecast for a single day (24-hour period)
struct DailyForecast: Codable {
    let dt: Date                        /// Date of the forecast
    let summary: String                 /// Human readable weather summary (e.g. "partly cloudy")
    let temp: Temperature
    let weather: [WeatherCondition]
    
    // Coding keys
    enum CodingKeys: String, CodingKey {
        case dt, summary, temp, weather
    }
    
    // MARK: - Custom initialisation from JSON decoder
    
    // Needed to convert Unix timestamp to Date manually
    // The API provides timestamp as TimeInterval, which is converted to Date object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestamp = try container.decode(TimeInterval.self, forKey: .dt)
        self.dt = Date(timeIntervalSince1970: timestamp)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.temp = try container.decode(Temperature.self, forKey: .temp)
        self.weather = try container.decode([WeatherCondition].self, forKey: .weather)
    }

}

// MARK: - Temperature Details
// Comprehensive temperature data for different times of day
struct Temperature: Codable {
    let day: Double
    let min: Double
    let max: Double
    let night: Double
    let eve: Double
    let morn: Double
}

// MARK: - Weather Condition
// Describes the weather state (clear, rainy, snowy, etc.)
struct WeatherCondition: Codable {
    let id: Int                 /// Weather condition id (used for advisory)
    let main: String            /// Group of weather parameters (rain, snow, clear etc.)
    let description: String
    let icon: String            /// Weather icon id
}
