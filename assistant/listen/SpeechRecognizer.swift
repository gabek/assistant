//
//  SpeechRecognizer.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import Speech

protocol SpeechRecognizerDelegate: class {
    func speechDetected(_ speech: String)
    func displayResponse(_ speech: String)
    
    func didFinishSpeaking()
}

class SpeechRecognizer: NSObject {
    fileprivate let speechSynthesizer = AVSpeechSynthesizer()
    fileprivate var openEarsEventsObserver = OEEventsObserver()
    
    weak var delegate: SpeechRecognizerDelegate?
    
    var plugins = [Plugin]()
    private var whiteNoisePlugin: WhiteNoisePlugin!
    private var compoundCommandPlugin: CompoundCommandPlugin!
    private var lightingPlugin: LightingPlugin!
    private var canvasPlugin: MeuralCanvasPlugin!
    
    override init() {
        super.init()
        
        whiteNoisePlugin = WhiteNoisePlugin(delegate: self)
        compoundCommandPlugin = CompoundCommandPlugin(delegate: self)
        lightingPlugin = LightingPlugin(delegate: self)
        canvasPlugin = MeuralCanvasPlugin(delegate: self)
        
        speechSynthesizer.delegate = self
        compoundCommandPlugin.pluginDelegate = self
        
        plugins += [
            canvasPlugin,
            WeatherPlugin(delegate: self),
            lightingPlugin,
            TimerPlugin(delegate: self),
            whiteNoisePlugin,
            compoundCommandPlugin
        ]
        setup()
    }
    
    func start() {
        
    }
    
    private func generateSpeechRecognitionModels() -> (lmPath: String, dicPath: String)? {
        let lmGenerator = OELanguageModelGenerator()
        let phrases = plugins.flatMap { return $0.commands }
        let name = "assistant"
        
        let grammar = [ThisWillBeSaidOnce : [
            [ OneOfTheseWillBeSaidOnce : [Constants.prefixPhrase]],
            [ OneOfTheseWillBeSaidOnce : phrases]]
        ]
        
        let err: Error! = lmGenerator.generateGrammar(from: grammar, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
        
        if let err = err {
            fatalError(err.localizedDescription)
        }
        
        guard let lmPath = lmGenerator.pathToSuccessfullyGeneratedGrammar(withRequestedName: name) else { return nil }
        guard let dicPath = lmGenerator.pathToSuccessfullyGeneratedDictionary(withRequestedName: name) else { return nil }
        
        return (lmPath: lmPath, dicPath: dicPath)
    }
    
    func setup() {
        guard let paths = generateSpeechRecognitionModels() else { return }
        
//        OELogging.startOpenEarsLogging()
        
        do {
            try OEPocketsphinxController.sharedInstance().setActive(true) // Setting the shared OEPocketsphinxController active is necessary before any of its properties are accessed.
        } catch {
            print("Error: it wasn't possible to set the shared instance to active: \"\(error)\"")
        }
        openEarsEventsObserver.delegate = self
        OEPocketsphinxController.sharedInstance().disablePreferredBufferSize = true
        OEPocketsphinxController.sharedInstance().startListeningWithLanguageModel(atPath: paths.lmPath, dictionaryAtPath: paths.dicPath, acousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"), languageModelIsJSGF: true)
    }
}

extension SpeechRecognizer: PluginDelegate {
    func commandAcknowledged(_ text: String) {
        delegate?.speechDetected(text)
    }
    
    func speak(_ text: String) {
        
        delegate?.displayResponse(text)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_en-US_compact")
        speechSynthesizer.speak(utterance)
        
        whiteNoisePlugin.setVolume(0.4)
    }
}

extension SpeechRecognizer: OEEventsObserverDelegate {
    func pocketsphinxDidStartListening() {
        print("Listening...")
    }
    
    func pocketsphinxDidDetectSpeech() {
        print("*** Did detect speech")
    }
    
    func pocketsphinxDidDetectFinishedSpeech() {
        print("*** Did finish speech")
    }
    
    func pocketsphinxDidSuspendRecognition() {
        print("*** Did suspend recognition")
    }
    
    func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!) {
        print("*** Speech \(recognitionScore!): \(hypothesis!)")
        
        let removedPrefixPhrase = hypothesis.replacingOccurrences(of: Constants.prefixPhrase, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        for plugin in plugins {
            plugin.speechDetected(removedPrefixPhrase)
        }
    }
    
    func audioSessionInterruptionDidEnd() {
        print("audioSessionInterruptionDidEnd")
    }
    
    func audioSessionInterruptionDidBegin() {
        print("audioSessionInterruptionDidBegin")
    }
    
    func audioRouteDidChange(toRoute newRoute: String!) {
        print(newRoute)
    }
    
    func pocketsphinxFailedNoMicPermissions() {
        print(pocketsphinxFailedNoMicPermissions)
    }
}

extension SpeechRecognizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        delegate?.didFinishSpeaking()
        whiteNoisePlugin.setVolume(1.0)
    }
}

extension SpeechRecognizer: CompoundCommandPluginDelegate {
    func goodnight() {
        lightingPlugin.allLightsOff()
        canvasPlugin.off()
        whiteNoisePlugin.start()
        
        speak("Goodnight!")
    }
    
}
