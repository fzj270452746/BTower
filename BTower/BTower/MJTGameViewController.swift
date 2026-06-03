//
//  MJTGameViewController.swift
//  Mahjong Tower
//
//  The main gameplay screen: top bar (floor / coins / best), the mahjong
//  board, the tool row (hint / shuffle / undo) and the always-visible slot.
//

import UIKit
import SnapKit

final class MJTGameViewController: UIViewController {

    private let save = MJTSaveManager.shared
    private var game: MJTGameManager

    // Top bar
    private let topBar = UIView()
    private let floorLabel = UILabel()
    private let coinLabel = UILabel()
    private let bestLabel = UILabel()
    private let timerLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    // Board
    private let boardContainer = UIView()
    private var tileViews: [Int: MJTTileView] = [:]

    // Tools
    private let toolStack = UIStackView()
    private let hintTool = MJTToolButton(icon: "icon_hint", title: "Hint")
    private let shuffleTool = MJTToolButton(icon: "icon_shuffle", title: "Shuffle")
    private let undoTool = MJTToolButton(icon: "icon_undo", title: "Undo")

    // Slot
    private let slotContainer = UIView()
    private var slotCells: [UIView] = []
    private var slotTileViews: [MJTTileView] = []

    private var currentFloor: Int

    init(startFloor: Int) {
        self.currentFloor = startFloor
        self.game = MJTGameManager(floor: startFloor)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupTopBar()
        setupSlot()
        setupTools()
        setupBoard()
        startFloor(currentFloor, freshManager: false)
    }

