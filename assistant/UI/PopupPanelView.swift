//
//  PopupPanelView.swift
//  assistant
//
//  Created by Gabe Kangas on 3/15/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

@objc protocol PopupPanelDelegate: class {
    @objc func turnOffMeural()
    @objc func turnOnMeural()
    @objc func turnOffTV()
    @objc func turnOnTV()
    
    @objc func lightsPurple()
    @objc func lightsRelax()
    @objc func lightsSunset()
    @objc func lightsConcentrate()
    @objc func lightsBright()
    @objc func dimLights()
    @objc func brightenLights()
    @objc func nextPainting()
    @objc func prevPainting()
}

class PopupPanelView: UIViewController {
    weak var delegate: PopupPanelDelegate?

    override func viewDidLoad() {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.addSubview(blurView)
        blurView.pinToEdges()
        
        view.layoutMargins = UIEdgeInsets(top: 50, left: 100, bottom: 70, right: 100)
        blurView.backgroundColor = Constants.secondaryColor.withAlphaComponent(0.1)
        
        let row1 = createRow()
        row1.addArrangedSubview(makeButton(title: "Prev", selector: #selector(PopupPanelDelegate.prevPainting), image: UIImage(named: "previous")))
        row1.addArrangedSubview(makeButton(title: "Canvas Off", selector: #selector(PopupPanelDelegate.turnOffMeural), image: UIImage(named: "frame")))
        row1.addArrangedSubview(makeButton(title: "Canvas On", selector: #selector(PopupPanelDelegate.turnOnMeural), image: UIImage(named: "frame")))
        row1.addArrangedSubview(makeButton(title: "Next", selector: #selector(PopupPanelDelegate.nextPainting), image: UIImage(named: "next")))

        view.addSubview(row1)
        row1.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        row1.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        
        let row2 = createRow()
        row2.addArrangedSubview(makeButton(title: "Turn on TV", selector: #selector(PopupPanelDelegate.turnOnTV), image: UIImage(named: "appletv")))
        row2.addArrangedSubview(makeButton(title: "Turn off TV", selector: #selector(PopupPanelDelegate.turnOffTV), image: UIImage(named: "appletv")))
        view.addSubview(row2)
        row2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        row2.topAnchor.constraint(equalTo: row1.bottomAnchor, constant: 30).isActive = true

        let row3 = createRow()
        row3.addArrangedSubview(makeButton(title: "Purple", selector: #selector(PopupPanelDelegate.lightsPurple), tintColor: .systemPurple, image: UIImage(named: "lightbulb")))
        row3.addArrangedSubview(makeButton(title: "Sunset", selector: #selector(PopupPanelDelegate.lightsSunset), tintColor: .systemRed, image: UIImage(named: "lightbulb")))
        row3.addArrangedSubview(makeButton(title: "Relax", selector: #selector(PopupPanelDelegate.lightsRelax), tintColor: UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0), image: UIImage(named: "lightbulb")))
        row3.addArrangedSubview(makeButton(title: "Concentrate", selector: #selector(PopupPanelDelegate.lightsConcentrate), tintColor: .white, image: UIImage(named: "lightbulb")))
        row3.addArrangedSubview(makeButton(title: "Bright", selector: #selector(PopupPanelDelegate.lightsBright), tintColor: UIColor(red: 1.0, green: 1.0, blue: 0.3, alpha: 1.0), image: UIImage(named: "lightbulb")))
        view.addSubview(row3)
        row3.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        row3.topAnchor.constraint(equalTo: row2.bottomAnchor, constant: 30).isActive = true

        let row4 = createRow()
        row4.addArrangedSubview(makeButton(title: "Brighten", selector: #selector(PopupPanelDelegate.brightenLights), image: UIImage(named: "lightbulb")))
        row4.addArrangedSubview(makeButton(title: "Dim", selector: #selector(PopupPanelDelegate.dimLights), image: UIImage(named: "lightbulb")))
        view.addSubview(row4)
        row4.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        row4.topAnchor.constraint(equalTo: row3.bottomAnchor, constant: 30).isActive = true

        
        Timer.scheduledTimer(withTimeInterval: 1.0 * 10, repeats: false) { (_) in
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
