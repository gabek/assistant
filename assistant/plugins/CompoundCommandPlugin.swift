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
}

class CompoundCommandPlugin: Plugin {
    weak var delegate: PluginDelegate?
    weak var pluginDelegate: CompoundCommandPluginDelegate?
    
    enum Command: String, CaseIterable {
        case goodnight = "goodnight"
    }
    
    var commands: [String] {
        return Command.allCases.map { return $0.rawValue }
    }
    
    required init(delegate: PluginDelegate) {
        self.delegate = delegate
    }
    
    func speechDetected(_ speech: String) {
        guard let command = Command(rawValue: speech) else { return }
        
        if command == .goodnight {
            pluginDelegate?.goodnight()
        }
    }
    
    
}
