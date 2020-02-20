//
//  WhiteNoisePlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/16/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

class WhiteNoisePlugin: Plugin {
    weak var delegate: PluginDelegate?
    
    enum Command: String, CaseIterable {
        case start = "play rain sounds"
        case stop = "stop rain"
    }
    
    private var player: AVAudioPlayer?
    
    var commands: [String] {
        return Command.allCases.map { return $0.rawValue }
    }
    
    required init(delegate: PluginDelegate) {
        self.delegate = delegate
    }
    
    func setVolume(_ volume: Float) {
        player?.setVolume(volume, fadeDuration: 0.6)
    }
    
    func speechDetected(_ speech: String) {
        guard let command = Command(rawValue: speech) else { return }
        
        if command == .start {
            start()
        } else if command == .stop {
            stop()
        }
    }
    
    func start() {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "rain", ofType: "mp3")!)
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()
        } catch {
            print(error)
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
    }
    
}
