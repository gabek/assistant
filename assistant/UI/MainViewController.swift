//
//  MainViewController.swift
//  assistant
//
//  Created by Gabe Kangas on 2/16/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import Kingfisher

class MainViewController: UIViewController {
    private let speechRecognizer = SpeechRecognizer()
    private let weatherFetcher = WeatherFetcher()
    
    private var isInSpeechSession = false
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        speechRecognizer.delegate = self
                
        view.addSubview(wallpaperImageView)
        view.addSubview(clockStackView)
        view.addSubview(ampmLabel)
        
        clockStackView.addArrangedSubview(timeLabel)
        clockStackView.addArrangedSubview(dateLabel)
        clockStackView.setCustomSpacing(40, after: dateLabel)
        clockStackView.addArrangedSubview(questionLabel)
        clockStackView.addArrangedSubview(answerLabel)

        statusStackView.addArrangedSubview(weatherIcon)
        statusStackView.addArrangedSubview(doNotDisturbIcon)
        
        view.addSubview(statusStackView)
        
        NSLayoutConstraint.activate([
            clockStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -100),
            clockStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clockStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            ampmLabel.topAnchor.constraint(equalTo: timeLabel.topAnchor, constant: 15),
            ampmLabel.leftAnchor.constraint(equalTo: timeLabel.rightAnchor, constant: 10),
            
            statusStackView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 50),
            statusStackView.centerXAnchor.constraint(equalTo: clockStackView.centerXAnchor),
            
            weatherIcon.widthAnchor.constraint(equalToConstant: 110),
            weatherIcon.heightAnchor.constraint(equalToConstant: 110),
            
            doNotDisturbIcon.widthAnchor.constraint(equalToConstant: 110),
            doNotDisturbIcon.heightAnchor.constraint(equalToConstant: 110),

        ])
        
        wallpaperImageView.pinToEdges()

        setupClock()
        
        view.addSubview(dimmingView)
        dimmingView.pinToEdges()
        
//        for family in UIFont.familyNames.sorted() {
//            let names = UIFont.fontNames(forFamilyName: family)
//            print("Family: \(family) Font names: \(names)")
//        }
        
        speechRecognizer.start()
        
        weatherFetcher.start { (weather) in
            guard let weather = weather else { return }
            self.weatherIcon.set(text: "\(Int(weather.temp))F", iconURL: weather.icon)
        }

        // Check every n seconds to adjust the screen brightness
        // based on the display brightness so it's not so blinding
        // in the dark.
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (_) in
            if self.isInSpeechSession { return }
            
            let dimmingAlpha = min(1.0 - (UIScreen.main.brightness * 2.6), 0.6)
            if dimmingAlpha == self.dimmingView.alpha { return }
            
            DispatchQueue.main.async {
                self.dimmingView.layer.removeAllAnimations()
                UIView.animate(withDuration: 2.0) {
                    self.dimmingView.alpha = dimmingAlpha
                }
            }
        }
    }
    
    private func setupClock() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        
        let ampmFormatter = DateFormatter()
        ampmFormatter.dateFormat = "a"

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (_) in
            let date = Date()
            self.timeLabel.text = timeFormatter.string(from: date)
            self.dateLabel.text = dateFormatter.string(from: date)
            self.ampmLabel.text = ampmFormatter.string(from: date)
        }
    }
    
    private let clockStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.alignment = .center
        return stackView
    }()
    
    private let statusStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 45
        stackView.alignment = .center
        return stackView
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.isOpaque = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.init(name: "Digital-7", size: 280)
        label.textAlignment = .center
        label.textColor = Constants.itemColor
        label.enableGlow(with: Constants.itemColor)
        return label
    }()
    
    private let ampmLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.init(name: "Digital-7", size: 70)
        label.textAlignment = .center
        label.textColor = Constants.itemColor
        label.enableGlow(with: Constants.itemColor)
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 40, weight: .medium)
        label.textAlignment = .center
        label.textColor = Constants.itemColor
        label.enableGlow(with: Constants.itemColor)
        return label
    }()
    
    fileprivate let questionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.italicSystemFont(ofSize: 30)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.alpha = 0
        label.textColor = .white
        return label
    }()
    
    fileprivate let answerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 40, weight: .light)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 3
        label.alpha = 0
        label.textColor = .white
        return label
    }()
    
    fileprivate let wallpaperImageView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "scab-picker.jpg"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    fileprivate let dimmingView: UIView = {
        let dimming = UIView()
        dimming.translatesAutoresizingMaskIntoConstraints = false
        dimming.backgroundColor = .black
        dimming.isUserInteractionEnabled = false
        return dimming
    }()
    
    fileprivate let weatherIcon: StatusButton = {
        let icon = StatusButton()
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
    
    fileprivate let doNotDisturbIcon: StatusButton = {
        let icon = StatusButton()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setImage(UIImage(named: "mute"), for: .normal)
        icon.setTitle("Mute", for: .normal)
        return icon
    }()
    
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
            
            titleLabel?.enableGlow(with: Constants.itemColor)
            imageView?.enableGlow(with: Constants.itemColor.withAlphaComponent(0.6))
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
}

extension MainViewController: SpeechRecognizerDelegate {
    func speechDetected(_ speech: String) {
        DispatchQueue.main.async {
            self.questionLabel.text = "\"\(speech)\""

            UIView.animate(withDuration: 0.2) {
                self.statusStackView.alpha = 0
            }
            
            UIView.animate(withDuration: 0.4) {
                self.questionLabel.alpha = 1.0
            }
            
            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { (_) in
                self.didFinishSpeaking()
            }
        }
    }
    
    func displayResponse(_ speech: String) {
        DispatchQueue.main.async {
            self.answerLabel.text = speech
            self.isInSpeechSession = true
            
            UIView.animate(withDuration: 0.4) {
                self.answerLabel.alpha = 1.0
                self.dimmingView.alpha = self.dimmingView.alpha * 0.5
            }
        }
    }
    
    func didFinishSpeaking() {
        UIView.animate(withDuration: 2.5, animations: {
            self.questionLabel.alpha = 0
            self.answerLabel.alpha = 0
        }) { (_) in
            UIView.animate(withDuration: 1.7) {
                self.statusStackView.alpha = 1.0
            }
            self.isInSpeechSession = false
        }
    }
}
