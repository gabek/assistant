//
//  HomeKitPlugin.swift
//  assistant
//
//  Created by Gabe Kangas on 2/19/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import HomeKit

class HomeKitPlugin: NSObject, Plugin {
    enum Command: String, CaseIterable {
        case goodnight = "goodnight"
        case turnOnTheThings = "turn on all the things"
    }
    
    weak var delegate: PluginDelegate?

    private let browser = HMAccessoryBrowser()
    private let homeManager = HMHomeManager()
    
    var commands: [String] {
        return Command.allCases.map { return $0.rawValue }
    }
    
    var actionButton: UIButton? {
        return nil
    }

    required init(delegate: PluginDelegate) {
        super.init()
        
        self.delegate = delegate
        
        browser.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.browser.startSearchingForNewAccessories()
        }
        
        homeManager.delegate = self
    }
    
    func speechDetected(_ speech: String) {
//        guard let command = Command(rawValue: speech) else { return }

    }
    
    func internalTempChanged(temp: Int) {
        //
    }
    
    func lightingChanged(value: Int) {
        //
    }
}

extension HomeKitPlugin: HMAccessoryBrowserDelegate {
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        print(accessory)
    }
}

extension HomeKitPlugin: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        let home = manager.homes.first!
        print(home)
        
        let actions = home.actionSets
        let accessories = home.accessories
        
        print(actions)
        print(accessories)
    }
}
