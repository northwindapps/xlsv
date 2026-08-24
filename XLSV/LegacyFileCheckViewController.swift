//
//  LegacyFileCheckViewController.swift
//  XLSV
//
//  Shown once, at cold launch, BEFORE Home (this app's usual entry point) -- checks for and
//  safely moves any files left over from the 1.3.6-era format (see LegacyMigration.swift) before
//  the user ever reaches the app's normal UI.
//
//  Deliberately does NOT touch Documents/importedExcel/ or any other path this app treats as
//  "the active file" -- LegacyMigration only ever moves files into Documents/RecoveredFiles/, a
//  separate, safe holding area. This app's own AppDelegate.application(_:open:) was found to
//  unconditionally overwrite its default active-file slot (Documents/importedExcel/initialXLSX_ff.xlsx)
//  on an incoming "Open in XLSV" -- this screen avoids that exact failure mode by never writing
//  anywhere near that path, only ever landing recovered files in their own separate folder.
//
//  Ported from the xlsv-205 (com.yumiya.blueframe) codebase 2026-08-24, now that this app has
//  taken over that bundle ID and is the one that will actually receive upgrading users'
//  Documents containers. The only real change from that version: proceeds to "Home" (this app's
//  storyboard identifier for its entry point), not "StartLine".
//
//  Built entirely in code, no storyboard scene -- matches RecoveredFilesViewController.swift's
//  own precedent for this feature.
//
import UIKit

class LegacyFileCheckViewController: UIViewController {

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Old-style enum initializer (matches the same pattern already used elsewhere in this repo,
    // e.g. BackupTableViewController's loadingSpinner) rather than UIActivityIndicatorView(style:).
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        statusLabel.text = "Checking for files from a previous version..."

        view.addSubview(spinner)
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
        spinner.startAnimating()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Off the main thread so the spinner actually animates rather than showing a frozen
        // frame -- the work itself (a directory listing + a handful of file moves, see
        // LegacyMigration.migrateLegacySheetsIfNeeded()) is cheap, and this screen is on the
        // critical path for every single launch, not just upgrading users, so it needs to stay
        // fast and not block the main thread regardless.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Count of files actually moved *by this call*, not how many currently sit in
            // Documents/RecoveredFiles/ -- that count stays nonzero forever once anything's
            // been recovered, which would re-show the alert below on every single launch
            // instead of just the one right after migration finds something new.
            let movedCount = LegacyMigration.migrateLegacySheetsIfNeeded()
            DispatchQueue.main.async {
                self?.proceedToHome(recoveredCount: movedCount)
            }
        }
    }

    private func proceedToHome(recoveredCount: Int) {
        let storyboard = self.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        let home = storyboard.instantiateViewController(withIdentifier: "Home")
        home.modalPresentationStyle = .fullScreen

        let swapToHome = {
            // This is the very first screen shown at cold launch -- nothing is presented on
            // top of it yet, so a direct rootViewController swap is safe here (no dismiss-first
            // step needed, unlike swapping root mid-lifecycle with other screens already
            // presented above it -- see the rootViewController-swap-leak lesson elsewhere in
            // this app's history for why that distinction matters).
            let appd = UIApplication.shared.delegate as? AppDelegate
            appd?.window?.rootViewController = home
        }

        guard recoveredCount > 0 else {
            swapToHome()
            return
        }

        // Only shown when there's actually something to tell the user about -- everyone else
        // (the overwhelming majority of launches, and every launch after the first one
        // post-update) sees no dialog at all, just a brief spinner frame before Home appears.
        let message = recoveredCount == 1
            ? "Found 1 file from a previous version of this app. It's been saved safely and is available under \u{201C}Recovered Files\u{201D}."
            : "Found \(recoveredCount) files from a previous version of this app. They've been saved safely and are available under \u{201C}Recovered Files\u{201D}."
        let alert = UIAlertController(title: "Files Recovered", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in swapToHome() })
        present(alert, animated: true)
    }
}
