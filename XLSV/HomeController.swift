//
//  HomeController.swift
//  XLSV
//
//  Created by yano on 2026/07/19.
//  Copyright © 2026 Credera. All rights reserved.
//

import UIKit

class HomeController: UIViewController {

    // Temporary instrumentation for the window.rootViewController-swap leak
    // investigation (see [[project_rootviewcontroller_swap_leak]] memory note) --
    // confirms whether dismiss()-before-swap actually lets this instance deallocate.
    // Safe to remove once the fix is confirmed on-device.
    deinit {
        print("DEINIT HomeController \(ObjectIdentifier(self))")
    }

    // Tapping a mode button below synchronously runs that mode's viewDidLoad
    // (loadExcelSheet included) as part of instantiateViewController/present --
    // there's no background threading for this yet, so on a large file that's a
    // multi-second freeze with zero feedback today. This overlay just gives the
    // user something to look at during that freeze; it doesn't make the load
    // itself any faster.
    private let loadingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let loadingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private func showLoading() {
        view.bringSubview(toFront: loadingOverlay)
        loadingOverlay.isHidden = false
        loadingSpinner.startAnimating()
        view.isUserInteractionEnabled = false
    }

    private func hideLoading() {
        loadingSpinner.stopAnimating()
        loadingOverlay.isHidden = true
        view.isUserInteractionEnabled = true
    }

    private func makeButton(title: String, subtitle: String) -> UIButton {
        let button = UIButton(type: .system)

        let attributedTitle = NSMutableAttributedString(
            string: title + "\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.label,
            ]
        )
        attributedTitle.append(NSAttributedString(
            string: subtitle,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
            ]
        ))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        return button
    }

    private func makeSettingsButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Settings"
        return button
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "XLSV"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "An xlsx file viewer"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let spreadsheetButton = makeButton(title: "Spreadsheet", subtitle: "Good for making a simple, general sheet")
        spreadsheetButton.addTarget(self, action: #selector(openSpreadsheet), for: .touchUpInside)

        let formFillButton = makeButton(title: "Form Fill", subtitle: "Good for filling forms made with xlsx")
        formFillButton.addTarget(self, action: #selector(openFormFill), for: .touchUpInside)

        let playgroundButton = makeButton(title: "Playground", subtitle: "Good for checking 3D surface graphs")
        playgroundButton.addTarget(self, action: #selector(openPlayground), for: .touchUpInside)

        let settingsButton = makeSettingsButton()
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        var stackButtons: [UIButton] = [spreadsheetButton, formFillButton, playgroundButton]

        // Only shown when LegacyFileCheckViewController's migration (run before this
        // screen ever appears) actually found something -- everyone else sees the
        // normal 3-button Home unchanged. Without this, the one-time "Files Recovered"
        // alert told the user their data was under "Recovered Files" with no actual way
        // to reach that screen from here -- confirmed missing 2026-08-24.
        if LegacyMigration.hasRecoveredFiles() {
            let recoveredFilesButton = makeButton(title: "Recovered Files", subtitle: "Sheets recovered from an earlier version of this app")
            recoveredFilesButton.addTarget(self, action: #selector(openRecoveredFiles), for: .touchUpInside)
            stackButtons.append(recoveredFilesButton)
        }

        let stack = UIStackView(arrangedSubviews: stackButtons)
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let disclaimerLabel = UILabel()
        disclaimerLabel.text = "⚠️ Always keep a backup of your original xlsx file before editing — do not rely on this app as your only copy of important data."
        disclaimerLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        disclaimerLabel.textColor = .secondaryLabel
        disclaimerLabel.textAlignment = .center
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false

        let creditLabel = UILabel()
        creditLabel.text = "© 2019 Yujin Yano. All rights reserved."
        creditLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        creditLabel.textColor = .tertiaryLabel
        creditLabel.textAlignment = .center
        creditLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(stack)
        view.addSubview(disclaimerLabel)
        view.addSubview(creditLabel)
        view.addSubview(settingsButton)

        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(loadingSpinner)

        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 32),
            settingsButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            creditLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            creditLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            creditLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            disclaimerLabel.bottomAnchor.constraint(equalTo: creditLabel.topAnchor, constant: -8),
            disclaimerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            disclaimerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingSpinner.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentMigrationNoticeIfNeeded()
    }

    // TEMPORARY -- this entire method exists only for the one final release shipped under
    // com.yumiya.xlsv2 before this app moves to the com.yumiya.blueframe App Store listing
    // (~13k existing installs there vs ~280 here -- see Claude's memory
    // `project_xlsv_repo_family_and_v205_migration` for the full reasoning). Remove this
    // method and its call in viewDidAppear once that release has shipped and this bundle ID
    // is no longer being updated.
    //
    // HomeController persists for the life of the process (mode screens are presented on top
    // of it, not replacing it), so this fires once per launch -- not once per return to Home.
    private func presentMigrationNoticeIfNeeded() {
        let alert = UIAlertController(
            title: "Important Notice",
            message: """
            XLSV is moving to a new App Store listing. This app will not receive further updates.

            To keep using XLSV, please search the App Store for “XLSV” and install the new listing.

            This is a separate app and will not have your existing files. Before switching, open a file, tap MENU, and use Export (Files or Email) to save a copy you can bring over.
            """,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func openSpreadsheet() {
        showLoading()
        // The spinner has to actually get a runloop turn to paint before the
        // synchronous instantiateViewController/present below blocks the main
        // thread -- without this hop, startAnimating() and the freeze would be
        // scheduled in the same runloop pass and nothing would ever be drawn.
        DispatchQueue.main.async {
            let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "StartLine") as! ViewController
            targetViewController.modalPresentationStyle = .fullScreen
            self.present(targetViewController, animated: true) {
                self.hideLoading()
            }
        }
    }

    @objc private func openFormFill() {
        showLoading()
        DispatchQueue.main.async {
            let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "Filefill") as! FileFillViewController
            targetViewController.modalPresentationStyle = .fullScreen
            self.present(targetViewController, animated: true) {
                self.hideLoading()
            }
        }
    }

    @objc private func openPlayground() {
        showLoading()
        DispatchQueue.main.async {
            let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "StartLine2") as! PlaygroundViewController
            targetViewController.modalPresentationStyle = .fullScreen
            self.present(targetViewController, animated: true) {
                self.hideLoading()
            }
        }
    }

    @objc private func openRecoveredFiles() {
        let listViewController = RecoveredFilesViewController()
        let nav = UINavigationController(rootViewController: listViewController)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func openSettings() {
        // No file is open yet at this point (this is the home screen), so
        // SettingsViewController's idx stays nil -- its own showAnimate()
        // already handles that case by falling back to StartLine rather than
        // trying to reload a specific sheet.
        let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "Settings") as! SettingsViewController
        targetViewController.modalPresentationStyle = .fullScreen
        self.present(targetViewController, animated: true, completion: nil)
    }
}
