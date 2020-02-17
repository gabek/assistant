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
        layer.shadowOffset = .zero//CGSize(width: 1, height: 1) //.zero
        layer.shadowRadius = 10.0
        layer.shadowColor = color.cgColor
    }
}
