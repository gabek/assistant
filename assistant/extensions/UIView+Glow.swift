//
//  UIView+Glow.swift
//  assistant
//
//  Created by Gabe Kangas on 2/16/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

extension UIView {
    func enableGlow(with color: UIColor) {
        layer.shadowOpacity = 1.0
        layer.shadowOffset = .zero
        layer.shadowRadius = 10.0
        layer.shadowColor = color.cgColor
        
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 1.0
        animation.toValue = 0.7
        animation.repeatCount = .infinity
        animation.duration = 1.0
        animation.autoreverses = true
        animation.isRemovedOnCompletion = true
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        layer.add(animation, forKey: "glowViewPulseAnimation")
        
        let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        radiusAnimation.fromValue = 10.0
        radiusAnimation.toValue = 16.0
        radiusAnimation.repeatCount = .infinity
        radiusAnimation.duration = 2.5
        radiusAnimation.autoreverses = true
        radiusAnimation.isRemovedOnCompletion = true
        radiusAnimation.fillMode = CAMediaTimingFillMode.forwards
        radiusAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        layer.add(radiusAnimation, forKey: "glowViewPulseRadiusAnimation")
    }
}
