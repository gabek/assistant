//
//  HarmonyHub.swift
//  assistant
//
//  Created by Gabe Kangas on 3/1/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import Starscream

class HarmonyHubPlugin: Plugin {
    enum Command: String, CaseIterable {
        case turnOffTV = "turn off the TV"
        case turnOnTV = "turn on the TV"
    }
    
    enum Constants: String, RawRepresentable {
        case hubIP = "192.168.1.3"
        case hubPort = "8088"
        case hubPath = "?domain=svcs.myharmony.com&hubId=3888326"
        
        enum LGTV: String {
            case DeviceID = "37912042"
            case PowerOffCommand = "PowerOff"
            case PowerOnCommand = "PowerOn"
        }
        
        enum AppleTV: String {
            case DeviceID = "14355481"
            case HomeCommand = "Home"
        }
    }
    
    weak var delegate: PluginDelegate?
    
    var commands: [String] {
       return Command.allCases.map { return $0.rawValue }
    }
    
    var actionButton: UIButton?
    var messageID = 0
    
    fileprivate var isConnected = false
    private var socket: WebSocket!
    
    required init(delegate: PluginDelegate) {
        self.delegate = delegate
        
        setup()
    }
    
    func turnOffTV() {
        send(deviceID: Constants.LGTV.DeviceID.rawValue, button: Constants.LGTV.PowerOffCommand.rawValue)
    }
    
    func turnOnTV() {
        send(deviceID: Constants.LGTV.DeviceID.rawValue, button: Constants.LGTV.PowerOnCommand.rawValue)
        send(deviceID: Constants.AppleTV.DeviceID.rawValue, button: Constants.AppleTV.HomeCommand.rawValue)
    }
    
    private func send(deviceID: String, button: String) {
        let timestamp = String(Int(Date().timeIntervalSinceReferenceDate))
        print(messageID, button, timestamp)

        let payload: [String : Any] = ["hbus": [ "cmd": "vnd.logitech.harmony/vnd.logitech.harmony.engine?holdAction", "id": "\(messageID)", "params": [ "status": "press", "timestamp": timestamp, "verb": "render", "action": "{\"command\":\"\(button)\",\"type\":\"IRCommand\",\"deviceId\":\"\(deviceID)\"}"]]]
        send(payload: payload)
    }
    
    private func send(payload: [String : Any]) {
        let data = try! JSONSerialization.data(withJSONObject: payload, options: [])
        self.socket.write(data: data)
        messageID += 1
    }
    
    func setup() {
        var request = URLRequest(url: URL(string: "ws://\(Constants.hubIP.rawValue):\(Constants.hubPort.rawValue)/\(Constants.hubPath.rawValue)")!)
        request.setValue("http://sl.dhg.myharmony.com", forHTTPHeaderField: "Origin")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("utf-8", forHTTPHeaderField: "Accept-Charset")
        
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    
    fileprivate func schedulePing() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { (_) in
            self.ping()
        }
    }
    
    private func ping() {
        let payload: [String : Any] = ["hbus": [ "cmd": "vnd.logitech.connect/vnd.logitech.pingvnd.logitech.ping", "id": "\(messageID)"]]
        send(payload: payload)
    }
    
    func speechDetected(_ speech: String) {
        guard let command = Command(rawValue: speech) else { return }
        
        if command == .turnOnTV {
            turnOnTV()
        } else if command == .turnOffTV {
            turnOffTV()
        }
    }
    

    
}

extension HarmonyHubPlugin: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
            schedulePing()
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viablityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
            print(error)
        }
    }
}
