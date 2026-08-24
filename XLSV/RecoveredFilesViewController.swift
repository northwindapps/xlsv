//
//  RecoveredFilesViewController.swift
//  XLSV
//
//  Read-only recovery UI for 1.3.6-era legacy sheets that LegacyMigration.swift moved out of
//  Documents/sub/ into Documents/RecoveredFiles/. This does not re-integrate recovered sheets into
//  the live editable workbook - it simply lets the user see the data is safe, inspect it, and
//  export it (via the share sheet) if they want to save/email it elsewhere.
//
//  Built entirely in code (no storyboard scene) and presented via self.present(...), matching the
//  modal-presentation pattern already used throughout ViewController.swift for its other screens.
//
//  Ported from the xlsv-205 (com.yumiya.blueframe) codebase 2026-08-24, now that this app has
//  taken over that bundle ID -- see LegacyMigration.swift's header comment for why.
//
import UIKit

/// Lists the sheets currently sitting in Documents/RecoveredFiles/, one row per recovered sheet.
class RecoveredFilesViewController: UITableViewController {

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: RecoveredFilesViewController.cellReuseIdentifier)
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
        fileNames = RecoveredFilesViewController.recoveredFileNames()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: RecoveredFilesViewController.cellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = fileNames[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let dir = RecoveredFilesViewController.recoveredDirectory() else { return }
        let fileName = fileNames[indexPath.row]
        let detail = RecoveredSheetDetailViewController(fileURL: dir.appendingPathComponent(fileName), sheetTitle: fileName)
        navigationController?.pushViewController(detail, animated: true)
    }
}

/// Shows the raw cell contents of a single recovered sheet, and offers a CSV export via the share
/// sheet (Mail, Save to Files, AirDrop, etc). Reads the same JSON schema as
/// ReadWriteJSON.old_readJsonForSheet(title:), but against an arbitrary file URL (the file has
/// already been moved out of Documents/sub/ by the time this runs).
class RecoveredSheetDetailViewController: UITableViewController {

    private static let cellReuseIdentifier = "RecoveredCellRow"

    private let fileURL: URL
    private var rows: [(location: String, content: String)] = []

    // (column, row) here are relative, 0-based positions within the recovered sheet's own used
    // range -- NOT 1.3.6's raw stored indices. The original app's row/column numbering scheme
    // (e.g. whether index 0 is a real data column or a header gutter) couldn't be confirmed with
    // certainty from the source alone -- exporting positions *relative to each other* sidesteps
    // that entirely: whatever the raw indices mean, cells preserve their relative layout, which
    // is what "does this look like my sheet" actually depends on.
    private var cells: [(column: Int, row: Int, value: String)] = []
    private var columnCount = 0
    private var rowCount = 0

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: RecoveredSheetDetailViewController.cellReuseIdentifier)
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
            print("RecoveredSheetDetailViewController: failed to read \(fileURL.lastPathComponent)")
            return
        }

        let content = dict["content"] as? [String] ?? []
        let location = dict["location"] as? [String] ?? []

        var raw: [(column: Int, row: Int, value: String)] = []
        for i in 0..<min(content.count, location.count) {
            let cellValue = content[i]
            if cellValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            let parts = location[i].components(separatedBy: ",")
            guard parts.count == 2, let column = Int(parts[0]), let row = Int(parts[1]) else { continue }
            raw.append((column: column, row: row, value: cellValue))
        }

        guard !raw.isEmpty else {
            rows = []
            return
        }

        let minColumn = raw.map { $0.column }.min()!
        let minRow = raw.map { $0.row }.min()!
        let maxColumn = raw.map { $0.column }.max()!
        let maxRow = raw.map { $0.row }.max()!

        cells = raw.map { (column: $0.column - minColumn, row: $0.row - minRow, value: $0.value) }
        columnCount = maxColumn - minColumn + 1
        rowCount = maxRow - minRow + 1

        // Sort by row-then-column so the list reads roughly the way the original sheet looked.
        let sorted = cells.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        rows = sorted.map { cell in
            let cellRef = ExcelHelper().GetExcelColumnName(columnNumber: cell.column + 1) + String(cell.row + 1)
            return (location: cellRef, content: cell.value)
        }
    }

    @objc private func exportTapped() {
        guard !cells.isEmpty else { return }

        // A real spreadsheet-shaped CSV -- one line per row, values comma-separated in their
        // actual column position (blank for an empty cell) -- so opening it in Excel/Numbers/etc
        // reproduces the sheet's layout, not just a "Cell,Value" pair dump.
        var grid = [[String]](repeating: [String](repeating: "", count: columnCount), count: rowCount)
        for cell in cells {
            grid[cell.row][cell.column] = cell.value
        }

        var csv = ""
        for row in grid {
            csv += row.map { RecoveredSheetDetailViewController.csvEscape($0) }.joined(separator: ",") + "\n"
        }

        let safeFileName = (title ?? "RecoveredSheet")
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeFileName)
            .appendingPathExtension("csv")

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            print("RecoveredSheetDetailViewController: failed to write CSV export: \(error.localizedDescription)")
            return
        }

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(activityVC, animated: true)
    }

    /// Quotes a field only when it actually needs it (contains a comma, quote, or newline) --
    /// matches standard CSV convention rather than quoting every field unconditionally.
    private static func csvEscape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecoveredSheetDetailViewController.cellReuseIdentifier, for: indexPath)
        let row = rows[indexPath.row]
        cell.textLabel?.text = "\(row.location): \(row.content)"
        cell.textLabel?.numberOfLines = 2
        cell.selectionStyle = .none
        return cell
    }
}
