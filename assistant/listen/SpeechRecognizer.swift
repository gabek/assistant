//
//  SpeechRecognizer.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import Speech

class SpeechRecognizer: NSObject {
    fileprivate let speechSynthesizer = AVSpeechSynthesizer()
    fileprivate var openEarsEventsObserver = OEEventsObserver()

    var plugins = [Plugin]()

  override init() {
    super.init()
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

    let err: Error! = lmGenerator.generateGrammar(from: grammar, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
//    let err: Error! = lmGenerator.generateLanguageModel(from: phrases, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))

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

    private func speechDetected(_ speech: String) {
        print(speech)

        for plugin in plugins {
            plugin.speechDetected(speech.lowercased())
        }
    }
}

extension SpeechRecognizer: PluginDelegate {
    func speak(_ text: String) {
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
