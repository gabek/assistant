//
//  PluginProtocol.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

protocol Plugin {
    var delegate: PluginDelegate? { get set }
    var commands: [String] { get }
    init(delegate: PluginDelegate)
    func speechDetected(_ speech: String)
}

protocol PluginDelegate: class {
    func speak(_ text: String)
    func commandAcknowledged(_ text: String)
}
