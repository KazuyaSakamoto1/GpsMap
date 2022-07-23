//
//  SpeechService.swift
//  LEAD WAY
//
//  Created by 坂本和哉 on 2022/07/19.
//

//テキスト読み関数

import UIKit
import AVFoundation

class SpeechService {

    private let synthesizer = AVSpeechSynthesizer()
     // 再生速度を設定
    var rate: Float = AVSpeechUtteranceDefaultSpeechRate
    // 言語を日本語に設定
    var voice = AVSpeechSynthesisVoice(language: "ja-JP")

    func say(_ phrase: String) {
        // 話す内容をセット
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.rate = rate
        utterance.voice = voice

        synthesizer.speak(utterance)
    }

    func getVoices() {

        AVSpeechSynthesisVoice.speechVoices().forEach({ print($0.language) })
    }
}
