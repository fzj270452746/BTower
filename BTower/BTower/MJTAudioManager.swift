//
//  MJTAudioManager.swift
//  Mahjong Tower
//
//  Lightweight sound + haptics. Uses system sounds so no audio assets are
//  required; respects the user's Settings toggles.
//

import UIKit
import AudioToolbox

final class MJTAudioManager {

    static let shared = MJTAudioManager()
    private let save = MJTSaveManager.shared

    private init() {}

    enum Effect {
        case tap
        case match
        case win
        case fail
        case coin
    }

    func play(_ effect: Effect) {
        guard save.soundEnabled else { return }
        let soundID: SystemSoundID
        switch effect {
        case .tap:   soundID = 1104
        case .match: soundID = 1105
        case .win:   soundID = 1025
        case .fail:  soundID = 1053
        case .coin:  soundID = 1057
        }
        AudioServicesPlaySystemSound(soundID)
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard save.vibrationEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard save.vibrationEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(type)
    }
}
