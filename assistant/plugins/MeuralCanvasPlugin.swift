//
//  MeuralCanvasPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

class MeuralCanvasPlugin: Plugin {
    var commands: [String] {
      return Command.allCases.map { return $0.rawValue }
    }
  
    enum Command: String, CaseIterable {
        case whatIsShowing = "what painting is showing"
        case next = "next painting"
        case previous = "previous painting"
        case on = "turn on the canvas"
        case off = "turn off the canvas"
    }

    enum APIRequest: String {
        case on = "remote/control_command/resume"
        case off = "remote/control_command/suspend"
        case next = "remote/control_command/set_key/right"
        case previous = "remote/control_command/set_key/left"
        case captions = "remote/control_command/set_key/caption"
    }

    weak var delegate: PluginDelegate?

    private let canvasURL = "http://192.168.1.32"

  
    required init(delegate: PluginDelegate) {
        self.delegate = delegate
    }

    func speechDetected(_ speech: String) {
        guard let command = Command(rawValue: speech) else { return }

        if command == .whatIsShowing {
            whatIsShowing()
        } else if command == .on {
            on()
        } else if command == .off {
            off()
        } else if command == .next {
            next()
        } else if command == .previous {
            previous()
        }
    }

    private func on() {
        sendSimpleCommand(.on)
    }

    private func off() {
        sendSimpleCommand(.off)
    }

    private func next() {
        sendSimpleCommand(.next)
    }

    private func previous() {
        sendSimpleCommand(.previous)
    }

    private func whatIsShowing() {
        guard let currentItemURL = URL(string: canvasURL)?.appendingPathComponent("/remote/get_gallery_status_json") else { return }

        URLSession.shared.dataTask(with: currentItemURL) { (data, response, error) in
            guard let data = data else { return }

            let response = try? ObjectDecoder<CurrentStatusResponse>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
            guard let currentItemID = response?.response.currentItem else { return }
            guard let galleryID = response?.response.currentGallery else { return }

            guard let playlistRequestURL = URL(string: self.canvasURL)?.appendingPathComponent("/remote/get_frame_items_by_gallery_json/").appendingPathComponent(galleryID) else { return }
            URLSession.shared.dataTask(with: playlistRequestURL) { (data, response, error) in
                guard let data = data else { return }
                guard let response = try? ObjectDecoder<PlaylistResponse>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase) else { return }
                let items = response.response
                guard let item = items.first(where: { (singleItem) -> Bool in
                    return singleItem.id == currentItemID
                }) else { return }

                print(item)
                self.delegate?.speak(item.speechResponse)
            }.resume()

        }.resume()

        // Display the item detail on the canvas
        sendSimpleCommand(.captions)
    }

    private func sendSimpleCommand(_ command: APIRequest) {
        guard let url = URL(string: self.canvasURL)?.appendingPathComponent(command.rawValue) else { return }
        URLSession.shared.dataTask(with: url).resume()
    }

    private struct CurrentStatusResponse: Codable {
        var status: String
        var response: Response

        struct Response: Codable {
            var currentGallery: String
            var currentItem: String
            var currentGalleryName: String
        }
    }

    private struct PlaylistResponse: Codable {
        var status: String
        var response: [Response]

        struct Response: Codable {
            var id: String
            var author: String?
            var title: String?
            var year: String?
            var medium: String?
            var description: String?

            var speechResponse: String {
                var string = ""
                if let title = title {
                    string += title + " "
                }

                if let author = author {
                    string += ", by \(author). "
                }

                if let year = year, year != "" {
                    string += "Created in \(year). "
                }

                if let medium = medium, medium != "" {
                    string += "\(medium). "
                }

                return string
            }
        }
    }
}
