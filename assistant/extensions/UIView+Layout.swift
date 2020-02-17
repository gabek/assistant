//
//  UIView+Utils.swift
//  thebatplayerios
//
//  Created by Gabe Kangas on 8/6/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func centerInSuperview(offset: CGPoint = .zero) {
        guard let superview = superview else {
            assertionFailure("Must be added to a superview")
            return
        }
        
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: superview.centerXAnchor, constant: offset.x),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor, constant: offset.y),
        ])
    }
    
    func pinToEdges() {
        guard let superview = superview else {
            assertionFailure("Must be added to a superview")
            return
        }
        
        translatesAutoresizingMaskIntoConstraints = false

        topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
    }
    
    func pinToLeftAndRightMargins() {
        guard let superview = superview else {
            assertionFailure("Must be added to a superview")
            return
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        
        leftAnchor.constraint(equalTo: superview.layoutMarginsGuide.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: superview.layoutMarginsGuide.rightAnchor).isActive = true
    }
    
    static func spacerOfHeight(_ height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.backgroundColor = UIColor.clear
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }
}
