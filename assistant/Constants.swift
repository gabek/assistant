//
//  Constants.swift
//  assistant
//
//  Created by Gabe Kangas on 2/16/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

struct Constants {
    struct Strings {
        static let prefixPhrase = "hey computer"
    }

    struct Hosts {
        static let senorServer = URL(string: "http://192.168.1.9")!
        static let meuralCanvas = URL(string: "http://192.168.1.32")!
        static let hueHub = URL(string: "http://192.168.1.2")!
        static let harmonyHub = URL(string: "ws://192.168.1.7:8088")!
    }
}

extension UIColor {
    static let itemColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
    static let secondaryColor = UIColor(red: 0.4, green: 1.0, blue: 0.5, alpha: 1.0)
    static let shadowColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
}
