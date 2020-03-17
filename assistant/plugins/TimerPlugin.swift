//
//  TimerPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/14/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

class TimerPlugin: Plugin {
    var commands: [String] {
        return Command.allCases.map { return $0.rawValue }
    }

    weak var delegate: PluginDelegate?

    private var timers = [TimerInstance]()

    enum Command: String, CaseIterable {
        case start = "start timer"
    }

    var actionButton: UIButton? {
        return nil
    }

    required init(delegate: PluginDelegate) {
        self.delegate = delegate
    }

    func speechDetected(_: String) {
        // guard let command = Command(rawValue: speech) else { return }
    }

    private func startTimer() {
        let duration: TimeInterval = 10.0

        let timer = TimerInstance()
        timer.startTimer(duration: duration) { timer in
            print(timer.id)
            print(timer.name)
        }

        timers.append(timer)
    }

    class TimerInstance {
        var id: String = UUID().uuidString
        var name: String = "Test name"
        private var timer: Timer?

        func startTimer(duration: TimeInterval, block: @escaping (TimerInstance) -> Void) {
            timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { _ in
                block(self)
            })
        }
    }

    func internalTempChanged(temp _: Int) {
        //
    }

    func lightingChanged(value _: Int) {
        //
    }
}
