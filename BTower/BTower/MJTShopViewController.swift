//
//  MJTShopViewController.swift
//  Mahjong Tower
//
//  Spend coins on permanent upgrades.
//

import UIKit
import SnapKit

final class MJTShopViewController: UIViewController {

    private let store = MJTStoreManager.shared
    private let save = MJTSaveManager.shared

    private let coinLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var rows: [MJTUpgradeKind: UpgradeRow] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MJTTheme.jadeDark
        setupHeader()
        setupList()
        refresh()
    }

    private func setupHeader() {
        let header = UILabel()
        header.text = "Shop"
        header.font = MJTTheme.title(30)
        header.textColor = MJTTheme.gold
        header.textAlignment = .center
        view.addSubview(header)

        let close = UIButton(type: .system)
        close.setTitle("✕", for: .normal)
        close.titleLabel?.font = MJTTheme.title(24)
        close.setTitleColor(MJTTheme.cream, for: .normal)
        close.addTarget(self, action: #selector(tapClose), for: .touchUpInside)
        view.addSubview(close)

        coinLabel.font = MJTTheme.title(20)
        coinLabel.textColor = MJTTheme.gold
        coinLabel.textAlignment = .center
        view.addSubview(coinLabel)

        let guide = view.safeAreaLayoutGuide
        header.snp.makeConstraints { make in
            make.top.equalTo(guide).offset(16)
            make.centerX.equalToSuperview()
        }
        close.snp.makeConstraints { make in
            make.centerY.equalTo(header)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(40)
        }
        coinLabel.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
    }

    private func setupList() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 14

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(70)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalTo(scrollView).offset(-32)
        }

        for kind in MJTUpgradeKind.allCases {
            let row = UpgradeRow(kind: kind)
            row.onBuy = { [weak self] in self?.buy(kind) }
            contentStack.addArrangedSubview(row)
            rows[kind] = row
        }
    }

    private func buy(_ kind: MJTUpgradeKind) {
        if store.purchase(kind) {
            MJTAudioManager.shared.play(.coin)
            MJTAudioManager.shared.haptic(.medium)
        } else {
            MJTAudioManager.shared.haptic(.rigid)
        }
        refresh()
    }

    private func refresh() {
        coinLabel.text = "Coins: \(save.coins)"
        rows.forEach { $1.update() }
    }

    @objc private func tapClose() { dismiss(animated: true) }
}
