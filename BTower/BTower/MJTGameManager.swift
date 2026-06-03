//
//  MJTGameManager.swift
//  Mahjong Tower
//
//  Core gameplay engine for a single floor: slot management, triple matching,
//  classic solitaire clickability, tools (hint/shuffle/undo) and win/fail.
//
//  The view layer talks to this through `MJTGameDelegate`; the manager never
//  touches UIKit views directly.
//

import Foundation

protocol MJTGameDelegate: AnyObject {
    func gameDidLoadBoard(_ manager: MJTGameManager)
    func game(_ manager: MJTGameManager, didSelectTile tile: MJTTileModel)
    func game(_ manager: MJTGameManager, didReveal tile: MJTTileModel)
    func game(_ manager: MJTGameManager, didBreakIce tile: MJTTileModel)
    func game(_ manager: MJTGameManager, didUnlockTiles tiles: [MJTTileModel])
    func game(_ manager: MJTGameManager, slotDidChange slot: [MJTTileModel])
    func game(_ manager: MJTGameManager, didMatchTiles tiles: [MJTTileModel], goldenBonus: Int)
    func game(_ manager: MJTGameManager, didRestoreState tiles: [MJTTileModel], slot: [MJTTileModel])
    func game(_ manager: MJTGameManager, highlightHints tiles: [MJTTileModel])
    func game(_ manager: MJTGameManager, timeRemaining seconds: Int)
    func gameDidWin(_ manager: MJTGameManager, reward: Int)
    func gameDidLose(_ manager: MJTGameManager)
}

final class MJTGameManager {

    weak var delegate: MJTGameDelegate?

    private(set) var config: MJTFloorConfig
    private(set) var tiles: [MJTTileModel] = []
    private(set) var slot: [MJTTileModel] = []
    private(set) var gridCols = 0
    private(set) var gridRows = 0

    // Tool charges available this floor.
    private(set) var hintsLeft: Int
    private(set) var shufflesLeft: Int
    private(set) var undosLeft: Int
    let slotCapacity: Int

    private var isFinished = false
    private var timer: Timer?
    private(set) var secondsRemaining: Int = 0
    private var lockTimer: Timer?

    // Undo support: full value snapshots of the board + slot.
    private struct Snapshot {
        let tileStates: [TileState]
        let slotIDs: [Int]
    }
    private struct TileState {
        let id: Int
        let isRemoved: Bool
        let isIced: Bool
        let isHidden: Bool
        let isLocked: Bool
    }
    private var undoStack: [Snapshot] = []

    init(floor: Int) {
        let cfg = MJTTowerManager.shared.config(for: floor)
        self.config = cfg
        let store = MJTStoreManager.shared
        self.hintsLeft = store.value(for: .hint)
        self.shufflesLeft = store.value(for: .shuffle)
        self.undosLeft = store.value(for: .undo)
        self.slotCapacity = store.value(for: .slot)
    }

    deinit { timer?.invalidate(); lockTimer?.invalidate() }

    // MARK: - Lifecycle

    func start() {
        let board = MJTTowerManager.shared.makeBoard(for: config)
        tiles = board.tiles
        gridCols = board.gridCols
        gridRows = board.gridRows
        slot.removeAll()
        undoStack.removeAll()
        isFinished = false
        delegate?.gameDidLoadBoard(self)
        delegate?.game(self, slotDidChange: slot)

        if config.bossRule == .timeChallenge {
            secondsRemaining = config.timeLimit
            startTimer()
        }
        if config.bossRule == .lockedTiles {
            startLockTimer()
        }
    }

