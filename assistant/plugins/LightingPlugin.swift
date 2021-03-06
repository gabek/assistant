//
//  LightingPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/16/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

class LightingPlugin: Plugin {
    enum Command: String, CaseIterable {
        case on = "turn on all the lights"
        case off = "turn off all the lights"

        case brighten10 = "brighten lights by ten percent"
        case brighten20 = "brighten lights by twenty percent"
        case brighten30 = "brighten lights by thirty percent"
        case brighten40 = "brighten lights by fourty percent"
        case brighten50 = "brighten lights by fifty percent"
        case brighten60 = "brighten lights by sixty percent"
        case brighten70 = "brighten lights by seventy percent"
        case brighten80 = "brighten lights by eighty percent"
        case brighten90 = "brighten lights by ninty percent"
        case brighten100 = "brighten lights by one hundred percent"

        case dim10 = "dim lights by ten percent"
        case dim20 = "dim lights by twenty percent"
        case dim30 = "dim lights by thirty percent"
        case dim40 = "dim lights by fourty percent"
        case dim50 = "dim lights by fifty percent"
        case dim60 = "dim lights by sixty percent"
        case dim70 = "dim lights by seventy percent"
        case dim80 = "dim lights by eighty percent"
        case dim90 = "dim lights by ninty percent"
        case dim100 = "dim lights by one hundred percent"
    }

    enum LightingScene: String {
        case purple = "KG-Qb103ctGIbvO"
        case relax = "t0ZIPksrsH8gUn6"
        case bright = "ti4qcX2M6Vbkr07"
        case concentrate = "z81PTtGic0PSA5A"
        case sunset = "CzgmUmHLnpYN1jb"
    }

    weak var delegate: PluginDelegate?

    var commands: [String] {
        return Command.allCases.map { return $0.rawValue }
    }

    var actionButton: UIButton? {
        return toggleButton
    }

    private let toggleButton: UIButton = {
        let button = StatusButton()
        button.setImage(UIImage(named: "lightbulb"), for: .normal)
        return button
    }()

    private let username = "EgXXcP6A9XHyYHEi1i4M0BNd0RZn48eqvFMqmym0"

    private var lightsAreOn = false {
        didSet {
            let title = lightsAreOn ? "All Off" : "All On"
            toggleButton.setTitle(title, for: .normal)
        }
    }

    required init(delegate: PluginDelegate) {
        self.delegate = delegate

        toggleButton.addTarget(self, action: #selector(toggleLights), for: .touchUpInside)
        checkLightsStatus()

        Timer.scheduledTimer(withTimeInterval: 1.0 * 60, repeats: true) { _ in
            self.checkLightsStatus()
        }
    }

    private func checkLightsStatus() {
        getGroup(0) { group in
            DispatchQueue.main.async {
                self.lightsAreOn = group.state.allOn
            }
        }
    }

    @objc private func toggleLights() {
        if lightsAreOn {
            allLightsOff()
        } else {
            allLightsOn()
        }
    }

    func speechDetected(_ speech: String) {
        guard let command = Command(rawValue: speech) else { return }

        delegate?.commandAcknowledged(speech)

        switch command {
        case .on:
            allLightsOn()
        case .off:
            allLightsOff()
        case .brighten10:
            changeBrightness(percent: 10)
        case .brighten20:
            changeBrightness(percent: 20)
        case .brighten30:
            changeBrightness(percent: 30)
        case .brighten40:
            changeBrightness(percent: 40)
        case .brighten50:
            changeBrightness(percent: 50)
        case .brighten60:
            changeBrightness(percent: 60)
        case .brighten70:
            changeBrightness(percent: 70)
        case .brighten80:
            changeBrightness(percent: 80)
        case .brighten90:
            changeBrightness(percent: 90)
        case .brighten100:
            changeBrightness(percent: 100)
        case .dim10:
            changeBrightness(percent: -10)
        case .dim20:
            changeBrightness(percent: -20)
        case .dim30:
            changeBrightness(percent: -30)
        case .dim40:
            changeBrightness(percent: -40)
        case .dim50:
            changeBrightness(percent: -50)
        case .dim60:
            changeBrightness(percent: -60)
        case .dim70:
            changeBrightness(percent: -70)
        case .dim80:
            changeBrightness(percent: -80)
        case .dim90:
            changeBrightness(percent: -90)
        case .dim100:
            changeBrightness(percent: -100)
        }
    }

    @objc func allLightsOn() {
        sendSimpleCommand("/groups/0/action", command: "{\"on\":true}")
        lightsAreOn = true
    }

    @objc func allLightsOff() {
        sendSimpleCommand("/groups/0/action", command: "{\"on\":false}")
        lightsAreOn = false
    }

    func changeBrightness(percent: Double) {
        let offset = Int(254 * (percent * 0.01))
        sendSimpleCommand("/groups/0/action", command: "{\"bri_inc\":\(offset)}")
    }

    private func sendSimpleCommand(_ path: String, command: String) {
        let url = Constants.Hosts.hueHub.appendingPathComponent("/api/\(username)").appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")

        request.httpBody = command.data(using: .utf8, allowLossyConversion: true)

        URLSession.shared.dataTask(with: request) { _, _, _ in
//            print(response)
//            print(error)
        }.resume()
    }

    private func getGroup(_ groupNumber: Int, completion: @escaping (Group) -> Void) {
        let url = Constants.Hosts.hueHub.appendingPathComponent("/api/\(username)").appendingPathComponent("/groups/\(groupNumber)/")

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else { return }
            do {
                let group = try ObjectDecoder<Group>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
                completion(group)
            } catch {
                print(error)
            }
        }.resume()
    }

    func enableScene(_ scene: LightingScene, groupNumber: Int? = 0) {
        let url = Constants.Hosts.hueHub.appendingPathComponent("/api/\(username)").appendingPathComponent("/groups/\(groupNumber ?? 0)/action")

        let sceneRequest = GroupScene(scene: scene.rawValue)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = sceneRequest.data

        URLSession.shared.dataTask(with: request) { _, _, _ in
//            print(response)
//            print(error)
        }.resume()
    }

    func internalTempChanged(temp _: Int) {
        //
    }

    func lightingChanged(value _: Int) {
        //
    }

    private struct Group: Codable {
        struct Action: Codable {
            var bri: Int
        }

        struct State: Codable {
            var allOn: Bool
            var anyOn: Bool
        }

        var state: State
        var action: Action
    }

    private struct GroupScene: Codable {
        var scene: String
    }
}
