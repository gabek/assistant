//
//  MainViewController.swift
//  assistant
//
//  Created by Gabe Kangas on 2/16/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import Kingfisher
import RxSwift

class MainViewController: UIViewController {
    private let disposeBag = DisposeBag()

    private var whiteNoisePlugin: WhiteNoisePlugin!
    private var compoundCommandPlugin: CompoundCommandPlugin!
    private var lightingPlugin: LightingPlugin!
    private var canvasPlugin: MeuralCanvasPlugin!
    private var harmonyHubPlugin: HarmonyHubPlugin!
    fileprivate var plugins = [Plugin]()

    private let speechRecognizer = SpeechRecognizer()
    fileprivate let textToSpeech = TextToSpeech()

    fileprivate let sensors = Sensors()
    fileprivate var sensorBrightness: Int?

    private let wallpapers = [
        "scab-picker.jpg",
        "cold.jpg",
        "moon.jpg",
    ]

    fileprivate var doNotDisturbEnabled = false {
        didSet {
            let title = doNotDisturbEnabled ? "Unmute" : "Mute"
            doNotDisturbButton.setTitle(title, for: .normal)

            let width: CGFloat = doNotDisturbEnabled ? 5.0 : 0.0
            doNotDisturbOutline.layer.borderWidth = width
        }
    }

    private var isInSpeechSession = false
    private var isInDayMode = false {
        didSet {
            dimmingView.alpha = 0.0
            let title = isInDayMode ? "Day" : "Night"
            let imageName = isInDayMode ? "day-mode" : "night-mode"
            let image = UIImage(named: imageName)!
            dayNightButton.setImage(image, for: .normal)
            dayNightButton.setTitle(title, for: .normal)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        view.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.3).cgColor
        view.layer.cornerRadius = 22.0

        speechRecognizer.delegate = self
        sensors.delegate = self

        view.addSubview(wallpaperImageView)
        view.addSubview(clockStackView)
        view.addSubview(ampmLabel)

        clockStackView.addArrangedSubview(timeLabel)
        clockStackView.addArrangedSubview(dateLabel)
        clockStackView.setCustomSpacing(40, after: dateLabel)
        clockStackView.addArrangedSubview(questionLabel)
        clockStackView.addArrangedSubview(answerLabel)

        statusStackView1.addArrangedSubview(doNotDisturbButton)
        statusStackView1.addArrangedSubview(dayNightButton)
        statusStackView1.addArrangedSubview(goodnightButton)

        randomItemsStackView.addArrangedSubview(roomTempLabel)

        view.addSubview(statusStackView1)
        view.addSubview(statusStackView2)
        view.addSubview(randomItemsStackView)

        NSLayoutConstraint.activate([
            clockStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -100),
            clockStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clockStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height * 0.1),
            ampmLabel.topAnchor.constraint(equalTo: timeLabel.topAnchor, constant: 15),
            ampmLabel.leftAnchor.constraint(equalTo: timeLabel.rightAnchor, constant: 10),

            statusStackView1.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 50),
            statusStackView1.centerXAnchor.constraint(equalTo: clockStackView.centerXAnchor),

            statusStackView2.topAnchor.constraint(equalTo: statusStackView1.bottomAnchor, constant: 20),
            statusStackView2.centerXAnchor.constraint(equalTo: clockStackView.centerXAnchor),

            doNotDisturbButton.widthAnchor.constraint(equalToConstant: 110),
            doNotDisturbButton.heightAnchor.constraint(equalToConstant: 110),

            dayNightButton.widthAnchor.constraint(equalToConstant: 110),
            dayNightButton.heightAnchor.constraint(equalToConstant: 110),

            goodnightButton.widthAnchor.constraint(equalToConstant: 110),
            goodnightButton.heightAnchor.constraint(equalToConstant: 110),

            randomItemsStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 40),
            randomItemsStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
        ])

        wallpaperImageView.pinToEdges()

        setupClock()

        DispatchQueue.main.async {
            let window = UIApplication.shared.keyWindow
            window?.addSubview(self.dimmingView)
            self.dimmingView.pinToEdges()
        }

        view.addSubview(doNotDisturbOutline)
        doNotDisturbOutline.pinToEdges()

        whiteNoisePlugin = WhiteNoisePlugin(delegate: self)
        compoundCommandPlugin = CompoundCommandPlugin(delegate: self)
        lightingPlugin = LightingPlugin(delegate: self)
        canvasPlugin = MeuralCanvasPlugin(delegate: self)
        harmonyHubPlugin = HarmonyHubPlugin(delegate: self)
        compoundCommandPlugin.pluginDelegate = self

        plugins = [
            WeatherPlugin(delegate: self),
            canvasPlugin,
            lightingPlugin,
            TimerPlugin(delegate: self),
            whiteNoisePlugin,
            compoundCommandPlugin,
            harmonyHubPlugin,
        ]
        speechRecognizer.setPlugins(plugins)

        let pluginButtons = plugins.compactMap { $0.actionButton }
        for button in pluginButtons {
            if statusStackView1.arrangedSubviews.count > 5 {
                statusStackView2.addArrangedSubview(button)
            } else {
                statusStackView1.addArrangedSubview(button)
            }

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 110),
                button.heightAnchor.constraint(equalToConstant: 110),
            ])
        }

        // Toggle day/night mode via button
        dayNightButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.isInDayMode.toggle()
            self?.handleScreenBrightness()
        }).disposed(by: disposeBag)

        goodnightButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.goodnight()
        }).disposed(by: disposeBag)

        isInDayMode = false
        doNotDisturbEnabled = false

        doNotDisturbButton.addTarget(self, action: #selector(toggleDoNotDisturb), for: .touchUpInside)

        let touchRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentPopupMenu))
        view.addGestureRecognizer(touchRecognizer)

        Timer.scheduledTimer(withTimeInterval: 20 * 60, repeats: true) { _ in
            self.updateWallpaper()
        }
    }

    private func updateWallpaper() {
        guard let wallpaper = wallpapers.randomElement() else { return }
        UIView.transition(with: wallpaperImageView, duration: 3.0, options: .transitionCrossDissolve, animations: {
            self.wallpaperImageView.image = UIImage(named: wallpaper)
        }, completion: nil)
    }

    @objc private func presentPopupMenu() {
        let vc = PopupPanelView()
        vc.delegate = self
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }

    fileprivate func handleScreenBrightness() {
        if isInSpeechSession || isInDayMode { return }
        guard let sensorBrightness = sensorBrightness else { return }

        var dimmingAlpha: CGFloat = 0.0

        if sensorBrightness < 10 {
            let adjustedBrightness = Double(sensorBrightness) * 1.8
            dimmingAlpha = CGFloat(min(1 - (adjustedBrightness * 0.1), 0.7))
        }

        if dimmingAlpha == dimmingView.alpha { return }

        DispatchQueue.main.async {
            self.dimmingView.layer.removeAllAnimations()
            UIView.animate(withDuration: 2.0) {
                self.dimmingView.alpha = dimmingAlpha
            }
        }
    }

    @objc private func toggleDoNotDisturb() {
        doNotDisturbEnabled.toggle()
    }

    private func setupClock() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full

        let ampmFormatter = DateFormatter()
        ampmFormatter.dateFormat = "a"

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let date = Date()
            self.timeLabel.text = timeFormatter.string(from: date)
            self.dateLabel.text = dateFormatter.string(from: date)
            self.ampmLabel.text = ampmFormatter.string(from: date)
        }
    }

    fileprivate func removeActionButtons() {
        UIView.animate(withDuration: 0.2) {
            self.statusStackView1.alpha = 0
            self.statusStackView2.alpha = 0
        }

        UIView.animate(withDuration: 0.4) {
            self.questionLabel.alpha = 1.0
        }

        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            self.didFinishSpeaking()
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

    private let statusStackView1: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 45
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let statusStackView2: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 45
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let randomItemsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 45
        stackView.alignment = .leading
        return stackView
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.isOpaque = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "Digital-7", size: 280)
        label.textAlignment = .center
        label.textColor = UIColor.itemColor
        label.startFlicker()
        label.enableGlow(with: UIColor.shadowColor)
        return label
    }()

    private let roomTempLabel: UILabel = {
        let label = UILabel()
        label.isOpaque = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 50)
        label.textAlignment = .center
        label.textColor = UIColor.secondaryColor
        label.alpha = 0.5
        label.enableGlow(with: UIColor.shadowColor)
        return label
    }()

    private let ampmLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "Digital-7", size: 70)
        label.textAlignment = .center
        label.textColor = UIColor.itemColor
        label.enableGlow(with: UIColor.shadowColor)
        label.startFlicker()
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 40, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.itemColor
        label.alpha = 0.9
        label.enableGlow(with: UIColor.shadowColor)
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
        dimming.alpha = 0.0
        dimming.layer.borderWidth = 5
        dimming.layer.cornerRadius = 22.0
        return dimming
    }()

    fileprivate let doNotDisturbOutline: UIView = {
        let outline = UIView()
        outline.translatesAutoresizingMaskIntoConstraints = false
        outline.backgroundColor = .clear
        outline.isUserInteractionEnabled = false
        outline.alpha = 0.5
        outline.layer.borderWidth = 5
        outline.layer.cornerRadius = 22.0
        outline.layer.borderColor = UIColor.systemRed.cgColor
        return outline
    }()

    fileprivate let doNotDisturbButton: StatusButton = {
        let icon = StatusButton()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setImage(UIImage(named: "mute"), for: .normal)
        icon.setTitle("Mute", for: .normal)
        return icon
    }()

    fileprivate let dayNightButton: StatusButton = {
        let icon = StatusButton()
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()

    fileprivate let goodnightButton: StatusButton = {
        let icon = StatusButton()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setTitle("Sleep", for: .normal)
        icon.setImage(UIImage(named: "sleep"), for: .normal)
        return icon
    }()
}

