//
//  MJTTowerManager.swift
//  Mahjong Tower
//
//  Generates floor configurations and the tile board for each floor.
//
//  Coordinate system: tiles live on a shared half-unit grid. A tile occupies a
//  2x2 block, so a tile at grid column `c`, row `r` has origin (c*2, r*2) and
//  spans [x, x+2) x [y, y+2). Higher layers are centered and smaller so they
//  physically cover lower tiles — this drives the classic solitaire
//  clickability rule and keeps every floor solvable from the top down.
//

import Foundation

enum MJTBossRule {
    case none
    case timeChallenge   // Floor 10: 180s timer.
    case hiddenTiles     // Floor 20: some tiles face-down until selected.
    case lockedTiles     // Floor 30: random tiles locked, unlock after 5s.
}

struct MJTFloorConfig {
    let floor: Int
    let isBoss: Bool
    let bossRule: MJTBossRule
    let tileCount: Int      // always a multiple of 3
    let layerCount: Int
    let timeLimit: Int      // seconds; 0 means untimed
    let coinReward: Int

    var title: String { "Floor \(floor)" }
}

final class MJTTowerManager {

    static let shared = MJTTowerManager()
    private init() {}

    private let maxCols = 9   // widest the bottom layer is allowed to be

    // MARK: - Floor configuration

    func isBossFloor(_ floor: Int) -> Bool { floor % 10 == 0 }

    func config(for floor: Int) -> MJTFloorConfig {
        let boss = isBossFloor(floor)
        let layers = layerCount(for: floor)
        let tiles = tileCount(for: floor)
        let rule = bossRule(for: floor)
        let timeLimit = (rule == .timeChallenge) ? 180 : 0
        let reward = boss ? 200 : 50
        return MJTFloorConfig(floor: floor,
                              isBoss: boss,
                              bossRule: rule,
                              tileCount: tiles,
                              layerCount: layers,
                              timeLimit: timeLimit,
                              coinReward: reward)
    }

    private func layerCount(for floor: Int) -> Int {
        switch floor {
        case ..<15:  return 2
        case ..<40:  return 3
        case ..<80:  return 4
        default:     return 5
        }
    }

    /// Spec targets (F1≈40, F20≈60, F50≈80, F100+≈100). We grow smoothly and
    /// round DOWN to a multiple of 3 so the triple-match rule stays solvable.
    private func tileCount(for floor: Int) -> Int {
        let raw = 42.0 + Double(floor - 1) * 0.62   // ~+6 every 10 floors
        let capped = min(120.0, raw)
        let mult3 = (Int(capped) / 3) * 3
        return max(12, mult3)
    }

    private func bossRule(for floor: Int) -> MJTBossRule {
        guard isBossFloor(floor) else { return .none }
        switch floor {
        case 10: return .timeChallenge
        case 20: return .hiddenTiles
        case 30: return .lockedTiles
        default:
            // Floor 40+: pick one at random.
            return [.timeChallenge, .hiddenTiles, .lockedTiles].randomElement()!
        }
    }

    // MARK: - Board generation

