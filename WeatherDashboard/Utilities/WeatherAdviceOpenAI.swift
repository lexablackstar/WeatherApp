//
//  WeatherAdviceOpenAI.swift
//  WeatherDashboard
//
// OpenAI integration for AI-generated weather advice
// Provides contextual, personalized recommendations using GPT-3.5
import Foundation

class WeatherAdviceOpenAI {
    // MARK: - OpenAI API key and URL
    // This is a security risk - API key must NEVER be put in the code - to be removed after the demo
    private let apiKey: String = ""
    private let urlBase: String = "https://api.openai.com/v1/chat/completions"
    
    // MARK: - Public Methods
    
    // Requests weather advice from OpenAI based on current conditions
    //
    // - Parameters:
    //   - location: Location name for context
    //   - temperature: Temperature in Celsius
    //   - humidity: Humidity percentage (0-100)
    //   - windSpeed: Wind speed in km/h
    // - Returns: AI-generated advice string
    // - Throws: WeatherAdviceError for various failure scenarios
    func getWeatherAdvice(location: String, temperature: Double, humidity: Int, windSpeed: Double) async throws -> String {
        let prompt = createPrompt(location: location, temperature: temperature, humidity: humidity, windSpeed: windSpeed)
        return try await requestAdvice(prompt: prompt)
    }
    
    // MARK: - Private Methods
    
    // Constructs the prompt sent to OpenAI
    // Includes weather data and instructions for the AI
    //
    // - Parameters:
    //   - location: Location name
    //   - temperature: Temperature in Celsius
    //   - humidity: Humidity percentage
    //   - windSpeed: Wind speed in km/h
    // - Returns: Complete prompt string for AI
    private func createPrompt(location: String, temperature: Double, humidity: Int, windSpeed: Double) -> String {
        var prompt: String = """
            Based on the following weather conditions in \(location), provide brief practical and funny advice for someone going outside:
            - Temperature: \(temperature)°C
            - Humidity: \(humidity)%
            - Wind Speed: \(windSpeed) km/h
            Mention if it's inline with normal weather conditions for this period of the year.
        """
    
        // In case the method is called without providing weather conditions, let OpenAI decide
        if temperature == 0.0 && humidity == 0 && windSpeed == 0.0 {
            prompt = """
            Provide a brief practical and funny advice for someone going outside in \(location), taking into account that there is no weather data available. 
            """
        }

        prompt = prompt + "Give concise advice about clothing, activities, and any precautions to take. Limit to maximum 50 words."
        
        return prompt
    }
    
    // Makes HTTP request to OpenAI API
    // Handles request construction, error handling, and response parsing
    //
    // - Parameter prompt: The prompt to send to OpenAI
    // - Returns: AI-generated advice text
    // - Throws: WeatherAdviceError for various failure scenarios
    private func requestAdvice(prompt: String) async throws -> String {
        
        // STEP1: Verify URL
        guard let url = URL(string: urlBase) else {
            throw WeatherAdviceError.invalidURL
        }
        
        // STEP 2: Configure HTTP Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // STEP 3: Build request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",               /// "gpt-3.5-turbo" used for cost effective
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 150,                      /// 150 tokens means ~ 100-120 words.
            "temperature": 0.7
        ]
        
        // STEP 4: Serialize request body to JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // STEP 5: Execute HTTP request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // STEP 6: Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherAdviceError.invalidResponse
        }
        
        /// Check for successful response (status code range 200 - 299)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherAdviceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // STEP 7: Parse JSON response
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Extract advice text from nested JSON structure
        guard let choices = jsonResponse?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw WeatherAdviceError.parsingError
        }
        
        // STEP 8: Return result
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Error Handling
enum WeatherAdviceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .parsingError:
            return "Failed to parse response"
        }
    }
}

