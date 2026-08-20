//
//  V2RecoveredFilesViewController.swift
//  MultiDirectionCollectionView
//
//  Read-only recovery UI for 1.3.6-era legacy sheets that V2LegacyMigration.swift moved out of
//  Documents/sub/ into Documents/RecoveredFiles/. This does not re-integrate recovered sheets into
//  the live editable workbook - it simply lets the user see the data is safe, inspect it, and
//  export it (via the share sheet) if they want to save/email it elsewhere.
//
//  Built entirely in code (no storyboard scene) and presented via self.present(...), matching the
//  modal-presentation pattern already used throughout V2ViewController.swift for its other screens.
//
import UIKit

/// Lists the sheets currently sitting in Documents/RecoveredFiles/, one row per recovered sheet.
class V2RecoveredFilesViewController: UITableViewController {

    private static let cellReuseIdentifier = "RecoveredFileCell"

    private var fileNames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recovered Files"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: V2RecoveredFilesViewController.cellReuseIdentifier)
        reloadFileList()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFileList()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func reloadFileList() {
        fileNames = V2RecoveredFilesViewController.recoveredFileNames()
        tableView.reloadData()
    }

    static func recoveredDirectory() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("RecoveredFiles")
    }

    static func recoveredFileNames() -> [String] {
        guard let dir = recoveredDirectory() else { return [] }
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return entries
            .map { url -> (String, Date) in
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                return (url.lastPathComponent, date)
            }
            .sorted(by: { $0.1 > $1.1 })
            .map { $0.0 }
    }

    // MARK: - UITableViewDataSource / Delegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileNames.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Sheets recovered from an earlier version of the app"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: V2RecoveredFilesViewController.cellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = fileNames[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let dir = V2RecoveredFilesViewController.recoveredDirectory() else { return }
        let fileName = fileNames[indexPath.row]
        let detail = V2RecoveredSheetDetailViewController(fileURL: dir.appendingPathComponent(fileName), sheetTitle: fileName)
        navigationController?.pushViewController(detail, animated: true)
    }
}

/// Shows the raw cell contents of a single recovered sheet, and offers a CSV export via the share
/// sheet (Mail, Save to Files, AirDrop, etc). Reads the same JSON schema as
/// V2ReadWriteJSON.old_readJsonForSheet(title:), but against an arbitrary file URL (the file has
/// already been moved out of Documents/sub/ by the time this runs).
class V2RecoveredSheetDetailViewController: UITableViewController {

    private static let cellReuseIdentifier = "RecoveredCellRow"

    private let fileURL: URL
    private var rows: [(location: String, content: String)] = []

    init(fileURL: URL, sheetTitle: String) {
        self.fileURL = fileURL
        super.init(style: .plain)
        self.title = sheetTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: V2RecoveredSheetDetailViewController.cellReuseIdentifier)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(exportTapped)
        )
        loadContent()
    }

    private func loadContent() {
        guard let data = try? Data(contentsOf: fileURL),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = jsonObject as? [String: Any] else {
            print("V2RecoveredSheetDetailViewController: failed to read \(fileURL.lastPathComponent)")
            return
        }

        let content = dict["content"] as? [String] ?? []
        let location = dict["location"] as? [String] ?? []

        var combined: [(String, String)] = []
        for i in 0..<min(content.count, location.count) {
            let cellValue = content[i]
            if cellValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            combined.append((V2RecoveredSheetDetailViewController.excelLocation(from: location[i]), cellValue))
        }

        // Sort by column-then-row so the list reads roughly the way the original sheet looked.
        combined.sort { $0.0 < $1.0 }
        rows = combined.map { (location: $0.0, content: $0.1) }
    }

    /// Converts the legacy "column,row" location format (e.g. "1,4") into an Excel-style
    /// reference (e.g. "A4"). Falls back to the raw string if it can't be parsed.
    static func excelLocation(from raw: String) -> String {
        let parts = raw.components(separatedBy: ",")
        guard parts.count == 2, let column = Int(parts[0]) else { return raw }
        return excelColumnName(columnNumber: column) + parts[1]
    }

    static func excelColumnName(columnNumber: Int) -> String {
        var dividend = columnNumber
        var columnName = ""
        while dividend > 0 {
            let modulo = (dividend - 1) % 26
            if let scalar = UnicodeScalar(65 + modulo) {
                columnName = String(Character(scalar)) + columnName
            }
            dividend = (dividend - modulo) / 26
        }
        return columnName
    }

    @objc private func exportTapped() {
        guard !rows.isEmpty else { return }

        var csv = "Cell,Value\n"
        for row in rows {
            let escapedValue = row.content.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(row.location),\"\(escapedValue)\"\n"
        }

        let safeFileName = (title ?? "RecoveredSheet")
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeFileName)
            .appendingPathExtension("csv")

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            print("V2RecoveredSheetDetailViewController: failed to write CSV export: \(error.localizedDescription)")
            return
        }

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(activityVC, animated: true)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: V2RecoveredSheetDetailViewController.cellReuseIdentifier, for: indexPath)
        let row = rows[indexPath.row]
        cell.textLabel?.text = "\(row.location): \(row.content)"
        cell.textLabel?.numberOfLines = 2
        cell.selectionStyle = .none
        return cell
    }
}
