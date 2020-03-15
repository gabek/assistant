//
//  sensors.swift
//  assistant
//
//  Created by Gabe Kangas on 3/14/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

protocol SensorsDelegate: class {
    func internalTempChanged(temp: Int)
    func lightingChanged(value: Int)
}

class Sensors {
    struct Response: Codable {
        var light: Int
        var temp: Int
    }
    
    weak var delegate: SensorsDelegate?
    private let sensorURL = URL(string: "http://192.168.1.20")!
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { (_) in
            self.fetch()
        }
        
        fetch()
    }
    
    private func fetch() {
        URLSession.shared.dataTask(with: sensorURL) { (data, response, error) in
            guard let data = data else { return }

            do {
                let sensors = try ObjectDecoder<Response>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
                self.delegate?.internalTempChanged(temp: sensors.temp)
                self.delegate?.lightingChanged(value: sensors.light)
            } catch {
                print(error)
            }
        }.resume()
    }
}
