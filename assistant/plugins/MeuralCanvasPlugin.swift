//
//  MeuralCanvasPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class MeuralCanvasPlugin: Plugin {
    enum MeuralCanvasAPIError: Error {
        case urlError
        case apiResponseError
    }

    let disposeBag = DisposeBag()

    private var backlight = 0

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
        case setBrightness = "remote/control_command/set_backlight"
        case setPlaylist = "/remote/control_command/change_gallery"
    }

    private enum Playlists: String, CaseIterable {
        case art = "135814"
        case photography = "135817"
        case bands = "135855"
        case starWars = "135861"
        case flyers = "139850"

        var ttl: TimeInterval {
            switch self {
            case .art:
                return 30
            case .photography:
                return 20
            default:
                return 10
            }
        }
    }

    weak var delegate: PluginDelegate?

    var actionButton: UIButton? {
        return nil
    }

    private var playlistIndex: Int = 0
    private var scheduledNextItemTimer: Timer?
    required init(delegate: PluginDelegate) {
        self.delegate = delegate

        // Every minute check to see what playlist we're on
        // and how long the current image has been displayed.
        // Depending on the playlist move to the next item
        // if needed.
        Timer.scheduledTimer(withTimeInterval: 1.0 * 60, repeats: true) { _ in
            self.handleAutomaticNextItem()
        }

        // Every N minutes to change to the next playlist/gallery
        Timer.scheduledTimer(withTimeInterval: Constants.Time.meuralCanvasPlaylistRotationInterval, repeats: true) { _ in
            var nextPlaylistIndex: Int = self.playlistIndex + 1
            if nextPlaylistIndex > Playlists.allCases.count - 1 {
                nextPlaylistIndex = 0
            }
            self.playlistIndex = nextPlaylistIndex
            self.setPlaylist(id: Playlists.allCases[nextPlaylistIndex].rawValue)
        }
    }

    private var trackedCurrentItem: (item: String, time: Date)?
    private func handleAutomaticNextItem() {
        getCurrentStatus().subscribe(onNext: { item in
            guard let playlist = Playlists(rawValue: item.response.currentGallery) else { return }

            if let trackedCurrentItem = self.trackedCurrentItem, trackedCurrentItem.item == item.response.currentItem, Date().timeIntervalSince(trackedCurrentItem.time) > playlist.ttl {
                self.next()
                return
            } else if self.trackedCurrentItem?.item != item.response.currentItem {
                self.trackedCurrentItem = (item.response.currentItem, Date())
                return
            }

        }, onError: { error in
            print(error)
         }).disposed(by: disposeBag)
    }

    func speechDetected(_ speech: String) {
        guard let command = Command(rawValue: speech) else { return }

        delegate?.commandAcknowledged(speech)

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

    func on() {
        sendSimpleCommand(.on)
    }

    func off() {
        sendSimpleCommand(.off)
    }

    func next() {
        sendSimpleCommand(.next)
    }

    func previous() {
        sendSimpleCommand(.previous)
    }

    func setPlaylist(id: String) {
        let url = Constants.Hosts.meuralCanvas.appendingPathComponent(APIRequest.setPlaylist.rawValue).appendingPathComponent(id)
        URLSession.shared.dataTask(with: url).resume()
    }

    private func setBacklight(value: Int) {
        let backlightBrightness = min(max(10, value * 3), 80)

        var adjustedBacklightBrightness = backlightBrightness
        let brightnessDelta = backlightBrightness - backlight

        if brightnessDelta == 0 { return }

        // Try to limit the amount of change each time.
        if abs(brightnessDelta) < 3 { return }
        if backlight != 0, abs(brightnessDelta) < 6 {
            adjustedBacklightBrightness = backlight + (brightnessDelta / 2)
        }

        if adjustedBacklightBrightness == backlight { return }
        print("\(backlight) -> \(adjustedBacklightBrightness)")

        backlight = adjustedBacklightBrightness

        let url = Constants.Hosts.meuralCanvas.appendingPathComponent(APIRequest.setBrightness.rawValue).appendingPathComponent(String(adjustedBacklightBrightness))
        URLSession.shared.dataTask(with: url).resume()
    }

    private func getCurrentStatus() -> Observable<CurrentStatusResponse> {
        return Observable.create { observer -> Disposable in
            let currentItemURL = Constants.Hosts.meuralCanvas.appendingPathComponent("/remote/get_gallery_status_json")

            let task = URLSession.shared.dataTask(with: currentItemURL) { data, _, error in
                do {
                    guard let data = data else {
                        observer.onError(MeuralCanvasAPIError.apiResponseError)
                        return
                    }

                    let apiResponse = try ObjectDecoder<CurrentStatusResponse>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
                    observer.onNext(apiResponse)
                } catch {
                    observer.onError(error)
                }
            }
            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func getItem(id: String, playlistID: String) -> Observable<PlaylistResponse.Item> {
        return Observable.create { observer -> Disposable in

            let playlistRequestURL = Constants.Hosts.meuralCanvas.appendingPathComponent("/remote/get_frame_items_by_gallery_json/").appendingPathComponent(playlistID)

            let task = URLSession.shared.dataTask(with: playlistRequestURL) { data, _, error in
                do {
                    guard let data = data else {
                        observer.onError(MeuralCanvasAPIError.apiResponseError)
                        return
                    }

                    let playlistResponse = try ObjectDecoder<PlaylistResponse>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
                    let items = playlistResponse.response
                    guard let item = items.first(where: { (singleItem) -> Bool in
                        singleItem.id == id
                    }) else {
                        observer.onError(MeuralCanvasAPIError.urlError)
                        return // Disposables.create()
                    }

                    observer.onNext(item)
                } catch {
                    observer.onError(error)
                }
            }

            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func whatIsShowing() {
        // Display the item detail UI on the canvas
        sendSimpleCommand(.captions)

        // 1. Get the current item ID and playlist ID
        getCurrentStatus().flatMap { result in
            // 2. Get the playlist by ID, and find the item in it
            self.getItem(id: result.response.currentItem, playlistID: result.response.currentGallery)
        }.subscribe(onNext: { item in
            print(item)
            self.delegate?.speak(item.speechResponse)
        }, onError: { error in
            print(error)
        }).disposed(by: disposeBag)
    }

    private func sendSimpleCommand(_ command: APIRequest) {
        let url = Constants.Hosts.meuralCanvas.appendingPathComponent(command.rawValue)
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
        var response: [Item]

        struct Item: Codable {
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

    func internalTempChanged(temp _: Int) {
        //
    }

    func lightingChanged(value: Int) {
        setBacklight(value: value)
    }
}
