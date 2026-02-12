//
//  ContentView.swift
//  Weathr
//
//  Created by Kief on 08/02/2026.
//

import SwiftUI

struct ContentView: View {

    let fontSize: CGFloat = 50
    let bigFontSize: CGFloat = 120
    @State var weatherData: WeatherData?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var lastUpdated: Date?
    @State private var lastRequestedURL: String?
    @State private var lastResponseBody: String?
    @State private var temperatureDisplay: String = "?"
    @State private var city: String = "s-Hertogenbosch"
    private let apiKey = "3b7c0bb2df5778f696d6dfc53b6189c9"
 
    var body: some View {
        ZStack {
            Image("Lenticular_Cloud")
                .resizable()
                .ignoresSafeArea()
                .aspectRatio(contentMode: .fill)
                
            VStack {
                // City input row
                HStack {
                    TextField("Enter city", text: $city, onCommit: {
                        loadData(for: city)
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .font(.system(size: 14))
                    .frame(maxWidth: 220)
                    .submitLabel(.search)
                    .onSubmit { loadData(for: city) }

                    Button(action: { loadData(for: city) }) {
                        Text("Search")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                    }
                    .disabled(isLoading)
                }
                .padding([.horizontal, .top])
                if let err = errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                        .padding(.horizontal)
                }
                Spacer()
                Text(weatherData?.name ?? city)
                    .font(Font.custom("Helvetica Neue UltraLight", size: fontSize))
                if isLoading {
                    Text("Loading...")
                        .font(.system(size: 18))
                } else {
                    Text(temperatureDisplay)
                        .font(Font.custom("Helvetica Neue UltraLight", size: bigFontSize))
                }
                 Spacer()
                 Spacer()
             }
             .padding()
         }
         .onAppear { loadData(for: city) }
         
     }
    
    
    
    func getTemperatureString() -> String {
        if let weatherData = weatherData {
            let temp = weatherData.main.temp
            return String(format: "%.0f°C", temp)
        } else {
            return "?"
        }
    }

    // Fetch weather data from OpenWeatherMap and decode into WeatherData
    func loadData(for city: String) {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("Empty city; nothing to load")
            return
        }

        // Build the URL safely using URLComponents to ensure correct encoding
        let ts = Int(Date().timeIntervalSince1970)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.openweathermap.org"
        components.path = "/data/2.5/weather"
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "_", value: String(ts)) // cache-busting
        ]

        guard let url = components.url else {
            print("Error: failed to build URL from components: \(components)")
            return
        }

        // Use a request that ignores local caches to force fresh server responses
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30

        Task {
            // Clear previous data and show loading indicator and remember the requested URL
            await MainActor.run {
                self.weatherData = nil
                self.temperatureDisplay = "?"
                self.errorMessage = nil
                self.isLoading = true
                self.lastRequestedURL = url.absoluteString
            }
            print("Requesting URL: \(url.absoluteString)")
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                // Capture raw response on background thread
                let responseBody = String(data: data, encoding: .utf8)
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(WeatherData.self, from: data)

                // Update UI state on main actor (assign all @State here)
                await MainActor.run {
                    self.lastResponseBody = responseBody
                    self.weatherData = decoded
                    self.temperatureDisplay = String(format: "%.0f°C", decoded.main.temp)
                    self.lastUpdated = Date()
                    self.isLoading = false
                }
            } catch {
                // Ensure loading flag is cleared and show error
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                }
                print("Network or decoding error: \(error)")
                // Optionally try to print the response body for debugging
                if let (responseData, _) = try? await URLSession.shared.data(for: request),
                   let str = String(data: responseData, encoding: .utf8) {
                    print("Response body: \(str)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
