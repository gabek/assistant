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
    private let weatherFetcher = WeatherFetcher()

    enum Command: String, CaseIterable {
        case current = "what is the weather"
        case forecast = "what is the weather forecast"
    }
    
    required init(delegate: PluginDelegate) {
        self.delegate = delegate
        
        weatherFetcher.start { (weather) in
            guard let weather = weather else { return }
            self.weatherButton.set(text: "\(Int(weather.temp))F", iconURL: weather.icon)
        }
        
        weatherButton.addTarget(self, action: #selector(getCurrentWeather), for: .touchUpInside)
    }
    
    var commands: [String] {
       return Command.allCases.map { return $0.rawValue }
    }
    
    var actionButton: UIButton? {
        return weatherButton
    }

    fileprivate let weatherButton: StatusButton = {
        let icon = StatusButton()
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
    
    func speechDetected(_ speech: String) {
        guard let command = Command(rawValue: speech) else { return }
        
        delegate?.commandAcknowledged(speech)
        
        if command == .current {
            getCurrentWeather()
        }
    }
    
    @objc private func getCurrentWeather() {
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?zip=94102,us&units=imperial&appid=93ed55d7ec87196fbea338496a481e4e")!
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            do {
                let response = try ObjectDecoder<CurrentWeatherResponse>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
                self.delegate?.speak(response.speechResponse)
                print(response.speechResponse)
            } catch {
                print(error)
            }
        }.resume()
    }
    
    private func getForecast() {
//        let url = "https://api.openweathermap.org/data/2.5/forecast?zip=94102,us&units=imperial&appid=93ed55d7ec87196fbea338496a481e4e"
    }
    
    func internalTempChanged(temp: Int) {
        //
    }
    
    func lightingChanged(value: Int) {
        //
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
