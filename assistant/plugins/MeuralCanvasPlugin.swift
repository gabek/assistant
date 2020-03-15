//
//  MeuralCanvasPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

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
    }
    
    weak var delegate: PluginDelegate?
    
    private let canvasURL = "http://192.168.1.32"
    
    var actionButton: UIButton? {
        return nil
    }

    required init(delegate: PluginDelegate) {
        self.delegate = delegate        
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
    
    private func next() {
        sendSimpleCommand(.next)
    }
    
    private func previous() {
        sendSimpleCommand(.previous)
    }
    
    private func setBacklight(value: Int) {
        let backlightBrightness = min(max(10, value * 3), 80)

        var adjustedBacklightBrightness = backlightBrightness
        let brightnessDelta = backlightBrightness - backlight

        if brightnessDelta == 0 { return }

        // Try to limit the amount of change each time.
        if abs(brightnessDelta) < 3 { return }
        if backlight != 0 && abs(brightnessDelta) < 6 {
            adjustedBacklightBrightness = backlight + (brightnessDelta / 2)
        }
        
        if adjustedBacklightBrightness == backlight { return }
        print("\(backlight) -> \(adjustedBacklightBrightness)")

        backlight = adjustedBacklightBrightness

        guard let url = URL(string: self.canvasURL)?.appendingPathComponent(APIRequest.setBrightness.rawValue).appendingPathComponent(String(adjustedBacklightBrightness)) else { return }
        URLSession.shared.dataTask(with: url).resume()
    }
    
    private func getCurrentStatus() -> Observable<CurrentStatusResponse> {
        return Observable.create { observer -> Disposable in
            guard let currentItemURL = URL(string: self.canvasURL)?.appendingPathComponent("/remote/get_gallery_status_json") else {
                observer.onError(MeuralCanvasAPIError.urlError)
                return Disposables.create()
            }
            
            let task = URLSession.shared.dataTask(with: currentItemURL) { (data, response, error) in
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
            
            guard let playlistRequestURL = URL(string: self.canvasURL)?.appendingPathComponent("/remote/get_frame_items_by_gallery_json/").appendingPathComponent(playlistID) else {
                observer.onError(MeuralCanvasAPIError.urlError)
                return Disposables.create()
            }
            
            let task = URLSession.shared.dataTask(with: playlistRequestURL) { (data, response, error) in
                do {
                    guard let data = data else {
                        observer.onError(MeuralCanvasAPIError.apiResponseError)
                        return
                    }
                    
                    let playlistResponse = try ObjectDecoder<PlaylistResponse>().getObjectFrom(jsonData: data, decodingStrategy: .convertFromSnakeCase)
                    let items = playlistResponse.response
                    guard let item = items.first(where: { (singleItem) -> Bool in
                        return singleItem.id == id
                    }) else {
                        observer.onError(MeuralCanvasAPIError.urlError)
                        return //Disposables.create()
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
        }.subscribe(onNext: { (item) in
            print(item)
            self.delegate?.speak(item.speechResponse)
        }, onError: { (error) in
            print(error)
        }).disposed(by: disposeBag)
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
    
    func internalTempChanged(temp: Int) {
        //
    }
    
    func lightingChanged(value: Int) {
        setBacklight(value: value)
    }
}
