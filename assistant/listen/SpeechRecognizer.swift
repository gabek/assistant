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
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
        
        plugins += [
            MeuralCanvasPlugin(delegate: self),
            WeatherPlugin(delegate: self),
            LightingPlugin(delegate: self),
            TimerPlugin(delegate: self),
        ]
        setup()
    }
    
    func start() {
        
    }
    
    private func generateSpeechRecognitionModels() -> (lmPath: String, dicPath: String)? {
        let lmGenerator = OELanguageModelGenerator()
        let phrases = plugins.flatMap { return $0.commands }
        let name = "assistant"
        
        let allowedPhrases = ["OneOfTheseWillBeSaidOnce": phrases]
        let grammar = ["OneOfTheseWillBeSaidOnce": allowedPhrases]
        
//        let err: Error! = lmGenerator.generateGrammar(from: grammar, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
        let err: Error! = lmGenerator.generateLanguageModel(from: phrases, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
        
        if let err = err {
            fatalError(err.localizedDescription)
        }
        
        guard let lmPath = lmGenerator.pathToSuccessfullyGeneratedLanguageModel(withRequestedName: name) else { return nil }
        guard let dicPath = lmGenerator.pathToSuccessfullyGeneratedDictionary(withRequestedName: name) else { return nil }
        
        return (lmPath: lmPath, dicPath: dicPath)
    }
    
    func setup() {
        guard let paths = generateSpeechRecognitionModels() else { return }
        
        do {
            try OEPocketsphinxController.sharedInstance().setActive(true) // Setting the shared OEPocketsphinxController active is necessary before any of its properties are accessed.
        } catch {
            print("Error: it wasn't possible to set the shared instance to active: \"\(error)\"")
        }
        
        OEPocketsphinxController.sharedInstance().startListeningWithLanguageModel(atPath: paths.lmPath, dictionaryAtPath: paths.dicPath, acousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"), languageModelIsJSGF: false)
        openEarsEventsObserver.delegate = self
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
        
        for plugin in plugins {
            plugin.speechDetected(hypothesis)
        }
    }
}

extension SpeechRecognizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        delegate?.didFinishSpeaking()
    }
}