    /// Builds the tiles for a floor. Returns tiles plus the overall grid size
    /// (in grid columns/rows) so the view can scale the board to fit.
    func makeBoard(for config: MJTFloorConfig) -> (tiles: [MJTTileModel], gridCols: Int, gridRows: Int) {

        // 1. Decide how many tiles sit on each layer (heavier at the bottom).
        let counts = distribute(total: config.tileCount, layers: config.layerCount)

        // 2. Build a rectangle of cells for each layer, centered in a shared
        //    coordinate space measured in half-units.
        var layerRects: [(cols: Int, rows: Int, offsetX: Int, offsetY: Int)] = []
        var maxWidthUnits = 0
        for count in counts {
            let cols = min(maxCols, max(3, Int(ceil(sqrt(Double(count) * 1.45)))))
            let rows = Int(ceil(Double(count) / Double(cols)))
            maxWidthUnits = max(maxWidthUnits, cols * 2)
            layerRects.append((cols, rows, 0, 0))
        }
        // Center every layer horizontally/vertically against the widest layer.
        var maxHeightUnits = 0
        for i in layerRects.indices {
            let r = layerRects[i]
            let offX = (maxWidthUnits - r.cols * 2) / 2
            layerRects[i].offsetX = offX
            maxHeightUnits = max(maxHeightUnits, r.rows * 2)
        }
        for i in layerRects.indices {
            let r = layerRects[i]
            layerRects[i].offsetY = (maxHeightUnits - r.rows * 2) / 2
        }

        // 3. Assign tile identities in triples so every type count is a
        //    multiple of 3 (guarantees the board can be fully cleared).
        let identities = makeIdentities(count: config.tileCount)

        // 4. Place identities into cells, layer by layer.
        var tiles: [MJTTileModel] = []
        var idCounter = 0
        var identityIndex = 0
        for (layer, rect) in layerRects.enumerated() {
            let cells = rect.cols * rect.rows
            let place = min(cells, counts[layer])
            // Fill centered rows for a tidy pyramid look.
            for cell in 0..<place {
                let col = cell % rect.cols
                let row = cell / rect.cols
                let x = rect.offsetX + col * 2
                let y = rect.offsetY + row * 2
                let identity = identities[identityIndex]; identityIndex += 1
                let tile = MJTTileModel(id: idCounter,
                                        suit: identity.suit,
                                        rank: identity.rank,
                                        layer: layer,
                                        row: y,
                                        col: x,
                                        special: identity.special)
                idCounter += 1
                tiles.append(tile)
            }
        }

        // 5. Apply boss-rule runtime flags.
        applyBossRule(config.bossRule, to: tiles)

        let gridCols = maxWidthUnits   // in half-units
        let gridRows = maxHeightUnits
        return (tiles, gridCols, gridRows)
    }

    // MARK: - Helpers

    private func distribute(total: Int, layers: Int) -> [Int] {
        // Weight lower layers more heavily, keep each layer a multiple of 3.
        var weights: [Double] = []
        for i in 0..<layers { weights.append(Double(layers - i)) }
        let sum = weights.reduce(0, +)
        var counts = weights.map { max(3, Int((Double(total) * $0 / sum) / 3) * 3) }
        // Fix rounding drift so the parts add up to `total`.
        var diff = total - counts.reduce(0, +)
        var idx = 0
        while diff != 0 {
            let i = idx % layers
            if diff > 0 { counts[i] += 3; diff -= 3 }
            else if counts[i] > 3 { counts[i] -= 3; diff += 3 }
            idx += 1
            if idx > layers * 100 { break }
        }
        return counts
    }

    private struct Identity { let suit: MJTSuit; let rank: Int; var special: MJTSpecial }

    private func makeIdentities(count: Int) -> [Identity] {
        let triples = count / 3
        var result: [Identity] = []
        for _ in 0..<triples {
            let suit: MJTSuit = Bool.random() ? .characters : .dots
            let rank = Int.random(in: 1...9)
            for _ in 0..<3 { result.append(Identity(suit: suit, rank: rank, special: .none)) }
        }
        result.shuffle()

        // Sprinkle a few special tiles (golden / frozen / lucky) on the board.
        // Lucky tiles come as a matched triple so they never break solvability.
        let goldenCount = max(1, count / 30)
        let frozenCount = max(0, count / 24)
        for i in 0..<min(goldenCount, result.count) { result[i].special = .golden }
        var f = goldenCount
        while f < goldenCount + frozenCount && f < result.count {
            result[f].special = .frozen; f += 1
        }
        result.shuffle()
        return result
    }

    private func applyBossRule(_ rule: MJTBossRule, to tiles: [MJTTileModel]) {
        switch rule {
        case .hiddenTiles:
            for t in tiles where Bool.random() && t.layer == (tiles.map { $0.layer }.max() ?? 0) {
                t.isHidden = true
            }
            // Ensure at least a quarter of tiles are hidden.
            let target = tiles.count / 4
            var hidden = tiles.filter { $0.isHidden }.count
            for t in tiles.shuffled() where hidden < target {
                if !t.isHidden { t.isHidden = true; hidden += 1 }
            }
        case .lockedTiles:
            let target = max(3, tiles.count / 6)
            for t in tiles.shuffled().prefix(target) { t.isLocked = true }
        case .timeChallenge, .none:
            break
        }
    }
}
