//
//  MJTButton.swift
//  Mahjong Tower
//
//  Reusable styled buttons used across all screens.
//

import UIKit
import SnapKit

/// A pill button with a gradient fill. Used for primary home-screen actions.
final class MJTButton: UIButton {

    private let gradient = MJTTheme.gradientLayer([MJTTheme.jadeLight, MJTTheme.jade])

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = MJTTheme.title(20)
        setTitleColor(.white, for: .normal)
        layer.insertSublayer(gradient, at: 0)
        layer.cornerRadius = MJTTheme.buttonCorner
        layer.masksToBounds = true
        layer.borderWidth = 1.5
        layer.borderColor = MJTTheme.gold.withAlphaComponent(0.6).cgColor
        addTarget(self, action: #selector(press), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Uses an image asset (e.g. btn_start) as the face without distorting it.
    /// The supplied art is a horizontal pill centered in a square canvas with
    /// transparent padding, so we trim the padding and render it aspect-fit in
    /// the foreground image view. The button is then height-constrained to the
    /// pill's true aspect ratio so it can never stretch.
    func applyImage(_ name: String) {
        guard let raw = UIImage(named: name) else { return }
        let img = raw.mjtTrimmedTransparent()
        setTitle(nil, for: .normal)
        setBackgroundImage(nil, for: .normal)
        setImage(img, for: .normal)
        imageView?.contentMode = .scaleAspectFit   // 或 .scaleAspectFill
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        gradient.isHidden = true
        layer.borderWidth = 0
        layer.cornerRadius = 0
        backgroundColor = .clear

        // 删除或注释以下宽高比约束代码
        // let size = img.size
        // ...
        // aspectConstraint = c
    }

    private var aspectConstraint: NSLayoutConstraint?

    func setSecondaryStyle() {
        gradient.colors = [MJTTheme.gold.cgColor, MJTTheme.goldDeep.cgColor]
        setTitleColor(MJTTheme.ink, for: .normal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    @objc private func press() { mjtPressBounce() }
}

/// A small round tool button (Hint / Shuffle / Undo) with an icon + badge.
final class MJTToolButton: UIControl {

    let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let badge = UILabel()

    var count: Int = 0 {
        didSet {
            badge.text = "\(count)"
            isEnabled = count > 0
            alpha = isEnabled ? 1.0 : 0.45
        }
    }

    init(icon: String, title: String) {
        super.init(frame: .zero)
        backgroundColor = MJTTheme.panel
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = MJTTheme.gold.withAlphaComponent(0.5).cgColor

        iconView.image = UIImage(named: icon)?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = MJTTheme.cream
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        titleLabel.text = title
        titleLabel.font = MJTTheme.body(12)
        titleLabel.textColor = MJTTheme.cream
        titleLabel.textAlignment = .center
        addSubview(titleLabel)

        badge.font = MJTTheme.title(12)
        badge.textColor = MJTTheme.ink
        badge.backgroundColor = MJTTheme.gold
        badge.textAlignment = .center
        badge.layer.cornerRadius = 10
        badge.layer.masksToBounds = true
        addSubview(badge)

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(28)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(2)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-6)
        }
        badge.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(-6)
            make.width.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if isEnabled { mjtPressBounce() }
        return super.beginTracking(touch, with: event)
    }
}
