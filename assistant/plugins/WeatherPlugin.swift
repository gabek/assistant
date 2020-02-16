//
//  WeatherPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/15/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

class WeatherPlugin: Plugin {
    weak var delegate: PluginDelegate?
    
    enum Command: String {
        case current = "what is the weather"
        case forecast = "what is the weather forecast"
    }
    
    required init(delegate: PluginDelegate) {
        self.delegate = delegate
        
        getCurrentWeather()
    }
    
    func speechDetected(_ speech: String) {
        //
    }
    
    private func getCurrentWeather() {
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?zip=94102,us&units=imperial&appid=93ed55d7ec87196fbea338496a481e4e")!
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            do {
                let response = try ObjectDecoder<CurrentWeatherResponse>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
            
                print(response.speechResponse)
            } catch {
                print(error)
            }
        }.resume()
    }
    
    private func getForecast() {
        let url = "https://api.openweathermap.org/data/2.5/forecast?zip=94102,us&units=imperial&appid=93ed55d7ec87196fbea338496a481e4e"
    }
    
    private struct CurrentWeatherResponse: Codable {
        var weather: [Weather]
        var main: Main
        var name: String // Location
        
        struct Weather: Codable {
            var description: String
            var icon: String
        }
        
        struct Main: Codable {
            var temp: Double
            var feelsLike: Double
            var tempMin: Double
            var tempMax: Double
        }
        
        var speechResponse: String {
            return "The weather in \(name) is \(String(describing: weather.first?.description)) with a temperature of \(main.temp) and feels like \(main.feelsLike), with a high of \(main.tempMax) and low of \(main.tempMin) degrees."
        }
    }
}