extension MainViewController: SpeechRecognizerDelegate {
    func speechDetected(_ speech: String) {
        DispatchQueue.main.async {
            self.questionLabel.text = "\"\(speech)\""

            self.removeActionButtons()
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
        whiteNoisePlugin.setVolume(1.0)

        UIView.animate(withDuration: 2.5, animations: {
            self.questionLabel.alpha = 0
            self.answerLabel.alpha = 0
        }) { _ in
            UIView.animate(withDuration: 1.7) {
                self.statusStackView1.alpha = 1.0
                self.statusStackView2.alpha = 1.0
            }
            self.isInSpeechSession = false
            self.view.layer.borderWidth = 0.0
        }
    }
}

extension MainViewController: PluginDelegate {
    func commandAcknowledged(_ text: String) {
        speechDetected(text)
    }

    func speak(_ text: String) {
        DispatchQueue.main.async {
            self.removeActionButtons()
        }

        displayResponse(text)
        whiteNoisePlugin.setVolume(0.4)
        if !doNotDisturbEnabled {
            textToSpeech.speak(text)
        }
    }
}

extension MainViewController: CompoundCommandPluginDelegate {
    func turnOnAllTheThings() {
        lightingPlugin.allLightsOn()
        canvasPlugin.on()
    }

    func goodnight() {
        UIView.transition(with: wallpaperImageView, duration: 1.0, options: .transitionCrossDissolve, animations: {
            self.wallpaperImageView.alpha = 0.5
        }, completion: nil)

        harmonyHubPlugin.turnOffTV()
        lightingPlugin.allLightsOff()
        canvasPlugin.off()
        whiteNoisePlugin.start()

        speak("Goodnight!")
    }
}

extension MainViewController: SensorsDelegate {
    func internalTempChanged(temp: Int) {
        roomTempLabel.text = "\(temp)F"
    }

    func lightingChanged(value: Int) {
        sensorBrightness = value
        handleScreenBrightness()

        for plugin in plugins {
            plugin.lightingChanged(value: value)
        }

        if wallpaperImageView.alpha != 1.0 {
            UIView.transition(with: wallpaperImageView, duration: 1.0, options: .transitionCrossDissolve, animations: {
                self.wallpaperImageView.alpha = 1.0
            }, completion: nil)
        }
    }
}

extension MainViewController: PopupPanelDelegate {
    func nextPainting() {
        canvasPlugin.next()
    }

    func prevPainting() {
        canvasPlugin.previous()
    }

    func dimLights() {
        lightingPlugin.changeBrightness(percent: -10)
    }

    func brightenLights() {
        lightingPlugin.changeBrightness(percent: 10)
    }

    func lightsPurple() {
        lightingPlugin.enableScene(.purple)
    }

    func lightsRelax() {
        lightingPlugin.enableScene(.relax)
    }

    func lightsSunset() {
        lightingPlugin.enableScene(.sunset)
    }

    func lightsConcentrate() {
        lightingPlugin.enableScene(.concentrate)
    }

    func lightsBright() {
        lightingPlugin.enableScene(.bright)
    }

    func turnOffMeural() {
        canvasPlugin.off()
    }

    func turnOnMeural() {
        canvasPlugin.on()
    }

    func turnOffTV() {
        harmonyHubPlugin.turnOffTV()
    }

    func turnOnTV() {
        harmonyHubPlugin.turnOnTV()
    }
}
