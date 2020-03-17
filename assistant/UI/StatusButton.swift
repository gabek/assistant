//
//  StatusButton.swift
//  assistant
//
//  Created by Gabe Kangas on 2/29/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import Kingfisher

class StatusButton: LayoutableButton {
    override var tintColor: UIColor! {
        get {
            return super.tintColor
        }

        set {
            imageView?.tintColor = newValue
            setTitleColor(newValue, for: .normal)
            layer.borderColor = newValue.withAlphaComponent(0.7).cgColor

            super.tintColor = newValue
        }
    }

    init() {
        super.init(frame: .zero)
        imageVerticalAlignment = .center
        imageHorizontalAlignment = .center
        titleEdgeInsets = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        imageEdgeInsets = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)

        tintColor = UIColor.itemColor

        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel?.textAlignment = .center

        layer.borderWidth = 2.0

        titleLabel?.enableGlow(with: UIColor.shadowColor)
        imageView?.enableGlow(with: UIColor.shadowColor.withAlphaComponent(0.8))
        imageView?.startFlicker()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.size.width / 2
    }

    func set(text: String, iconURL: String) {
        guard let url = URL(string: iconURL) else { return }

        let imageModifier = AnyImageModifier { (image) -> KFCrossPlatformImage in
            image.withRenderingMode(.alwaysTemplate)
        }

        kf.setImage(with: url, for: .normal, placeholder: nil, options: [KingfisherOptionsInfoItem.imageModifier(imageModifier)])
        setTitle(text, for: .normal)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