    private func setupBackground() {
        view.backgroundColor = MJTTheme.jadeDark
        let bg = UIImageView(image: UIImage(named: "bg_game"))
        bg.contentMode = .scaleAspectFill
        bg.clipsToBounds = true
        view.addSubview(bg)
        bg.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupTopBar() {
        topBar.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        view.addSubview(topBar)
        topBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(100)
        }

        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = MJTTheme.title(22)
        closeButton.setTitleColor(MJTTheme.cream, for: .normal)
        closeButton.addTarget(self, action: #selector(tapClose), for: .touchUpInside)
        topBar.addSubview(closeButton)

        for label in [floorLabel, coinLabel, bestLabel] {
            label.font = MJTTheme.title(17)
            label.textColor = MJTTheme.cream
            topBar.addSubview(label)
        }
        floorLabel.textAlignment = .left
        coinLabel.textAlignment = .center
        coinLabel.textColor = MJTTheme.gold
        bestLabel.textAlignment = .right
        bestLabel.font = MJTTheme.body(14)

        timerLabel.font = MJTTheme.title(15)
        timerLabel.textColor = MJTTheme.danger
        timerLabel.textAlignment = .center
        timerLabel.isHidden = true
        topBar.addSubview(timerLabel)

        let guide = view.safeAreaLayoutGuide
        floorLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(guide.snp.top).offset(14)
        }
        coinLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(floorLabel)
        }
        bestLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(floorLabel)
        }
        timerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(coinLabel.snp.bottom).offset(4)
        }
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-6)
            make.width.height.equalTo(32)
        }
    }
    private func setupSlot() {
        slotContainer.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        slotContainer.layer.cornerRadius = 14
        slotContainer.layer.borderWidth = 1
        slotContainer.layer.borderColor = MJTTheme.gold.withAlphaComponent(0.5).cgColor
        view.addSubview(slotContainer)
        slotContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.height.equalTo(64)
        }
        rebuildSlotCells()
    }

    /// Slot capacity can change between runs (upgrade), so cells are rebuilt.
    private func rebuildSlotCells() {
        slotContainer.subviews.filter { $0.tag == 9911 }.forEach { $0.removeFromSuperview() }
        slotCells.removeAll()
        let capacity = game.slotCapacity
        let cellStack = UIStackView()
        cellStack.axis = .horizontal
        cellStack.distribution = .fillEqually
        cellStack.spacing = 4
        cellStack.tag = 9911
        slotContainer.addSubview(cellStack)
        cellStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }
        for _ in 0..<capacity {
            let cell = UIView()
            cell.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            cell.layer.cornerRadius = 5
            cellStack.addArrangedSubview(cell)
            slotCells.append(cell)
        }
    }

    private func setupTools() {
        toolStack.axis = .horizontal
        toolStack.distribution = .fillEqually
        toolStack.spacing = 16
        view.addSubview(toolStack)
        toolStack.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.bottom.equalTo(slotContainer.snp.top).offset(-12)
            make.height.equalTo(58)
        }
        [hintTool, shuffleTool, undoTool].forEach { toolStack.addArrangedSubview($0) }
        hintTool.addTarget(self, action: #selector(tapHint), for: .touchUpInside)
        shuffleTool.addTarget(self, action: #selector(tapShuffle), for: .touchUpInside)
        undoTool.addTarget(self, action: #selector(tapUndo), for: .touchUpInside)
    }

    private func setupBoard() {
        view.addSubview(boardContainer)
        boardContainer.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(8)
            make.bottom.equalTo(toolStack.snp.top).offset(-12)
        }
    }
    // MARK: - Floor flow

    private func startFloor(_ floor: Int, freshManager: Bool) {
        currentFloor = floor
        save.currentRunFloor = floor
        save.hasActiveRun = true
        if freshManager {
            game = MJTGameManager(floor: floor)
            rebuildSlotCells()
        }
        game.delegate = self
        timerLabel.isHidden = (game.config.bossRule != .timeChallenge)
        refreshHUD()
        game.start()
    }

    private func refreshHUD() {
        floorLabel.text = game.config.isBoss ? "Floor \(currentFloor) ★" : "Floor \(currentFloor)"
        coinLabel.text = "🪙 \(save.coins)"
        bestLabel.text = "Best \(save.bestFloor)"
        hintTool.count = game.hintsLeft
        shuffleTool.count = game.shufflesLeft
        undoTool.count = game.undosLeft
    }

    // MARK: - Board rendering

    private func renderBoard() {
        tileViews.values.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()
        boardContainer.layoutIfNeeded()

        let cols = max(1, game.gridCols)
        let rows = max(1, game.gridRows)
        let area = boardContainer.bounds
        guard area.width > 0, area.height > 0 else { return }

        // Each tile is 2 half-units wide; layers shift slightly for a 3D look.
        let unitW = area.width / CGFloat(cols + 1)
        let unitH = area.height / CGFloat(rows + 1)
        let unit = min(unitW, unitH)
        let tileW = unit * 2 * 0.96
        let tileH = unit * 2 * 0.96

        // Center the whole board within the container.
        let boardW = CGFloat(cols) * unit
        let boardH = CGFloat(rows) * unit
        let originX = area.midX - boardW / 2
        let originY = area.midY - boardH / 2
        let layerShift = unit * 0.16

        // Draw bottom layers first so upper layers sit visually on top.
        let sorted = game.tiles.filter { !$0.isRemoved }.sorted {
            if $0.layer != $1.layer { return $0.layer < $1.layer }
            if $0.row != $1.row { return $0.row < $1.row }
            return $0.col < $1.col
        }
        for model in sorted {
            let tv = MJTTileView(model: model)
            let x = originX + CGFloat(model.col) * unit - CGFloat(model.layer) * layerShift
            let y = originY + CGFloat(model.row) * unit - CGFloat(model.layer) * layerShift
            tv.frame = CGRect(x: x, y: y, width: tileW, height: tileH)
            tv.onTap = { [weak self] view in self?.handleTileTap(view) }
            boardContainer.addSubview(tv)
            tileViews[model.id] = tv
        }
        updateSelectableAppearance()
    }

    private func updateSelectableAppearance() {
        for (id, tv) in tileViews {
            guard let model = game.tiles.first(where: { $0.id == id }) else { continue }
            tv.setSelectableAppearance(game.isSelectable(model) || model.isHidden)
        }
    }

    private func handleTileTap(_ tileView: MJTTileView) {
        let model = tileView.model
        if model.isHidden {
            game.select(model)   // reveals
            return
        }
        guard game.isSelectable(model) else {
            MJTAudioManager.shared.haptic(.rigid)
            return
        }
        tileView.animateSelect()
        MJTAudioManager.shared.play(.tap)
        MJTAudioManager.shared.haptic(.light)
        game.select(model)
    }

    // MARK: - Slot rendering

    private func renderSlot(_ slotModels: [MJTTileModel]) {
        slotTileViews.forEach { $0.removeFromSuperview() }
        slotTileViews.removeAll()
        for (i, model) in slotModels.enumerated() where i < slotCells.count {
            let cell = slotCells[i]
            let tv = MJTTileView(model: model)
            slotContainer.addSubview(tv)
            tv.frame = cell.frame
            tv.isUserInteractionEnabled = false
            slotTileViews.append(tv)
        }
    }

    // MARK: - Tool actions

    @objc private func tapHint() {
        if game.useHint() { refreshHUD() }
    }
    @objc private func tapShuffle() {
        if game.useShuffle() {
            MJTAudioManager.shared.haptic(.medium)
            refreshHUD()
        }
    }
    @objc private func tapUndo() {
        if game.useUndo() {
            MJTAudioManager.shared.haptic(.light)
            refreshHUD()
        }
    }

    @objc private func tapClose() {
        game.stop()
        dismiss(animated: true)
    }
}

