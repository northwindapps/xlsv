//
//  HomeController.swift
//  XLSV
//
//  Created by yano on 2026/07/19.
//  Copyright © 2026 Credera. All rights reserved.
//

import UIKit

class HomeController: UIViewController {

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

        let stack = UIStackView(arrangedSubviews: [spreadsheetButton, formFillButton, playgroundButton])
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

        NSLayoutConstraint.activate([
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
        ])
    }

    @objc private func openSpreadsheet() {
        let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "StartLine") as! ViewController
        targetViewController.modalPresentationStyle = .fullScreen
        self.present(targetViewController, animated: true, completion: nil)
    }

    @objc private func openFormFill() {
        let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "Filefill") as! FileFillViewController
        targetViewController.modalPresentationStyle = .fullScreen
        self.present(targetViewController, animated: true, completion: nil)
    }

    @objc private func openPlayground() {
        let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "StartLine2") as! PlaygroundViewController
        targetViewController.modalPresentationStyle = .fullScreen
        self.present(targetViewController, animated: true, completion: nil)
    }
}
