//
//  SpeechRecognizer.swift
//  assistant
//
//  Created by Gabe Kangas on 2/13/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation
import Speech

class SpeechRecognizer {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private var endOfCommandTimer: Timer?
    let audioSession = AVAudioSession.sharedInstance()

    fileprivate let speechSynthesizer = AVSpeechSynthesizer()

    var plugins = [Plugin]()

    init() {
        try! audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try! audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try! audioEngine.start()

        //print(AVSpeechSynthesisVoice.speechVoices())

        plugins.append(
          MeuralCanvasPlugin(delegate: self),
          TimerPlugin(delegate: self),
        )
    }

    func start() {
        restart()
    }

    func startRecording() throws {

//        recognitionTask?.cancel()
//        self.recognitionTask = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true

//        if #available(iOS 13, *) {
            if speechRecognizer?.supportsOnDeviceRecognition ?? false {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
//        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.endOfCommandTimer?.invalidate()

                DispatchQueue.main.async {
                    for transcribedString in result.transcriptions {
                        self.speechDetected(transcribedString.formattedString)
                    }
//                    let transcribedString = result.bestTranscription.formattedString
//                    self.speechDetected(transcribedString)

                    self.endOfCommandTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (_) in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.restart()
                        }
                    })
                }
            }

            if error != nil {
//                print(error)
//                self.audioEngine.stop()
//                inputNode.removeTap(onBus: 0)
//                self.recognitionRequest = nil
//                self.recognitionTask = nil
//                self.restart()
            }
        }
    }

    private func restart() {
//        print("Restarting...")
        //        audioEngine.stop()
        recognitionRequest?.endAudio()
        //        recognitionRequest?.
        recognitionTask?.cancel()
        //        recognitionRequest = nil
        //        recognitionTask = nil

        try! startRecording()
    }

    private func speechDetected(_ speech: String) {
        print(speech)

        for plugin in plugins {
            plugin.speechDetected(speech.lowercased())
        }
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization{authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized: print("authorized")
                case .restricted: print("restricted")
                case .notDetermined: print("not determined")
                case .denied: print("denied")
                @unknown default:
                    fatalError()
                }
            }
        }
    }
}

extension SpeechRecognizer: PluginDelegate {
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        //utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_en-US_compact")
        speechSynthesizer.speak(utterance)
    }


}
