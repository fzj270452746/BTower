//
//  MJTLegalViewController.swift
//  Mahjong Tower
//
//  Simple scrollable text screen for Privacy Policy / Terms of Use.
//

import UIKit
import SnapKit

enum MJTLegalText {
    static let privacy = """
    Mahjong Tower: Jade Ascent respects your privacy.

    This game is a single-player experience. It does not collect, store, or \
    transmit any personal information. There are no user accounts, no chat, \
    and no social features.

    All game progress (best floor, coins, upgrades, and settings) is stored \
    locally on your device using the system's standard storage. This data \
    never leaves your device and is removed if you delete the app.

    The game works fully offline and has no network dependency.

    Optional rewarded advertisements may be shown if you choose to watch them \
    for in-game rewards.

    Because no data is collected, there is nothing to request, export, or \
    delete from any server.

    If you have questions about this policy, please contact the developer \
    through the App Store listing.
    """

    static let terms = """
    By playing Mahjong Tower: Jade Ascent you agree to the following terms.

    This game is provided for entertainment purposes only. It contains no \
    gambling and offers no real-money rewards. In-game coins have no monetary \
    value and cannot be exchanged for cash or goods.

    Permanent upgrades are purchased using in-game coins earned through play.

    The game is intended for single-player use. There are no user accounts and \
    no online services are required.

    The developer is not liable for any loss of in-game progress. Game data is \
    stored locally and may be lost if the app is deleted.

    Continued use of the game constitutes acceptance of these terms.
    """
}

final class MJTLegalViewController: UIViewController {

    private let titleText: String
    private let bodyText: String

    init(titleText: String, bodyText: String) {
        self.titleText = titleText
        self.bodyText = bodyText
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MJTTheme.jadeDark

        let header = UILabel()
        header.text = titleText
        header.font = MJTTheme.title(24)
        header.textColor = MJTTheme.gold
        header.numberOfLines = 0
        view.addSubview(header)

        let close = UIButton(type: .system)
        close.setTitle("✕", for: .normal)
        close.titleLabel?.font = MJTTheme.title(24)
        close.setTitleColor(MJTTheme.cream, for: .normal)
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        view.addSubview(close)

        let scroll = UIScrollView()
        view.addSubview(scroll)
        let body = UILabel()
        body.text = bodyText
        body.font = MJTTheme.body(15)
        body.textColor = MJTTheme.cream
        body.numberOfLines = 0
        scroll.addSubview(body)

        let guide = view.safeAreaLayoutGuide
        header.snp.makeConstraints { make in
            make.top.equalTo(guide).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(close.snp.left).offset(-8)
        }
        close.snp.makeConstraints { make in
            make.top.equalTo(guide).offset(16)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(40)
        }
        scroll.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(16)
            make.left.right.bottom.equalTo(guide)
        }
        body.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalTo(scroll).offset(-40)
        }
    }
}
