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
    
    fileprivate let audioEngine = AVAudioEngine()
    
    fileprivate let sensors = Sensors()
    fileprivate var sensorBrightness: Int?
    
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
        
        statusStackView.addArrangedSubview(doNotDisturbButton)
        statusStackView.addArrangedSubview(dayNightButton)
        statusStackView.addArrangedSubview(goodnightButton)
        
        randomItemsStackView.addArrangedSubview(roomTempLabel)
        
        view.addSubview(statusStackView)
        view.addSubview(randomItemsStackView)
        
        NSLayoutConstraint.activate([
            clockStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -100),
            clockStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clockStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            ampmLabel.topAnchor.constraint(equalTo: timeLabel.topAnchor, constant: 15),
            ampmLabel.leftAnchor.constraint(equalTo: timeLabel.rightAnchor, constant: 10),
            
            statusStackView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 50),
            statusStackView.centerXAnchor.constraint(equalTo: clockStackView.centerXAnchor),
            
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
        
        let pluginButtons = plugins.compactMap({ return $0.actionButton })
        for button in pluginButtons {
            statusStackView.addArrangedSubview(button)
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
        
        let inputNode = audioEngine.inputNode
        let bus = 0
        inputNode.installTap(onBus: bus, bufferSize: 2048, format: inputNode.inputFormat(forBus: bus)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            
            if !self.isInSpeechSession { return }
            
            func scaledPower(power: Float) -> Float {
                let minDb: Float = -40.0
                
                guard power.isFinite else { return 0.0 }
                
                if power < minDb {
                    return 0.0
                } else if power >= 1.0 {
                    return 1.0
                } else {
                    return (abs(minDb) - abs(power)) / abs(minDb)
                }
            }
                        
            guard let channelData = buffer.floatChannelData else { return }
            
            let channelDataValue = channelData.pointee
            let channelDataValueArray = stride(from: 0,
                                               to: Int(buffer.frameLength),
                                               by: buffer.stride).map{ channelDataValue[$0] }
            
            let value = channelDataValueArray.map{ $0 * $0 }.reduce(0, +) / Float(buffer.frameLength)
            let rms = sqrt(value)
            let avgPower = 20 * log10(rms)
            let meterLevel = scaledPower(power: avgPower)
            
            let borderWidth: CGFloat = max(4.0, CGFloat(meterLevel * 80.0))
            DispatchQueue.main.async {
                self.view.layer.borderWidth = borderWidth
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print(error)
        }
        
        let touchRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentPopupMenu))
        view.addGestureRecognizer(touchRecognizer)
        
        DispatchQueue.main.async {
            self.presentPopupMenu()
        }
    }
    
    @objc private func presentPopupMenu() {
        let vc = PopupPanelView()
        vc.delegate = self
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }
    
    fileprivate func handleScreenBrightness() {
        if self.isInSpeechSession || self.isInDayMode { return }
        guard let sensorBrightness = sensorBrightness else { return }
        
        var dimmingAlpha: CGFloat = 0.0
        
        if sensorBrightness < 10 {
            let adjustedBrightness = Double(sensorBrightness) * 1.8
            dimmingAlpha = CGFloat(min(1 - (adjustedBrightness * 0.1), 0.7))
        }
        
        if dimmingAlpha == self.dimmingView.alpha { return }
        
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
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (_) in
            let date = Date()
            self.timeLabel.text = timeFormatter.string(from: date)
            self.dateLabel.text = dateFormatter.string(from: date)
            self.ampmLabel.text = ampmFormatter.string(from: date)
        }
    }
    
    fileprivate func removeActionButtons() {
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
        label.font = UIFont.init(name: "Digital-7", size: 280)
        label.textAlignment = .center
        label.textColor = Constants.itemColor
        label.startFlicker()
        label.enableGlow(with: Constants.shadowColor)
        return label
    }()
    
    private let roomTempLabel: UILabel = {
        let label = UILabel()
        label.isOpaque = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 50)
        label.textAlignment = .center
        label.textColor = Constants.secondaryColor
        label.alpha = 0.5
        label.enableGlow(with: Constants.shadowColor)
        return label
    }()
    
    private let ampmLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.init(name: "Digital-7", size: 70)
        label.textAlignment = .center
        label.textColor = Constants.itemColor
        label.enableGlow(with: Constants.shadowColor)
        label.startFlicker()
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 40, weight: .medium)
        label.textAlignment = .center
        label.textColor = Constants.itemColor
        label.alpha = 0.9
        label.enableGlow(with: Constants.shadowColor)
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
        }) { (_) in
            UIView.animate(withDuration: 1.7) {
                self.statusStackView.alpha = 1.0
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
        self.sensorBrightness = value
        handleScreenBrightness()

        for plugin in plugins {
            plugin.lightingChanged(value: value)
        }
    }
    
    
}

extension MainViewController: PopupPanelDelegate {
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
