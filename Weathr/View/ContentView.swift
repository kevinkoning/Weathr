//
//  ContentView.swift
//  Weathr
//
//  Created by Kief on 08/02/2026.
//

import SwiftUI

struct ContentView: View {
    let fontSize: CGFloat = 60
    let bigFontSize: CGFloat = 120
    @State var weatherData: WeatherData?
    let URLString = "https://api.openweathermap.org/data/2.5/weather?q=s-Hertogenbosch&appid=3b7c0bb2df5778f696d6dfc53b6189c9&units=metric"
    
//    guard let url = URL(string: URLString) else {
//        print("Error: Invalid URL")
//        return
//    }
    
    var body: some View {
        ZStack {
            Image("Lenticular_Cloud")
                .resizable()
                .ignoresSafeArea()
                .aspectRatio(contentMode: .fill)
                
            VStack {
                Spacer()
                Text("Den Bosch")
                    .font(Font.custom("Helvetica Neue UltraLight", size: fontSize))
                Text(getTemperatureString())
                    .font(Font.custom("Helvetica Neue UltraLight", size: bigFontSize))
                Spacer()
                Spacer()
            }
            .padding()
        }
        //.onAppear(perform: loadData)
    }
    
    func getTemperatureString() -> String {
        if let weatherData = weatherData {
            return String(weatherData.main.temp)
        } else {
            return "?"
        }
    }
}

#Preview {
    ContentView()
}
