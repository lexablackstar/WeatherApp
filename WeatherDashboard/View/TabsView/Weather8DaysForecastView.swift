//
//  Weather8DaysForecastView.swift
//  WeatherDashboard
//
// Displays 8-day weather forecast with interactive bar chart
// This is Tab 2 - Shows daily forecasts with high/low temperatures
import SwiftUI
import Charts

struct Weather8DaysForecastView: View {
    
    @EnvironmentObject var viewModel: WeatherViewModel                  /// Access to shared weather view model
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: Background
            // Full-screen gradient background (blue to red fade)
            GradientBackground(color1: Color.blue.opacity(0.8), color2: Color.green.opacity(0.8))
            
            VStack(spacing: 5) {
                // MARK: - Title
                Text("8-Day Forecast - \(viewModel.currentLocationName)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal,10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text ("Daily Highs and Lows (°C)")
                    .padding(.horizontal,10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                // MARK: - Chart and List Section
                if !viewModel.dailyForecasts.isEmpty {
                    
                    ForecastChart(forecasts: viewModel.dailyForecasts)
                        .frame(height: 250)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.horizontal)
                        
                    
                    List(viewModel.dailyForecasts, id: \.dt) { day in
                        DailyForecastRow(day: day)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden) // Hide default list background
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.white.opacity(0.1))
                            .shadow(color: .black.opacity(1.0), radius: 10, x: 0, y: 5)
                    )
                    .padding(.top, 23)  // 20 points space from chart
                    .padding(.horizontal)  // Same horizontal padding as chart
                } else {
                    Text("No forecast data available.")
                        .foregroundColor(.white)
                }
            }
        }
        
    }
}

// MARK: - ForecastChart Component
// Bar chart visualization of 8-day temperature forecast
// Shows high and low temperatures as grouped bars for each day
struct ForecastChart: View {
    let forecasts: [DailyForecast]
    
    var body: some View {
        VStack{
            Chart {
                ForEach(forecasts, id: \.dt) { day in
                    // Low Temperature Bar
                    BarMark(
                        x: .value("Day", day.dt, unit: .day),
                        y: .value("Low Temp", day.temp.min)
                    )
                    .foregroundStyle(Color.red.opacity(0.7))
                    .position(by: .value("Type", "High"))
                    
                    // High Temperature Bar
                    BarMark(
                        x: .value("Day", day.dt, unit: .day),
                        y: .value("High Temp", day.temp.max)
                    )
                    .foregroundStyle(Color.orange.opacity(0.8))
                    .position(by: .value("Type", "Low"))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            Divider()
            HStack{
                Text("Detailed Daily Summary")
                    .multilineTextAlignment(.leading)
                    .padding(5)
                    .fontWeight(.bold)
                Spacer()
                
            }
        }
    }
}

// MARK: - DailyForecastRow Component
// Individual row in the forecast list
// Shows date, weather condition, temperatures, and safety advisory
struct DailyForecastRow: View {
    let day: DailyForecast
    
    // Generate advice based on condition and temperature
    // WeatherAdvice appears to be a utility for safety messages
    var advisoryText: String? {
            guard let condition = day.weather.first else { return nil }
        return WeatherAdvice.advice(for: condition.main, tempC: day.temp.min).message
        }
    
    var body: some View {
        VStack (alignment: .leading) {
            Text(day.dt, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .frame(alignment: .leading)
                .foregroundColor(Color.black)
                .fontWeight(.bold)
            
            if let advisory = advisoryText {
                Text(advisory)
                    .font(.footnote)
                    .foregroundColor(Color.black.opacity(0.6))
                    .frame(width: 300, alignment: .leading)
            }
            // High/Low Temperature
            Text("Low: \(Int(day.temp.min))° High: \(Int(day.temp.max))°")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(Color.black)
    
            
        }
        .foregroundColor(.white)
    }
}
