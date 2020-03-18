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

    struct Devices {
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

    var delegate: PluginDelegate?

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
        send(deviceID: Devices.LGTV.DeviceID.rawValue, button: Devices.LGTV.PowerOffCommand.rawValue)
    }

    func turnOnTV() {
        send(deviceID: Devices.LGTV.DeviceID.rawValue, button: Devices.LGTV.PowerOnCommand.rawValue)
        send(deviceID: Devices.AppleTV.DeviceID.rawValue, button: Devices.AppleTV.HomeCommand.rawValue)
    }

    private func send(deviceID: String, button: String) {
        let timestamp = String(Int(Date().timeIntervalSinceReferenceDate))
        print(messageID, button, timestamp)

        let payload: [String: Any] = ["hbus": ["cmd": "vnd.logitech.harmony/vnd.logitech.harmony.engine?holdAction", "id": "\(messageID)", "params": ["status": "press", "timestamp": timestamp, "verb": "render", "action": "{\"command\":\"\(button)\",\"type\":\"IRCommand\",\"deviceId\":\"\(deviceID)\"}"]]]
        send(payload: payload)
    }

    private func send(payload: [String: Any]) {
        let data = try! JSONSerialization.data(withJSONObject: payload, options: [])
        socket.write(data: data)
        messageID += 1
    }

    func setup() {
        let queryItems = [
            URLQueryItem(name: "domain", value: "svcs.myharmony.com"),
            URLQueryItem(name: "hubId", value: "3888326"),
        ]

        guard var url = URLComponents(url: Constants.Hosts.harmonyHub.appendingPathComponent("/"), resolvingAgainstBaseURL: false) else { return }
        url.queryItems = queryItems

        var request = URLRequest(url: url.url!)
        request.setValue("http://sl.dhg.myharmony.com", forHTTPHeaderField: "Origin")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("utf-8", forHTTPHeaderField: "Accept-Charset")

        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }

    fileprivate func schedulePing() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.ping()
        }
    }

    private func ping() {
        let payload: [String: Any] = ["hbus": ["cmd": "vnd.logitech.connect/vnd.logitech.pingvnd.logitech.ping", "id": "\(messageID)"]]
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
    func didReceive(event: WebSocketEvent, client _: WebSocket) {
        switch event {
        case let .connected(headers):
            isConnected = true
            print("websocket is connected: \(headers)")
            schedulePing()
        case let .disconnected(reason, code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case let .text(string):
            print("Received text: \(string)")
        case let .binary(data):
            print("Received data: \(data.count)")
        case .ping:
            break
        case .pong:
            break
        case .viablityChanged:
            break
        case .reconnectSuggested:
            break
        case .cancelled:
            isConnected = false
        case let .error(error):
            isConnected = false
            print(error)
            setup()
        }
    }

    func internalTempChanged(temp _: Int) {
        //
    }

    func lightingChanged(value _: Int) {
        //
    }
}
