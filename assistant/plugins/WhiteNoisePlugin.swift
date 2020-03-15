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
    
    private var isSoundPlaying = false {
        didSet {
            let title = isSoundPlaying ? "Stop" : "Start"
            noiseButton.setTitle(title, for: .normal)
        }
    }
    
    private var player: AVAudioPlayer?
    
    var commands: [String] {
        return Command.allCases.map { return $0.rawValue }
    }
    
    var actionButton: UIButton? {
        return noiseButton
    }

    fileprivate let noiseButton: StatusButton = {
        let icon = StatusButton()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setTitle("Start", for: .normal)
        return icon
    }()

    required init(delegate: PluginDelegate) {
        self.delegate = delegate
        
        noiseButton.addTarget(self, action: #selector(toggleSound), for: .touchUpInside)
    }
    
    @objc private func toggleSound() {
        if isSoundPlaying {
            stop()
        } else {
            start()
        }
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
        
        isSoundPlaying = true
    }
    
    func stop() {
        player?.stop()
        player = nil
        isSoundPlaying = false
    }
    
    func internalTempChanged(temp: Int) {
        //
    }
    
    func lightingChanged(value: Int) {
        //
    }
}
