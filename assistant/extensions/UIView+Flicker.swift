//
//  UIView+Flicker.swift
//  assistant
//
//  Created by Gabe Kangas on 3/14/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

extension UIView {
    struct AssociatedKeys {
        static var timer: UInt8 = 0
    }
    
    private(set) var timer: Timer? {
         get {
             guard let value = objc_getAssociatedObject(self, &AssociatedKeys.timer) as? Timer else {
                 return nil
             }
             return value
         }
         set(newValue) {
             objc_setAssociatedObject(self, &AssociatedKeys.timer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
         }
     }

    
    func startFlicker() {
        let randomInterval = Double(Float.random(in: 6...15))
        timer = Timer.scheduledTimer(timeInterval: randomInterval, target: self, selector: #selector(flicker), userInfo: nil, repeats: false)
    }
    
    @objc private func flicker() {
        let numberOfCycles = Float.random(in: 2...5)
        let animationOptions = UIView.AnimationOptions.autoreverse
        let defaultAlpha = self.alpha
        
        UIView.animate(withDuration: 0.04, delay: 0, options: animationOptions, animations: { () -> Void in
            UIView.setAnimationRepeatCount(numberOfCycles)
            self.alpha = defaultAlpha - 0.14
        }, completion: { (complete) -> Void in
            if complete {
                self.alpha = defaultAlpha
            }
            self.startFlicker()
        })
        
    }
}
