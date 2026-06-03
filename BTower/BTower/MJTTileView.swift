//
//  MJTTileView.swift
//  Mahjong Tower
//
//  Visual representation of one tile. Renders the base art plus the suit
//  glyph, and exposes animation helpers for select / match / reveal.
//

import UIKit
import SnapKit

final class MJTTileView: UIView {

    let model: MJTTileModel

    private let baseImage = UIImageView()
    private let glyphLabel = UILabel()
    private let suitDot = UIView()
    private let iceOverlay = UIView()
    private let hiddenOverlay = UIView()
    private let lockOverlay = UIView()
    private let specialBadge = UILabel()

    var onTap: ((MJTTileView) -> Void)?

    init(model: MJTTileModel) {
        self.model = model
        super.init(frame: .zero)
        build()
        refresh()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        layer.cornerRadius = 6
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 3

        baseImage.image = UIImage(named: "mahjong_tile_base")
        baseImage.contentMode = .scaleToFill
        baseImage.layer.cornerRadius = 6
        baseImage.layer.masksToBounds = true
        baseImage.backgroundColor = MJTTheme.cream
        addSubview(baseImage)

        glyphLabel.textAlignment = .center
        glyphLabel.adjustsFontSizeToFitWidth = true
        glyphLabel.minimumScaleFactor = 0.4
        addSubview(glyphLabel)

        specialBadge.textAlignment = .center
        specialBadge.font = MJTTheme.title(10)
        addSubview(specialBadge)

        for overlay in [iceOverlay, hiddenOverlay, lockOverlay] {
            overlay.layer.cornerRadius = 6
            overlay.layer.masksToBounds = true
            overlay.isHidden = true
            addSubview(overlay)
        }
        iceOverlay.backgroundColor = UIColor(red: 0.7, green: 0.88, blue: 1.0, alpha: 0.55)
        iceOverlay.layer.borderWidth = 2
        iceOverlay.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor

        hiddenOverlay.backgroundColor = MJTTheme.jadeDark
        let q = UILabel()
        q.text = "?"
        q.textColor = MJTTheme.gold
        q.font = MJTTheme.title(22)
        q.textAlignment = .center
        hiddenOverlay.addSubview(q)
        q.snp.makeConstraints { $0.edges.equalToSuperview() }

        lockOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        let lock = UILabel()
        lock.text = "🔒"
        lock.font = MJTTheme.title(20)
        lock.textAlignment = .center
        lockOverlay.addSubview(lock)
        lock.snp.makeConstraints { $0.edges.equalToSuperview() }

        baseImage.snp.makeConstraints { $0.edges.equalToSuperview() }
        glyphLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(2) }
        specialBadge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(1)
            make.left.equalToSuperview().offset(2)
        }
        iceOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        hiddenOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        lockOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func refresh() {
        glyphLabel.text = model.glyph
        glyphLabel.textColor = .mjtSuitColor(model.suit)
        glyphLabel.font = MJTTheme.title(model.special == .lucky ? 26 : 20)
        if model.special == .lucky { glyphLabel.textColor = MJTTheme.goldDeep }

        switch model.special {
        case .golden:
            specialBadge.text = "★"
            specialBadge.textColor = MJTTheme.goldDeep
            baseImage.backgroundColor = MJTTheme.gold.withAlphaComponent(0.35)
        case .lucky:
            specialBadge.text = ""
            baseImage.backgroundColor = MJTTheme.cream
        default:
            specialBadge.text = ""
            baseImage.backgroundColor = MJTTheme.cream
        }

        iceOverlay.isHidden = !model.isIced
        hiddenOverlay.isHidden = !model.isHidden
        lockOverlay.isHidden = !model.isLocked
        glyphLabel.isHidden = model.isHidden
    }

    /// Dims tiles that are currently not selectable so the player has guidance.
    func setSelectableAppearance(_ selectable: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.baseImage.alpha = selectable ? 1.0 : 0.55
            self.glyphLabel.alpha = selectable ? 1.0 : 0.55
        }
    }

    @objc private func handleTap() { onTap?(self) }

    // MARK: - Animations

    func animateSelect() {
        UIView.animate(withDuration: 0.10, animations: {
            self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: { _ in
            UIView.animate(withDuration: 0.10) { self.transform = .identity }
        })
    }

    func animateHint() {
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue = 0.3
        pulse.duration = 0.45
        pulse.autoreverses = true
        pulse.repeatCount = 3
        layer.add(pulse, forKey: "hint")
        let glow = UIView(frame: bounds.insetBy(dx: -3, dy: -3))
        glow.layer.borderColor = MJTTheme.gold.cgColor
        glow.layer.borderWidth = 3
        glow.layer.cornerRadius = 8
        addSubview(glow)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { glow.removeFromSuperview() }
    }

    func animateReveal() {
        UIView.transition(with: self, duration: 0.3, options: .transitionFlipFromLeft) {
            self.refresh()
        }
    }

    func animateBreakIce() {
        UIView.animate(withDuration: 0.25) { self.refresh() }
    }

    func animateMatchOut(completion: @escaping () -> Void) {
        let glow = CABasicAnimation(keyPath: "shadowColor")
        glow.toValue = MJTTheme.gold.cgColor
        layer.add(glow, forKey: "glow")
        UIView.animate(withDuration: 0.25, animations: {
            self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            completion()
        })
    }
}
