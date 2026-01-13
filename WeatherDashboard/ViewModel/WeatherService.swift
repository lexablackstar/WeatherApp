//
//  WeatherService.swift
//  WeatherDashboard
//
// Service class responsible for fetching weather data from OpenWeatherMap API
// Uses the One Call API 3.0 which provides current weather and 8-day forecast
import Foundation

// MARK: - Error Definitions

// Specific error cases for better error handling and user feedback
enum WeatherServiceError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError(Error)
}

class WeatherService {
    
    // MARK: - OpenWeatherMap API key and URL
    // This is a security risk - API key must NEVER be put in the code - to be removed after the demo
    private let apiKey = "7b67e4e50d1fc481bb70f7e7a521a67c"
    private let baseURL = "https://api.openweathermap.org/data/3.0/onecall"
    
    // Request current and daily data, excluding minutely, hourly, and alerts.
    // Use 'metric' units for Celsius.
    private let excludeParts = "minutely,hourly,alerts"
    private let units = "metric" // Use "imperial" for Fahrenheit
    
    // MARK: - Public Methods
     
    // Fetches weather data for specified coordinates
    // This is an async function that uses Swift's modern concurrency model
    //
    // - Parameters:
    //   - latitude: Geographic latitude (-90 to +90)
    //   - longitude: Geographic longitude (-180 to +180)
    // - Returns: Complete weather API response with current and daily data
    // - Throws: WeatherServiceError for various failure scenarios
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherAPIResponse {
        // 1. Construct the URL
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw WeatherServiceError.invalidURL
        }
        
        // Build query parameters array
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "exclude", value: excludeParts),
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        
        // Convert URLComponents to URL
        guard let url = urlComponents.url else {
            throw WeatherServiceError.invalidURL
        }
        
        // 2. Perform the network request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 3. Validate HTTP response
        //  200 = HTTP OK
        //  Other status code (4xx, 5xx, ...) is considered error - throw Invalid response
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Basic error handling for non-200 status codes
            throw WeatherServiceError.invalidResponse
        }
        
        // 4. Decode the JSON response
        do {
            let decoder = JSONDecoder()
            // Decode the data into our WeatherAPIResponse struct
            let weatherResponse = try decoder.decode(WeatherAPIResponse.self, from: data)
            return weatherResponse
        } catch {
            // If decoding fails, throw decoding error
            // This could happen if:
            // - JSON structure doesn't match our model
            // - Required fields are missing
            // - Data types don't match (e.g., string where number expected)
            throw WeatherServiceError.decodingError(error)
        }
    }
}