// MARK: - Overlays & rewards

extension MJTGameViewController {

    private func flyCoinReward(amount: Int) {
        let label = UILabel()
        label.text = "+\(amount)"
        label.font = MJTTheme.title(22)
        label.textColor = MJTTheme.gold
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
        UIView.animate(withDuration: 0.6, animations: {
            label.center = self.coinLabel.center
            label.alpha = 0
            label.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }, completion: { _ in label.removeFromSuperview() })
    }

    private func presentFloorComplete(reward: Int, nextFloor: Int) {
        let overlay = makeOverlay()
        let panel = makePanel(in: overlay)
        let content = makeContentStack(in: panel)

        content.addArrangedSubview(makeTitleLabel("Floor Complete", color: MJTTheme.gold))
        content.addArrangedSubview(makeMessageLabel("Reward: \(reward) Coins"))

        let cont = MJTButton(title: "Continue")
        cont.setSecondaryStyle()
        cont.snp.makeConstraints { $0.height.equalTo(MJTTheme.buttonHeight) }
        cont.addAction(UIAction { [weak self, weak overlay] _ in
            overlay?.removeFromSuperview()
            self?.startFloor(nextFloor, freshManager: true)
        }, for: .touchUpInside)
        content.addArrangedSubview(cont)

        let home = makeTextButton("Return Home")
        home.snp.makeConstraints { $0.height.equalTo(36) }
        home.addAction(UIAction { [weak self] _ in self?.tapClose() }, for: .touchUpInside)
        content.addArrangedSubview(home)
    }

    private func presentGameOver() {
        let overlay = makeOverlay()
        let panel = makePanel(in: overlay)
        let content = makeContentStack(in: panel)

        content.addArrangedSubview(makeTitleLabel("Game Over", color: MJTTheme.danger))
        content.addArrangedSubview(makeMessageLabel("You reached Floor \(currentFloor)"))

        // Rewarded-ad "Continue Once" (only if ads not removed; offline stub).
        let watchAd = MJTButton(title: "Continue (Watch Ad)")
        watchAd.snp.makeConstraints { $0.height.equalTo(MJTTheme.buttonHeight) }
        watchAd.addAction(UIAction { [weak self, weak overlay] _ in
            overlay?.removeFromSuperview()
            self?.simulateRewardedContinue()
        }, for: .touchUpInside)
        content.addArrangedSubview(watchAd)

        let retry = MJTButton(title: "Retry")
        retry.setSecondaryStyle()
        retry.snp.makeConstraints { $0.height.equalTo(MJTTheme.buttonHeight) }
        retry.addAction(UIAction { [weak self, weak overlay] _ in
            overlay?.removeFromSuperview()
            self?.startFloor(self?.currentFloor ?? 1, freshManager: true)
        }, for: .touchUpInside)
        content.addArrangedSubview(retry)

        let home = makeTextButton("Return Home")
        home.snp.makeConstraints { $0.height.equalTo(36) }
        home.addAction(UIAction { [weak self] _ in
            self?.save.clearRun()
            self?.tapClose()
        }, for: .touchUpInside)
        content.addArrangedSubview(home)
    }

    /// Stands in for a rewarded ad: grants the one-shot slot rescue.
    private func simulateRewardedContinue() {
        game.continueAfterFail()
        refreshHUD()
    }

    // MARK: - Overlay builders

