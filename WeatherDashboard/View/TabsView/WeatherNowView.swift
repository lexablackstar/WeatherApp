//
//  WeatherNowView.swift
//  WeatherDashboard
//
// Displays current weather conditions for the selected location
// This is Tab 1 - Shows real-time weather data with metrics and AI advice
import SwiftUI
import SwiftData

struct WeatherNowView: View {
    @EnvironmentObject var viewModel: WeatherViewModel              /// Access to shared weather view model
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // MARK: Background
            // Full-screen gradient background (blue to red fade)
            GradientBackground()
            
            // MARK: Main Content
            // Only display content when all required data is available
            // This prevents crashes from force-unwrapping nil values
            if let current = viewModel.currentWeather,
               let apiResponse = viewModel.weatherApiResponse,
               let firstDay = apiResponse.daily.first,
               let condition = current.weather.first {
                
                VStack(spacing: 10) {
                    
                    // Display current location name
                    Text(viewModel.currentLocationName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // MARK: - Weather Icon and Temperature
                    HStack(spacing: 30) {
                        
                        // Use SFSymbols for a professional look, mapping from OpenWeather's main description
                        Image(systemName: mapWeatherConditionToSymbol(main: condition.main))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white.opacity(0.75))
                        
                        VStack(spacing: 5) {
                            Text("\(Int(current.temp))°C")
                                .font(.system(size: 40, weight: .thin))
                                .foregroundColor(.white)
                            
                            Text(apiResponse.current.weather.first!.description.capitalized)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack (spacing: 20) {
                                Text("Min: \(Int(firstDay.temp.min))°C")
                                    .font(.system(size: 15, weight: .thin))
                                    .foregroundColor(.black)
                                Text("Max: \(Int(firstDay.temp.max))°C")
                                    .font(.system(size: 15, weight: .thin))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    
                    
                    // MARK: - Key Metrics
                    VStack {
                        // First row: Humidity, Wind, Pressure
                        HStack {
                            MetricView(title: "Humidity", value: "\(current.humidity)%", icon: "drop.fill")
                            MetricView(title: "Wind", value: "\(Int(current.windSpeed)) m/s", icon: "wind")
                            MetricView(title: "Pressure", value: "\(current.pressure) hPa", icon: "barometer")
                        }
                        .padding(.horizontal)
                        // Second row: Sunrise and Sunset times
                        HStack {
                            MetricView(title: "Sunrise", value: formatSunTime(current.sunrise, timezoneOffset: apiResponse.timezone_offset), icon: "sunrise")
                            MetricView(title: "Sunset", value: formatSunTime(current.sunset, timezoneOffset: apiResponse.timezone_offset), icon: "sunset")

                        }
                        .padding(.horizontal)

                    }
                    
                    // MARK: - AI Weather Advice Section
                    
                    VStack {
                        if viewModel.isLoadingAdvice {
                            // Show loading indicator while fetching
                            ProgressView()
                                .tint(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            let adviceMessage: String = {
                                let initial = viewModel.adviceMessage
                                if initial.isEmpty || initial == "ERROR FROM OPEN AI" {
                                    return WeatherAdvice.advice(for: condition.main, tempC: current.temp).message
                                } else {
                                    return initial
                                }
                            }()
                            
                            Text(adviceMessage)
                                .font(.system(size: 18, weight: .thin))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding()
                                .background(.black.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .foregroundColor(.white.opacity(0.95))
                        }
                    }
                    .padding(.vertical, 5)
                }
                
            } else {
                Text("loading weather data ...")
                    .foregroundColor(.white)
            }
        }
        
    }
    
    // MARK: - Helper Methods
    
    // Formats sunrise/sunset times with correct timezone
    // - Parameters:
    //   - date: The Date object from API (Unix timestamp)
    //   - timezoneOffset: Seconds from UTC (e.g., 3600 for UTC+1)
    // - Returns: Formatted time string (e.g., "6:30 AM")
    private func formatSunTime(_ date: Date, timezoneOffset: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset)
        return formatter.string(from: date)
    }
    
    // Maps OpenWeatherMap condition string to SF Symbol name
    // - Parameter main: Weather condition from API (Clear, Clouds, Rain, etc.)
    // - Returns: SF Symbol system icon name
    private func mapWeatherConditionToSymbol(main: String) -> String {
        switch main.lowercased() {
        case "clear": return "sun.max.fill"
        case "clouds": return "cloud.fill"
        case "rain", "drizzle": return "cloud.rain.fill"
        case "thunderstorm": return "cloud.bolt.fill"
        case "snow": return "cloud.snow.fill"
        case "mist", "smoke", "haze", "fog": return "cloud.fog.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

// MARK: - MetricView Component

// Reusable component for displaying weather metrics
// Used for humidity, wind, pressure, sunrise, and sunset
struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}



