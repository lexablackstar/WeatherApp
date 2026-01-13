//
//  WeatherAdvice.swift
//  WeatherDashboard
//
// Provides context-aware recommendations based on weather conditions
// Used when OpenAI API is unavailable or fails
import Foundation

// MARK: - Weather Advice Enum

enum WeatherAdvice: String, CaseIterable, Identifiable {
    case umbrellaNeeded
    case perfectForWalk
    case chillyWearJacket
    case veryColdBundleUp
    case hotStayHydrated
    case windySecureItems
    case generic

    var id: String { rawValue }

    var message: String {
        switch self {
        case .umbrellaNeeded:
            return "Don't forget your umbrella, it might rain."
        case .perfectForWalk:
            return "The weather is perfect for a walk outside."
        case .chillyWearJacket:
            return "It's a bit chilly, wear a jacket."
        case .veryColdBundleUp:
            return "Very cold outside, bundle up warmly."
        case .hotStayHydrated:
            return "It's hot, stay hydrated and avoid the sun."
        case .windySecureItems:
            return "It's windy, secure loose items."
        case .generic:
            return "Have a nice day regardless of the weather."
        }
    }

    // MARK: - Advice Logic
    
    // Determines appropriate advice based on weather condition and temperature
    // This is a rule-based system with predefined logic
    //
    // - Parameters:
    //   - condition: Weather condition string (Rain, Clear, Clouds, etc.)
    //   - tempC: Temperature in Celsius
    // - Returns: Appropriate WeatherAdvice case
    static func advice(for condition: String, tempC: Double) -> WeatherAdvice {
        let lowerCond = condition.lowercased()
        switch lowerCond {
        case "rain", "drizzle":
            return .umbrellaNeeded
        case "thunderstorm":
            return .umbrellaNeeded
        case "snow":
            if tempC < -5 {
                return .veryColdBundleUp
            } else {
                return .chillyWearJacket
            }
        case "clear":
            switch tempC {
            case ..<0:
                return .veryColdBundleUp
            case 0..<15:
                return .chillyWearJacket
            case 15..<25:
                return .perfectForWalk
            default:
                return .hotStayHydrated
            }
        case "clouds":
            switch tempC {
            case ..<5:
                return .chillyWearJacket
            case 5..<20:
                return .perfectForWalk
            default:
                return .hotStayHydrated
            }
        case "windy":
            return .windySecureItems
        default:
            // For other/unrecognized conditions, base advice on temperature
            switch tempC {
            case ..<0:
                return .veryColdBundleUp
            case 0..<10:
                return .chillyWearJacket
            case 10..<25:
                return .perfectForWalk
            case 25...:
                return .hotStayHydrated
            default:
                return .generic
            }
        }
    }
}
