//
//  MJTSettingsViewController.swift
//  Mahjong Tower
//
//  Toggles for Music / Sound / Vibration plus legal links.
//

import UIKit
import SnapKit

final class MJTSettingsViewController: UIViewController {

    private let save = MJTSaveManager.shared
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MJTTheme.jadeDark
        setupHeader()
        setupContent()
    }

    private func setupHeader() {
        let header = UILabel()
        header.text = "Settings"
        header.font = MJTTheme.title(30)
        header.textColor = MJTTheme.gold
        view.addSubview(header)

        let close = UIButton(type: .system)
        close.setTitle("✕", for: .normal)
        close.titleLabel?.font = MJTTheme.title(24)
        close.setTitleColor(MJTTheme.cream, for: .normal)
        close.addTarget(self, action: #selector(tapClose), for: .touchUpInside)
        view.addSubview(close)

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
    }

    private func setupContent() {
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(70)
            make.left.right.equalToSuperview().inset(20)
        }

        stack.addArrangedSubview(toggleRow("Music", isOn: save.musicEnabled) { [weak self] on in
            self?.save.musicEnabled = on
        })
        stack.addArrangedSubview(toggleRow("Sound", isOn: save.soundEnabled) { [weak self] on in
            self?.save.soundEnabled = on
        })
        stack.addArrangedSubview(toggleRow("Vibration", isOn: save.vibrationEnabled) { [weak self] on in
            self?.save.vibrationEnabled = on
        })

        stack.addArrangedSubview(linkRow("Privacy Policy") { [weak self] in
            self?.showLegal(title: "Privacy Policy", body: MJTLegalText.privacy)
        })
        stack.addArrangedSubview(linkRow("Terms of Use") { [weak self] in
            self?.showLegal(title: "Terms of Use", body: MJTLegalText.terms)
        })
    }

    private func toggleRow(_ title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> UIView {
        let row = makeRow(title)
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = MJTTheme.jadeLight
        toggle.addAction(UIAction { _ in
            onChange(toggle.isOn)
            MJTAudioManager.shared.haptic(.light)
        }, for: .valueChanged)
        row.addSubview(toggle)
        toggle.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        return row
    }

    private func linkRow(_ title: String, action: @escaping () -> Void) -> UIView {
        let row = makeRow(title)
        let chevron = UILabel()
        chevron.text = "›"
        chevron.font = MJTTheme.title(22)
        chevron.textColor = MJTTheme.cream.withAlphaComponent(0.7)
        row.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(ClosureTapGesture(action))
        return row
    }

    private func makeRow(_ title: String) -> UIView {
        let row = UIView()
        row.backgroundColor = MJTTheme.panel
        row.layer.cornerRadius = 12
        row.snp.makeConstraints { $0.height.equalTo(56) }
        let label = UILabel()
        label.text = title
        label.font = MJTTheme.body(17)
        label.textColor = MJTTheme.cream
        row.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        return row
    }

    private func showLegal(title: String, body: String) {
        let vc = MJTLegalViewController(titleText: title, bodyText: body)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    private func toast(_ text: String) {
        let label = PaddingLabel()
        label.text = text
        label.font = MJTTheme.body(14)
        label.textColor = MJTTheme.ink
        label.backgroundColor = MJTTheme.gold
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.alpha = 0
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
        }
        UIView.animate(withDuration: 0.2, animations: { label.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.2) { label.alpha = 0 } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }

    @objc private func tapClose() { dismiss(animated: true) }
}

/// A tap gesture recognizer that invokes a stored closure (retained by self).
final class ClosureTapGesture: UITapGestureRecognizer {
    private let action: () -> Void
    init(_ action: @escaping () -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(fire))
    }
    @objc private func fire() { action() }
}

final class PaddingLabel: UILabel {
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + 28, height: s.height + 16)
    }
}
