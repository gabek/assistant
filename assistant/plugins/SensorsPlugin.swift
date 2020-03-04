//
//  SensorsPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 3/3/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import SwiftSocket

protocol SensorsPluginDelegate: class {
    func lightValueChanged(value: Double)
}

class SensorsPlugin: Plugin {
    enum Constants: String {
        case host = "x.x.x.x"
        case ReadData = "{\"command\":\"ReadData\"}"
    }
    
    weak var delegate: PluginDelegate?
    weak var sensorsDelegate: SensorsPluginDelegate?
    
    var commands = [String]()
    
    var actionButton: UIButton?
    
    required init(delegate: PluginDelegate) {
        self.delegate = delegate

        Timer.scheduledTimer(withTimeInterval: 0.5 * 60, repeats: true) { (_) in
            if self.sensorsDelegate == nil { return }
            
            self.reportLightValue()
        }
    }
    
    func speechDetected(_ speech: String) {
        //
    }
    
    func reportLightValue() {
        connect { (client) in
            do {
                let response = try self.readSensors(client: client)
                guard let lightValue = response?.lightVal else { return }
                self.sensorsDelegate?.lightValueChanged(value: lightValue)
            } catch {
                print(error)
            }
        }
    }
    
    func test() {
        connect { (client) in
            do {
                let response = try self.readSensors(client: client)
                print(response)
            } catch {
                print(error)
            }
        }
    }
    
    func readSensors(client: TCPClient) throws -> SensorResponse? {
        switch client.send(string: Constants.ReadData.rawValue ) {
        case .success:
            guard let data = client.read(1024*10) else { return nil }
            
            if let response = String(bytes: data, encoding: .utf8) {
                let sensorResponse = try ObjectDecoder<SensorResponse>().getObjectFrom(jsonString: response)
                return sensorResponse
            }
        case .failure(let error):
            print(error)
        }
        return nil
    }
    
    func connect(completion: @escaping (TCPClient) -> Void) {
        let client = TCPClient(address: Constants.host.rawValue, port: 5001)
        switch client.connect(timeout: 10) {
        case .success:
            completion(client)
            
        case .failure(let error):
            print(error)
        }
    }
}

struct SensorResponse : Codable {
    let createdAt: String?
    let tempVal: Double?
    let humiVal: Int?
    let lightVal: Double?
    let powerVolVal: Double?
    let ssid: String?
    let rssi: Int?
    let acceXval: Int?
    let acceYval: Int?
    let acceZval: Int?
    let magVal: Int?
    let extTempVal: Int?
}
