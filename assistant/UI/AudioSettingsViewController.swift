//
//  AudioSettingsViewController.swift
//  assistant
//
//  Created by Gabe Kangas on 4/20/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

@objc protocol AudioSettingsViewControllerDelegate: AnyObject {
    func audioEnableMovieMode()
    func audioEnableMusicMode()
}

class AudioSettingsViewController: UIViewController {
    weak var delegate: AudioSettingsViewControllerDelegate?

    override func viewDidLoad() {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.addSubview(blurView)
        blurView.pinToEdges()

        view.layoutMargins = UIEdgeInsets(top: 50, left: 100, bottom: 70, right: 100)
        blurView.backgroundColor = UIColor.secondaryColor.withAlphaComponent(0.1)

        let row1 = createRow()
        row1.addArrangedSubview(makeButton(title: "Music Mode", selector: #selector(AudioSettingsViewControllerDelegate.audioEnableMusicMode), image: UIImage(named: "frame")))
        row1.addArrangedSubview(makeButton(title: "Movie Mode", selector: #selector(AudioSettingsViewControllerDelegate.audioEnableMovieMode), image: UIImage(named: "frame")))

        view.addSubview(row1)
        row1.centerInSuperview()

        Timer.scheduledTimer(withTimeInterval: 1.0 * 10, repeats: false) { _ in
            self.dismiss(animated: true, completion: nil)
        }
    }

    private func createRow() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 50
        return stackView
    }

    private func makeButton(title: String, selector: Selector, tintColor: UIColor? = nil, image: UIImage? = nil) -> StatusButton {
        let button = StatusButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.heightAnchor.constraint(equalToConstant: 150).isActive = true
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        button.addTarget(delegate, action: selector, for: .touchUpInside)

        if let tintColor = tintColor {
            button.tintColor = tintColor
        }

        button.alpha = 0.8

        return button
    }
}
