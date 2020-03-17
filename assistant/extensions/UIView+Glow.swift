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
        animation.duration = Double.random(in: 1.0 ... 2.0)
        animation.autoreverses = true
        animation.isRemovedOnCompletion = true
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        layer.add(animation, forKey: "glowViewPulseAnimation")

        let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        radiusAnimation.fromValue = 10.0
        radiusAnimation.toValue = 16.0
        radiusAnimation.repeatCount = .infinity
        radiusAnimation.duration = Double.random(in: 2.0 ... 3.0)
        radiusAnimation.autoreverses = true
        radiusAnimation.isRemovedOnCompletion = true
        radiusAnimation.fillMode = CAMediaTimingFillMode.forwards
        radiusAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        layer.add(radiusAnimation, forKey: "glowViewPulseRadiusAnimation")

        let alphaAnimation = CABasicAnimation(keyPath: "alpha")
        alphaAnimation.fromValue = alpha
        alphaAnimation.toValue = alpha - 0.4
        alphaAnimation.repeatCount = .infinity
        alphaAnimation.duration = Double.random(in: 5.0 ... 6.0)
        alphaAnimation.autoreverses = true
        alphaAnimation.isRemovedOnCompletion = true
        alphaAnimation.fillMode = CAMediaTimingFillMode.forwards
        alphaAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        layer.add(alphaAnimation, forKey: "alphaAnimation")
    }
}
