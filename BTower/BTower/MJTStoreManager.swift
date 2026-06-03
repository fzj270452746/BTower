//
//  MJTStoreManager.swift
//  Mahjong Tower
//
//  Handles permanent upgrades bought with coins.
//

import Foundation

enum MJTUpgradeKind: CaseIterable {
    case hint
    case shuffle
    case undo
    case slot

    var title: String {
        switch self {
        case .hint:    return "Hint Capacity"
        case .shuffle: return "Shuffle Capacity"
        case .undo:    return "Undo Capacity"
        case .slot:    return "Slot Capacity"
        }
    }

    var iconName: String {
        switch self {
        case .hint:    return "icon_hint"
        case .shuffle: return "icon_shuffle"
        case .undo:    return "icon_undo"
        case .slot:    return "mahjong_tile_base"
        }
    }

    /// Starting value at level 1 and the value gained per level.
    var baseValue: Int {
        switch self {
        case .hint:    return 3   // 3 → 4 → 5
        case .shuffle: return 2   // 2 → 3 → 4
        case .undo:    return 3   // 3 → 4 → 5
        case .slot:    return 7   // 7 → 8 → 9
        }
    }

    /// Highest level the upgrade can reach (3 tiers per spec).
    var maxLevel: Int { 3 }
}

final class MJTStoreManager {

    static let shared = MJTStoreManager()
    private let save = MJTSaveManager.shared

    private init() {}

    // Cost grows with each tier purchased.
    private let tierCosts = [200, 500] // cost to go L1->L2, L2->L3

    func level(for kind: MJTUpgradeKind) -> Int {
        switch kind {
        case .hint:    return save.hintLevel
        case .shuffle: return save.shuffleLevel
        case .undo:    return save.undoLevel
        case .slot:    return save.slotLevel
        }
    }

    /// The effective capacity granted at the current level.
    func value(for kind: MJTUpgradeKind) -> Int {
        kind.baseValue + (level(for: kind) - 1)
    }

    /// The value the next level would grant, or nil at max.
    func nextValue(for kind: MJTUpgradeKind) -> Int? {
        guard level(for: kind) < kind.maxLevel else { return nil }
        return kind.baseValue + level(for: kind)
    }

    /// Coin cost to buy the next level, or nil at max.
    func nextCost(for kind: MJTUpgradeKind) -> Int? {
        let lvl = level(for: kind)
        guard lvl < kind.maxLevel else { return nil }
        return tierCosts[min(lvl - 1, tierCosts.count - 1)]
    }

    @discardableResult
    func purchase(_ kind: MJTUpgradeKind) -> Bool {
        guard let cost = nextCost(for: kind), save.coins >= cost else { return false }
        save.coins -= cost
        switch kind {
        case .hint:    save.hintLevel    += 1
        case .shuffle: save.shuffleLevel += 1
        case .undo:    save.undoLevel    += 1
        case .slot:    save.slotLevel    += 1
        }
        return true
    }
}
