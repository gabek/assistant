//
//  TextToSpeech.swift
//  assistant
//
//  Created by Gabe Kangas on 2/25/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import Foundation

protocol TextToSpeechDelegate: class {
    func didFinishSpeaking()
}

class TextToSpeech: NSObject {
    fileprivate let speechSynthesizer = AVSpeechSynthesizer()
    weak var delegate: TextToSpeechDelegate?

    override init() {
        super.init()

        speechSynthesizer.delegate = self
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_en-US_compact")
        speechSynthesizer.speak(utterance)
    }
}

extension TextToSpeech: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) {
        OEPocketsphinxController.sharedInstance()?.suspendRecognition()
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        delegate?.didFinishSpeaking()
        OEPocketsphinxController.sharedInstance()?.resumeRecognition()
    }
}
