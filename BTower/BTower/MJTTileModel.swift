//
//  MJTTileModel.swift
//  Mahjong Tower
//
//  Data model for a single mahjong tile and supporting enums.
//

import Foundation
import CoreGraphics

/// The two suits used by this game (no winds / dragons / seasons / flowers).
enum MJTSuit: Int, Codable {
    case characters   // 1-9 Characters (萬)
    case dots         // 1-9 Dots (筒)
}

/// Special behaviours a tile can carry.
enum MJTSpecial: Int, Codable {
    case none
    case frozen   // Needs two matches: first breaks ice, second removes.
    case golden   // Grants +50 coins when matched.
    case lucky    // Wildcard: matches any tile.
}

/// A single tile placed on the board.
final class MJTTileModel: Codable {

    let id: Int
    private(set) var suit: MJTSuit
    /// Rank 1...9. Lucky (wildcard) tiles keep a rank but ignore it on match.
    private(set) var rank: Int

    // Grid position. `layer` 0 is the bottom; higher layers sit on top.
    var layer: Int
    var row: Int
    var col: Int

    var special: MJTSpecial

    // Runtime state -----------------------------------------------------
    /// Frozen tiles start iced; cleared after the first match.
    var isIced: Bool
    /// Boss "Hidden Tiles" rule: face-down until selected.
    var isHidden: Bool
    /// Boss "Locked Tiles" rule: cannot be tapped until the timer frees it.
    var isLocked: Bool
    /// Removed from the board (either into the slot or auto-matched).
    var isRemoved: Bool

    init(id: Int,
         suit: MJTSuit,
         rank: Int,
         layer: Int,
         row: Int,
         col: Int,
         special: MJTSpecial = .none,
         isHidden: Bool = false,
         isLocked: Bool = false) {
        self.id = id
        self.suit = suit
        self.rank = rank
        self.layer = layer
        self.row = row
        self.col = col
        self.special = special
        self.isIced = (special == .frozen)
        self.isHidden = isHidden
        self.isLocked = isLocked
        self.isRemoved = false
    }

    /// A stable key identifying which tiles "match". Lucky tiles get their own
    /// key so the matching logic can treat them as wildcards explicitly.
    var matchKey: String {
        if special == .lucky { return "lucky" }
        return "\(suit.rawValue)-\(rank)"
    }

    /// Display glyph, e.g. "1萬" or "5筒". Lucky shows a star.
    var glyph: String {
        if special == .lucky { return "★" }
        switch suit {
        case .characters: return "\(rank)萬"
        case .dots:       return "\(rank)筒"
        }
    }

    /// Used by Shuffle to give the tile a new identity while keeping position.
    func reassign(suit: MJTSuit, rank: Int) {
        self.suit = suit
        self.rank = rank
    }
}
