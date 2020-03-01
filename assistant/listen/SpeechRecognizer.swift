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
    fileprivate var openEarsEventsObserver = OEEventsObserver()
    
    weak var delegate: SpeechRecognizerDelegate?
    
    var plugins = [Plugin]()
    
    func setPlugins(_ plugins: [Plugin]) {
        self.plugins = plugins
        setup()
    }
    
    private func generateSpeechRecognitionModels() -> (lmPath: String, dicPath: String)? {
        let lmGenerator = OELanguageModelGenerator()
        let phrases = plugins.flatMap { return $0.commands }
        let name = "assistant"
        
        let grammar = [ThisWillBeSaidOnce : [
            [OneOfTheseWillBeSaidOnce: [Constants.prefixPhrase]],
            [OneOfTheseWillBeSaidOnce: phrases]]
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
    
    func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!) {
        print("*** Speech \(recognitionScore!): \(hypothesis!)")
        
        let removedPrefixPhrase = hypothesis.replacingOccurrences(of: Constants.prefixPhrase, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        for plugin in plugins {
            plugin.speechDetected(removedPrefixPhrase)
        }
    }
    
    func pocketsphinxFailedNoMicPermissions() {
        print(pocketsphinxFailedNoMicPermissions)
    }
}




