//
//  MJTSaveManager.swift
//  Mahjong Tower
//
//  Persists progression, coins, upgrade levels and settings via UserDefaults.
//

import Foundation

final class MJTSaveManager {

    static let shared = MJTSaveManager()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let bestFloor    = "mjt.bestFloor"
        static let coins        = "mjt.coins"
        static let upHint       = "mjt.upgrade.hint"
        static let upShuffle    = "mjt.upgrade.shuffle"
        static let upUndo       = "mjt.upgrade.undo"
        static let upSlot       = "mjt.upgrade.slot"
        static let music        = "mjt.settings.music"
        static let sound        = "mjt.settings.sound"
        static let vibration    = "mjt.settings.vibration"
        static let currentFloor = "mjt.run.currentFloor"
        static let hasRun       = "mjt.run.hasRun"
        static let didBootstrap = "mjt.didBootstrap"
    }

    private init() {
        bootstrapDefaultsIfNeeded()
    }

    /// Settings default to ON the first time the app launches.
    private func bootstrapDefaultsIfNeeded() {
        guard !defaults.bool(forKey: Key.didBootstrap) else { return }
        defaults.set(true, forKey: Key.music)
        defaults.set(true, forKey: Key.sound)
        defaults.set(true, forKey: Key.vibration)
        defaults.set(true, forKey: Key.didBootstrap)
    }

    // MARK: - Progression
    var bestFloor: Int {
        get { defaults.integer(forKey: Key.bestFloor) }
        set { defaults.set(newValue, forKey: Key.bestFloor) }
    }

    var coins: Int {
        get { defaults.integer(forKey: Key.coins) }
        set { defaults.set(max(0, newValue), forKey: Key.coins) }
    }

    // MARK: - Upgrade levels (1-based; level 1 == starting capacity)
    var hintLevel: Int {
        get { max(1, defaults.integer(forKey: Key.upHint)) }
        set { defaults.set(newValue, forKey: Key.upHint) }
    }
    var shuffleLevel: Int {
        get { max(1, defaults.integer(forKey: Key.upShuffle)) }
        set { defaults.set(newValue, forKey: Key.upShuffle) }
    }
    var undoLevel: Int {
        get { max(1, defaults.integer(forKey: Key.upUndo)) }
        set { defaults.set(newValue, forKey: Key.upUndo) }
    }
    var slotLevel: Int {
        get { max(1, defaults.integer(forKey: Key.upSlot)) }
        set { defaults.set(newValue, forKey: Key.upSlot) }
    }

    // MARK: - Settings
    var musicEnabled: Bool {
        get { defaults.bool(forKey: Key.music) }
        set { defaults.set(newValue, forKey: Key.music) }
    }
    var soundEnabled: Bool {
        get { defaults.bool(forKey: Key.sound) }
        set { defaults.set(newValue, forKey: Key.sound) }
    }
    var vibrationEnabled: Bool {
        get { defaults.bool(forKey: Key.vibration) }
        set { defaults.set(newValue, forKey: Key.vibration) }
    }

    // MARK: - Current run (used by the Continue button)
    /// The floor the player should resume on, or 0 if no run is in progress.
    var currentRunFloor: Int {
        get { defaults.integer(forKey: Key.currentFloor) }
        set { defaults.set(newValue, forKey: Key.currentFloor) }
    }
    var hasActiveRun: Bool {
        get { defaults.bool(forKey: Key.hasRun) }
        set { defaults.set(newValue, forKey: Key.hasRun) }
    }

    func clearRun() {
        hasActiveRun = false
        currentRunFloor = 0
    }
}
