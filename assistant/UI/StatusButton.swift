//
//  StatusButton.swift
//  assistant
//
//  Created by Gabe Kangas on 2/29/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

class StatusButton: LayoutableButton {
    init() {
        super.init(frame: .zero)
        imageVerticalAlignment = .center
        imageHorizontalAlignment = .center
        titleEdgeInsets = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        imageEdgeInsets = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
        
        imageView?.tintColor = Constants.itemColor
        
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setTitleColor(Constants.itemColor, for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel?.textAlignment = .center
        
        layer.borderColor = Constants.itemColor.withAlphaComponent(0.7).cgColor
        layer.borderWidth = 2.0
        
        titleLabel?.enableGlow(with: Constants.shadowColor)
        imageView?.enableGlow(with: Constants.shadowColor.withAlphaComponent(0.8))
        imageView?.startFlicker()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = frame.size.width / 2
    }
    
    func set(text: String, iconURL: String) {
        guard let url = URL(string: iconURL) else { return }
        kf.setImage(with: url, for: .normal)
        setTitle(text, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
