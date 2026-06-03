//
//  MJTShopRows.swift
//  Mahjong Tower
//
//  Row views used by the Shop screen.
//

import UIKit
import SnapKit

/// One purchasable upgrade with its current level, effect and buy button.
final class UpgradeRow: UIView {

    private let kind: MJTUpgradeKind
    private let store = MJTStoreManager.shared

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let buyButton = MJTButton(title: "")

    var onBuy: (() -> Void)?

    init(kind: MJTUpgradeKind) {
        self.kind = kind
        super.init(frame: .zero)
        backgroundColor = MJTTheme.panel
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = MJTTheme.gold.withAlphaComponent(0.4).cgColor

        iconView.image = UIImage(named: kind.iconName)?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = MJTTheme.cream
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        titleLabel.text = kind.title
        titleLabel.font = MJTTheme.title(17)
        titleLabel.textColor = MJTTheme.cream
        addSubview(titleLabel)

        detailLabel.font = MJTTheme.body(13)
        detailLabel.textColor = MJTTheme.cream.withAlphaComponent(0.8)
        detailLabel.numberOfLines = 2
        addSubview(detailLabel)

        buyButton.setSecondaryStyle()
        buyButton.titleLabel?.font = MJTTheme.title(15)
        buyButton.addAction(UIAction { [weak self] _ in self?.onBuy?() }, for: .touchUpInside)
        addSubview(buyButton)

        snp.makeConstraints { $0.height.equalTo(86) }
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.top.equalToSuperview().offset(16)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.right.equalTo(buyButton.snp.left).offset(-8)
        }
        buyButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.equalTo(96)
            make.height.equalTo(48)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update() {
        let level = store.level(for: kind)
        let value = store.value(for: kind)
        if let next = store.nextValue(for: kind), let cost = store.nextCost(for: kind) {
            detailLabel.text = "Level \(level)  •  Now \(value) → \(next)"
            buyButton.setTitle("\(cost) 🪙", for: .normal)
            let affordable = MJTSaveManager.shared.coins >= cost
            buyButton.isEnabled = affordable
            buyButton.alpha = affordable ? 1.0 : 0.5
        } else {
            detailLabel.text = "Level \(level)  •  Max (\(value))"
            buyButton.setTitle("MAX", for: .normal)
            buyButton.isEnabled = false
            buyButton.alpha = 0.5
        }
    }
}