    private func makeOverlay() -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        return overlay
    }

    private func makePanel(in overlay: UIView) -> UIView {
        let panel = UIView()
        panel.backgroundColor = MJTTheme.jade
        panel.layer.cornerRadius = 20
        panel.layer.borderWidth = 2
        panel.layer.borderColor = MJTTheme.gold.cgColor
        overlay.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
        }
        panel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        panel.alpha = 0
        UIView.animate(withDuration: 0.25) {
            panel.transform = .identity
            panel.alpha = 1
        }
        return panel
    }

    /// A vertical content stack pinned to all four panel edges. This gives the
    /// panel a real height (it sizes to its content), keeping every button
    /// inside the panel's bounds so taps register.
    private func makeContentStack(in panel: UIView) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        panel.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().offset(-20)
            make.left.right.equalToSuperview().inset(20)
        }
        return stack
    }

    private func makeTitleLabel(_ text: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = MJTTheme.title(28)
        label.textColor = color
        label.textAlignment = .center
        return label
    }

    private func makeMessageLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = MJTTheme.body(17)
        label.textColor = MJTTheme.cream
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    private func makeTextButton(_ title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = MJTTheme.body(15)
        b.setTitleColor(MJTTheme.cream.withAlphaComponent(0.85), for: .normal)
        return b
    }
}

// MARK: - MJTGameDelegate

extension MJTGameViewController: MJTGameDelegate {

    func gameDidLoadBoard(_ manager: MJTGameManager) {
        // Defer until container has its final size.
        DispatchQueue.main.async { [weak self] in self?.renderBoard() }
    }

    func game(_ manager: MJTGameManager, didSelectTile tile: MJTTileModel) {
        // Remove the board view; the tile now lives in the slot.
        if let tv = tileViews[tile.id] {
            tv.removeFromSuperview()
            tileViews[tile.id] = nil
        }
        updateSelectableAppearance()
    }

    func game(_ manager: MJTGameManager, didReveal tile: MJTTileModel) {
        tileViews[tile.id]?.animateReveal()
        MJTAudioManager.shared.play(.tap)
        updateSelectableAppearance()
    }

    func game(_ manager: MJTGameManager, didBreakIce tile: MJTTileModel) {
        tileViews[tile.id]?.animateBreakIce()
        MJTAudioManager.shared.play(.tap)
        MJTAudioManager.shared.haptic(.medium)
    }

    func game(_ manager: MJTGameManager, didUnlockTiles tiles: [MJTTileModel]) {
        tiles.forEach { tileViews[$0.id]?.refresh() }
        updateSelectableAppearance()
    }

    func game(_ manager: MJTGameManager, slotDidChange slot: [MJTTileModel]) {
        renderSlot(slot)
    }

    func game(_ manager: MJTGameManager, didMatchTiles tiles: [MJTTileModel], goldenBonus: Int) {
        MJTAudioManager.shared.play(.match)
        MJTAudioManager.shared.haptic(.medium)
        // Animate matching tiles out of the slot.
        for model in tiles {
            if let tv = slotTileViews.first(where: { $0.model.id == model.id }) {
                tv.animateMatchOut {}
            }
        }
        if goldenBonus > 0 {
            save.coins += goldenBonus
            refreshHUD()
            flyCoinReward(amount: goldenBonus)
            MJTAudioManager.shared.play(.coin)
        }
    }

    func game(_ manager: MJTGameManager, didRestoreState tiles: [MJTTileModel], slot: [MJTTileModel]) {
        renderBoard()
        renderSlot(slot)
    }

    func game(_ manager: MJTGameManager, highlightHints tiles: [MJTTileModel]) {
        tiles.forEach { tileViews[$0.id]?.animateHint() }
    }

    func game(_ manager: MJTGameManager, timeRemaining seconds: Int) {
        let m = seconds / 60, s = seconds % 60
        timerLabel.text = String(format: "⏱ %d:%02d", m, s)
        timerLabel.isHidden = false
    }

    func gameDidWin(_ manager: MJTGameManager, reward: Int) {
        save.coins += reward
        let nextFloor = currentFloor + 1
        if currentFloor > save.bestFloor { save.bestFloor = currentFloor }
        save.currentRunFloor = nextFloor
        refreshHUD()
        MJTAudioManager.shared.play(.win)
        MJTAudioManager.shared.notify(.success)
        presentFloorComplete(reward: reward, nextFloor: nextFloor)
    }

    func gameDidLose(_ manager: MJTGameManager) {
        MJTAudioManager.shared.play(.fail)
        MJTAudioManager.shared.notify(.error)
        presentGameOver()
    }
}