    private func startTimer() {
        delegate?.game(self, timeRemaining: secondsRemaining)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isFinished else { return }
            self.secondsRemaining -= 1
            self.delegate?.game(self, timeRemaining: self.secondsRemaining)
            if self.secondsRemaining <= 0 { self.lose() }
        }
    }

    private func startLockTimer() {
        lockTimer?.invalidate()
        lockTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self, !self.isFinished else { return }
            let unlocked = self.tiles.filter { $0.isLocked && !$0.isRemoved }
            unlocked.forEach { $0.isLocked = false }
            if !unlocked.isEmpty { self.delegate?.game(self, didUnlockTiles: unlocked) }
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        lockTimer?.invalidate(); lockTimer = nil
        isFinished = true
    }
    // MARK: - Clickability (classic mahjong rules)

    /// A tile is free if nothing covers it AND its left OR right edge is open.
    func isSelectable(_ tile: MJTTileModel) -> Bool {
        guard !tile.isRemoved, !tile.isLocked else { return false }
        if isCovered(tile) { return false }
        return isLeftFree(tile) || isRightFree(tile)
    }

    /// Any active tile on a higher layer whose 2x2 footprint overlaps this one.
    private func isCovered(_ tile: MJTTileModel) -> Bool {
        for other in tiles where !other.isRemoved && other.layer > tile.layer {
            if overlaps(tile, other) { return true }
        }
        return false
    }

    private func overlaps(_ a: MJTTileModel, _ b: MJTTileModel) -> Bool {
        // Each tile spans a 2x2 block on the half-unit grid.
        let ax = a.col, ay = a.row, bx = b.col, by = b.row
        return abs(ax - bx) < 2 && abs(ay - by) < 2
    }

    private func isLeftFree(_ tile: MJTTileModel) -> Bool {
        !tiles.contains { other in
            !other.isRemoved && other.layer == tile.layer &&
            other.row == tile.row && other.col == tile.col - 2
        }
    }

    private func isRightFree(_ tile: MJTTileModel) -> Bool {
        !tiles.contains { other in
            !other.isRemoved && other.layer == tile.layer &&
            other.row == tile.row && other.col == tile.col + 2
        }
    }

    // MARK: - Selection

    func select(_ tile: MJTTileModel) {
        guard !isFinished, !tile.isRemoved else { return }

        // Hidden tiles reveal on first tap and require a second tap to play.
        if tile.isHidden {
            tile.isHidden = false
            delegate?.game(self, didReveal: tile)
            return
        }
        guard isSelectable(tile) else { return }

        pushUndoSnapshot()

        // Frozen tile: first valid selection breaks the ice but stays put.
        if tile.isIced {
            tile.isIced = false
            delegate?.game(self, didBreakIce: tile)
            // Breaking ice still consumes the move conceptually, but the tile
            // does not enter the slot; keep the snapshot so it can be undone.
            return
        }

        // Move the tile into the slot.
        tile.isRemoved = true
        insertIntoSlot(tile)
        delegate?.game(self, didSelectTile: tile)
        delegate?.game(self, slotDidChange: slot)

        resolveMatches()
        evaluateEndState()
    }

    /// Slot keeps identical tiles grouped so triples land adjacently.
    private func insertIntoSlot(_ tile: MJTTileModel) {
        if let lastIdx = slot.lastIndex(where: { matches($0, tile) }) {
            slot.insert(tile, at: lastIdx + 1)
        } else {
            slot.append(tile)
        }
    }

    /// Two tiles match if same suit+rank, or either is a Lucky wildcard.
    private func matches(_ a: MJTTileModel, _ b: MJTTileModel) -> Bool {
        if a.special == .lucky || b.special == .lucky { return true }
        return a.suit == b.suit && a.rank == b.rank
    }

    // MARK: - Matching (remove any 3 identical/wildcard tiles in the slot)

    private func resolveMatches() {
        var didMatch = true
        while didMatch {
            didMatch = false
            if let group = findTriple() {
                var bonus = 0
                for t in group where t.special == .golden {
                    bonus += 50
                }
                let ids = Set(group.map { $0.id })
                slot.removeAll { ids.contains($0.id) }
                delegate?.game(self, didMatchTiles: group, goldenBonus: bonus)
                delegate?.game(self, slotDidChange: slot)
                didMatch = true
            }
        }
    }

    /// Finds three slot tiles that mutually match (handles lucky wildcards).
    private func findTriple() -> [MJTTileModel]? {
        // Group by concrete key first.
        var buckets: [String: [MJTTileModel]] = [:]
        var luckies: [MJTTileModel] = []
        for t in slot {
            if t.special == .lucky { luckies.append(t) }
            else { buckets[t.matchKey, default: []].append(t) }
        }
        // Three of a concrete kind.
        for (_, group) in buckets where group.count >= 3 {
            return Array(group.prefix(3))
        }
        // Concrete pair + 1 lucky.
        if luckies.count >= 1 {
            for (_, group) in buckets where group.count >= 2 {
                return Array(group.prefix(2)) + [luckies[0]]
            }
        }
        // 1 concrete + 2 lucky.
        if luckies.count >= 2, let any = buckets.values.first(where: { !$0.isEmpty })?.first {
            return [any] + Array(luckies.prefix(2))
        }
        // 3 lucky.
        if luckies.count >= 3 { return Array(luckies.prefix(3)) }
        return nil
    }

    // MARK: - Win / Fail

    private func evaluateEndState() {
        if tiles.allSatisfy({ $0.isRemoved }) {
            win()
        } else if slot.count >= slotCapacity {
            lose()
        }
    }

    private func win() {
        guard !isFinished else { return }
        stop()
        delegate?.gameDidWin(self, reward: config.coinReward)
    }

    private func lose() {
        guard !isFinished else { return }
        stop()
        delegate?.gameDidLose(self)
    }

    /// Grants a one-shot rescue (rewarded ad "Continue"): clears the slot.
    func continueAfterFail() {
        isFinished = false
        slot.removeAll()
        delegate?.game(self, slotDidChange: slot)
        if config.bossRule == .timeChallenge {
            secondsRemaining = max(secondsRemaining, 60)
            startTimer()
        }
    }
    // MARK: - Tools

    /// Highlights selectable tiles that could progress toward a match.
    @discardableResult
    func useHint() -> Bool {
        guard !isFinished, hintsLeft > 0 else { return false }
        hintsLeft -= 1
        let selectable = tiles.filter { isSelectable($0) && !$0.isIced && !$0.isHidden }

        // Prefer tiles whose match key already has support on the board/slot.
        var keyCount: [String: Int] = [:]
        for t in slot { keyCount[t.matchKey, default: 0] += 1 }
        for t in selectable { keyCount[t.matchKey, default: 0] += 1 }

        let ranked = selectable.sorted {
            (keyCount[$0.matchKey] ?? 0) > (keyCount[$1.matchKey] ?? 0)
        }
        let hints = Array(ranked.prefix(3))
        delegate?.game(self, highlightHints: hints)
        return true
    }

    /// Re-randomizes the suit/rank of all remaining tiles while keeping every
    /// type count a multiple of 3, so the board stays solvable.
    @discardableResult
    func useShuffle() -> Bool {
        guard !isFinished, shufflesLeft > 0 else { return false }
        shufflesLeft -= 1
        pushUndoSnapshot()

        let active = tiles.filter { !$0.isRemoved }
        // Preserve identities already partially consumed: rebuild a fresh
        // multiple-of-3 identity pool sized to the active tiles.
        var pool: [(MJTSuit, Int)] = []
        let triples = active.count / 3
        for _ in 0..<triples {
            let suit: MJTSuit = Bool.random() ? .characters : .dots
            let rank = Int.random(in: 1...9)
            for _ in 0..<3 { pool.append((suit, rank)) }
        }
        // Any remainder (shouldn't happen since counts stay /3) gets padded.
        while pool.count < active.count { pool.append((.dots, 1)) }
        pool.shuffle()

        for (i, tile) in active.enumerated() {
            let (suit, rank) = pool[i]
            // Lucky/golden specials keep their behaviour but adopt new identity.
            tile.reassign(suit: suit, rank: rank)
        }
        delegate?.game(self, didRestoreState: tiles, slot: slot)
        return true
    }

    @discardableResult
    func useUndo() -> Bool {
        guard !isFinished, undosLeft > 0, let snap = undoStack.popLast() else { return false }
        undosLeft -= 1
        apply(snap)
        delegate?.game(self, didRestoreState: tiles, slot: slot)
        return true
    }

    // MARK: - Undo snapshots

    private func pushUndoSnapshot() {
        let states = tiles.map {
            TileState(id: $0.id, isRemoved: $0.isRemoved, isIced: $0.isIced,
                      isHidden: $0.isHidden, isLocked: $0.isLocked)
        }
        undoStack.append(Snapshot(tileStates: states, slotIDs: slot.map { $0.id }))
        if undoStack.count > 50 { undoStack.removeFirst() }
    }

    private func apply(_ snap: Snapshot) {
        var byID: [Int: MJTTileModel] = [:]
        for t in tiles { byID[t.id] = t }
        for state in snap.tileStates {
            guard let t = byID[state.id] else { continue }
            t.isRemoved = state.isRemoved
            t.isIced = state.isIced
            t.isHidden = state.isHidden
            t.isLocked = state.isLocked
        }
        slot = snap.slotIDs.compactMap { byID[$0] }
    }
}
