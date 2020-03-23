//
//  SpeechRecognizer.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import Speech
import TLSphinx

protocol SpeechRecognizerDelegate: AnyObject {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.setup()
        }
        // setup()
    }

    private func generateSpeechRecognitionModels() -> (lmPath: String, dicPath: String)? {
        let lmGenerator = OELanguageModelGenerator()
        let phrases = plugins.flatMap { $0.commands } + [Constants.Strings.prefixPhrase]
        let name = "assistant"

        //        let grammar = [ThisWillBeSaidOnce : [
        //            [OneOfTheseWillBeSaidOnce: [Constants.prefixPhrase]],
        //            [OneOfTheseWillBeSaidOnce: phrases]]
        //        ]
        //
        //        let err: Error! = lmGenerator.generateGrammar(from: grammar, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))

        let err: Error! = lmGenerator.generateLanguageModel(from: phrases, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
        if let err = err {
            fatalError(err.localizedDescription)
        }

        guard let lmPath = lmGenerator.pathToSuccessfullyGeneratedLanguageModel(withRequestedName: name) else { return nil }
        //        guard let lmPath = lmGenerator.pathToSuccessfullyGeneratedGrammar(withRequestedName: name) else { return nil }
        guard let dicPath = lmGenerator.pathToSuccessfullyGeneratedDictionary(withRequestedName: name) else { return nil }

        return (lmPath: lmPath, dicPath: dicPath)
    }

    var decoder: Decoder!
    func setup() {
        try! AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        try! AVAudioSession.sharedInstance().setCategory(.playAndRecord) // , options: [.allowBluetooth, .mixWithOthers, .allowBluetoothA2DP])
        try! AVAudioSession.sharedInstance().setMode(.gameChat)
        try! AVAudioSession.sharedInstance().setPreferredInputNumberOfChannels(1)
//        try! AVAudioSession.sharedInstance().setPreferredSampleRate(48000)

        let test = generateSpeechRecognitionModels()
        let hmm = Bundle.main.bundlePath // Path to the acustic model
        let lm = test!.lmPath // Bundle.main.path(forResource: "en-us-phone", ofType: "lm.dmp") else { return } // Path to the languaje model
        let dict = test!.dicPath // Bundle.main.path(forResource: "cmudict-en-us", ofType: "dict") else { return } // Path to the languaje dictionary
        let keywords = Bundle.main.path(forResource: "commands", ofType: "txt")!
        if let config = Config(args: ("-hmm", hmm), ("-lm", lm),
                               ("-kws", keywords), ("-dict", dict),
                               ("-nfft", "2048"), ("-samprate", "16000")) {
            config.showDebugInfo = false
            decoder = Decoder(config: config)!
            //        try! decoder.add(words:[("HEY","HH EY"), ("HELLO","HH EH L OW"), ("HEY COMPUTER", "HH EY K AH M P Y UW T ER")])

            try! decoder.startDecodingSpeech { hypothosis in
                guard let hypothosis = hypothosis else { return }
                self.didReceiveSpeech(hypothosis.text.lowercased())
            }

        } else {
            // Handle Config() fail
            print("Config fail")
        }
    }

    fileprivate func didReceiveSpeech(_ speech: String) {
        if speech == "" { return }

        guard let location = speech.range(of: Constants.Strings.prefixPhrase)?.lowerBound else { return }

        let fixedString = speech.suffix(from: location)

        print("*****", fixedString)

        let removedPrefixPhrase = fixedString.replacingOccurrences(of: Constants.Strings.prefixPhrase, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        if removedPrefixPhrase == "" { return }

        for plugin in plugins {
            for command in plugin.commands {
                if fixedString.contains(command) {
                    plugin.speechDetected(command)
                }
            }
        }
    }
}
