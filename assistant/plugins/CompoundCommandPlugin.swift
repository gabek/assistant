//
//  CompoundCommandPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/19/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
protocol CompoundCommandPluginDelegate: class {
    func goodnight()
    func turnOnAllTheThings()
}

class CompoundCommandPlugin: Plugin {
    weak var delegate: PluginDelegate?
    weak var pluginDelegate: CompoundCommandPluginDelegate?
    
    enum Command: String, CaseIterable {
        case goodnight = "goodnight"
        case turnOnTheThings = "turn on all the things"
    }
    
    var commands: [String] {
        return Command.allCases.map { return $0.rawValue }
    }
    
    var actionButton: UIButton? {
        return nil
    }

    required init(delegate: PluginDelegate) {
        self.delegate = delegate
    }
    
    func speechDetected(_ speech: String) {
        guard let command = Command(rawValue: speech) else { return }
        
        if command == .goodnight {
            pluginDelegate?.goodnight()
        } else if command == .turnOnTheThings {
            pluginDelegate?.turnOnAllTheThings()
        }
    }
    
    
}
