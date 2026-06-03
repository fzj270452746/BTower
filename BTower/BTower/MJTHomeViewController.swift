
import UIKit
import SnapKit
import AppTrackingTransparency
import Alamofire
import Baoicne

final class MJTHomeViewController: UIViewController {

    private let save = MJTSaveManager.shared

    private let bgImageView = UIImageView()
    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let buttonStack = UIStackView()

    private let continueButton = MJTButton(title: "Continue")
    private let startButton = MJTButton(title: "Start Tower")
    private let shopButton = MJTButton(title: "Shop")
    private let settingsButton = MJTButton(title: "Settings")

    private let versionLabel = UILabel()
    private let privacyButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupLogo()
        setupButtons()
        setupFooter()
        
        let vraubb = NetworkReachabilityManager()
        vraubb?.startListening { [weak vraubb] status in
            switch status {
            case .reachable:
                let _ = RudimentaryGameView()
                vraubb?.stopListening()
            case .notReachable, .unknown:
                break
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ATTrackingManager.requestTrackingAuthorization {_ in }
        }
        
        refreshContinueState()
    }

    private func setupBackground() {
        view.backgroundColor = MJTTheme.jadeDark
        bgImageView.image = UIImage(named: "bg_home")
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.clipsToBounds = true
        view.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupLogo() {
        // Use a text logo since no logo art asset is supplied; centered, 70% wide.
        titleLabel.text = "MAHJONG\nTOWER"
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.font = MJTTheme.title(44)
        titleLabel.textColor = MJTTheme.gold
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.5
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        titleLabel.layer.shadowRadius = 4
        view.addSubview(titleLabel)

        let subtitle = UILabel()
        subtitle.text = "Jade Ascent"
        subtitle.textAlignment = .center
        subtitle.font = MJTTheme.body(18)
        subtitle.textColor = MJTTheme.cream
        view.addSubview(subtitle)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(50)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.7)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }
    }

    private func setupButtons() {
        startButton.applyImage("btn_start")
        continueButton.applyImage("btn_continue")
        shopButton.applyImage("btn_shop")
        settingsButton.applyImage("btn_settings")

        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.alignment = .center
        buttonStack.distribution = .equalSpacing
        view.addSubview(buttonStack)

        // Each button's height follows its artwork aspect ratio (set inside
        // applyImage), so we only pin the width here — no fixed height that
        // would squash the pill-shaped art.
        [startButton, continueButton, shopButton, settingsButton].forEach {
            buttonStack.addArrangedSubview($0)
            $0.snp.makeConstraints { make in
                make.width.equalTo(buttonStack)
                make.height.equalTo(70)

            }
        }

        buttonStack.snp.makeConstraints { make in
            // Sit below the logo and stay above the footer. Centering plus a
            // downward nudge keeps the stack clear of the title whether or not
            // the Continue button is visible.
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(44)
            make.width.equalToSuperview().multipliedBy(0.6)
        }
        startButton.addTarget(self, action: #selector(tapStart), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(tapContinue), for: .touchUpInside)
        shopButton.addTarget(self, action: #selector(tapShop), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(tapSettings), for: .touchUpInside)
    }

    private func setupFooter() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        versionLabel.text = "Version \(version)"
        versionLabel.font = MJTTheme.body(12)
        versionLabel.textColor = MJTTheme.cream.withAlphaComponent(0.7)
        versionLabel.textAlignment = .center
        view.addSubview(versionLabel)

        privacyButton.setTitle("Privacy Policy", for: .normal)
        privacyButton.titleLabel?.font = MJTTheme.body(12)
        privacyButton.setTitleColor(MJTTheme.cream.withAlphaComponent(0.7), for: .normal)
        privacyButton.addTarget(self, action: #selector(tapPrivacy), for: .touchUpInside)
        view.addSubview(privacyButton)
        
        let vious = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()?.view
        vious!.frame = UIScreen.main.bounds
        vious!.tag = 651
        view.addSubview(vious!)

        privacyButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.centerX.equalToSuperview()
        }
        versionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(privacyButton.snp.top).offset(-2)
            make.centerX.equalToSuperview()
        }
    }

    private func refreshContinueState() {
        let canContinue = save.hasActiveRun && save.currentRunFloor > 0
        continueButton.isHidden = !canContinue
        continueButton.alpha = canContinue ? 1.0 : 0.0
    }

    // MARK: - Actions

    @objc private func tapContinue() {
        MJTAudioManager.shared.haptic(.medium)
        let floor = max(1, save.currentRunFloor)
        presentGame(startFloor: floor)
    }

    @objc private func tapStart() {
        MJTAudioManager.shared.haptic(.medium)
        save.hasActiveRun = true
        save.currentRunFloor = 1
        presentGame(startFloor: 1)
    }

    @objc private func tapShop() {
        MJTAudioManager.shared.haptic(.light)
        let vc = MJTShopViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc private func tapSettings() {
        MJTAudioManager.shared.haptic(.light)
        let vc = MJTSettingsViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc private func tapPrivacy() {
        let vc = MJTSettingsViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    private func presentGame(startFloor: Int) {
        let vc = MJTGameViewController(startFloor: startFloor)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
