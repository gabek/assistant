//
//  WeatherFetcher.swift
//  assistant
//
//  Created by Gabe Kangas on 2/16/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

class WeatherFetcher {
    struct WeatherResponse {
        var temp: Double
        var icon: String
    }
    
    func start(completion: @escaping (WeatherResponse?) -> Void) {
        getCurrentWeather(completion: completion)
        Timer.scheduledTimer(withTimeInterval: 1.0 * 60, repeats: true) { (_) in
            self.getCurrentWeather(completion: completion)
        }
    }
    
    private func getCurrentWeather(completion: @escaping (WeatherResponse?) -> Void) {
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?zip=94102,us&units=imperial&appid=93ed55d7ec87196fbea338496a481e4e")!
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            do {
                let response = try ObjectDecoder<CurrentWeatherResponse>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
                guard let icon = response.weather.first?.icon else { return }
                let iconURL = "https://openweathermap.org/img/wn/\(icon)@2x.png"
                let weatherResponse = WeatherResponse(temp: response.main.temp, icon: iconURL)
                DispatchQueue.main.async {
                    completion(weatherResponse)
                }
            } catch {
                print(error)
            }
        }.resume()
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
            guard let currentDescription = weather.first?.description else { return "" }
            
            // Right now in SF it's 59F with partly sunny.  Today foreccast has X with a hhigh of X and low of X.
            return "Right now in \(name) it's \(Int(main.temp)) degrees with \(currentDescription). Today's forecast has a high of \(Int(main.tempMax)) and low of \(Int(main.tempMin)) degrees."
        }
    }
}
