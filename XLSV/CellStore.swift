//
//  CellStore.swift
//  XLSV
//
//  Consolidated per-cell storage, replacing the ~25 parallel arrays
//  (location/cellStyleId/tcolor/textsize/bgcolor/cellBold/cellItalic/...)
//  previously maintained independently in ViewController.swift,
//  FileFillViewController.swift, and PlaygroundViewController.swift.
//
//  See /Users/yano/.claude/plans/wise-prancing-firefly.md for the full
//  rationale, and the storeInput/cellStyleId desync bug this structurally
//  removes.
//
//  NOTE on dense vs. sparse: the plan's original design used a dense
//  ContiguousArray sized rows*columns, reasoning that CustomCollectionViewLayout
//  already pays an O(rows*columns) cost for the whole grid. That assumption
//  broke in practice: ROWSIZE/COLUMNSIZE are padded well past the actual
//  populated-data extent (COLUMNSIZE floors to AppDelegate.DEFAULT_COLUMN_NUMBER
//  = 201 regardless of how many columns actually have data), so a 100,000-row
//  x 15-populated-column load-test file produced a 100,000 x 201 = ~20.1M-cell
//  dense allocation instead of the ~1.5M cells that actually had data -- a
//  multi-GB allocation that hung the app. Switched to sparse storage (keyed by
//  row/col, only populated cells allocated) to fix that; this is closer to
//  what the old styleIndexByLocation Dictionary already cost, not a regression
//  past the original baseline.
//

import Foundation

struct BorderEdge {
    var style: String
    var color: String
}

private struct CellKey: Hashable {
    var row: Int
    var col: Int
}

/// One cell's full state -- content, resolved style, and formula membership --
/// as a single value instead of being spread across ~25 parallel arrays keyed
/// by the same index. A "new cell" write is one assignment to one CellRecord,
/// so partially-updating a cell's content without its style (the storeInput/
/// cellStyleId bug this replaces) is not representable.
struct CellRecord {
    // true for any position that had an explicit entry in the source `location`
    // array (even a blank-content merge-anchor cell, per readExcel2's
    // mergedAnchorLoop) -- distinguishes "written, but empty" from "never
    // touched", matching `locationIndex(for:) != nil`'s exact semantics rather
    // than inferring it from content/styleId being non-default.
    var hasEntry = false
    var content: String = ""
    var styleId: Int = -1

    var fontSize: String = ""
    var fontColor: String = ""
    var bgColor: String = ""

    var bold = false
    var italic = false
    var underline = false
    var strike = false

    var borderLeft: BorderEdge?
    var borderRight: BorderEdge?
    var borderTop: BorderEdge?
    var borderBottom: BorderEdge?

    var horizontalAlign: String = ""
    var verticalAlign: String = ""
    var wrapText = false

    // Resolved xlsx number-format id for this cell (mirrors what
    // appd.numFmtIds[appd.excelStyleIdx[styleId]] resolves to today via the
    // legacy AppDelegate.excelStyleLocation path) -- -1 means "no explicit
    // number format". The format-code string itself (appd.formatCodes) stays
    // in AppDelegate's small per-unique-style tables; only the per-cell
    // pointer into that table lives here.
    var numFmtId: Int = -1

    // Formula text (without the leading "="), nil for a non-formula cell.
    // Replaces f_location/f_location_alphabet membership checks --
    // `record.formula != nil` is the "is this a formula cell" test.
    var formula: String?
    // The formula's last computed result (mirrors f_calculated), i.e. what
    // actually gets displayed for a formula cell -- distinct from `formula`
    // (the source text) and from `content` (which, for a formula cell, holds
    // whatever the original `content` array held there, unused for display
    // in this case but preserved for parity with the old array).
    var calculatedValue: String?

    var isEmpty: Bool {
        content.isEmpty && formula == nil
    }
}

/// Sparse store for one sheet's cells, keyed by (row, col) -- only positions
/// that actually have data are allocated, unlike a dense rows*columns array
/// (see the note at the top of this file for why dense was tried and dropped).
final class CellStore {
    private(set) var rows: Int
    private(set) var columns: Int
    private var cells: [CellKey: CellRecord] = [:]

    init(rows: Int, columns: Int) {
        self.rows = max(rows, 0)
        self.columns = max(columns, 0)
    }

    @inline(__always)
    func contains(row: Int, col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < columns
    }

    subscript(row: Int, col: Int) -> CellRecord {
        get {
            guard contains(row: row, col: col) else { return CellRecord() }
            return cells[CellKey(row: row, col: col)] ?? CellRecord()
        }
        set {
            guard contains(row: row, col: col) else { return }
            cells[CellKey(row: row, col: col)] = newValue
        }
    }

    /// All (row, col) positions currently holding a formula -- replaces
    /// iterating f_location/f_location_alphabet. O(populated cells), not
    /// O(rows*columns).
    var formulaCellPositions: [(row: Int, col: Int)] {
        cells.compactMap { key, record in
            record.formula != nil ? (key.row, key.col) : nil
        }
    }

    // MARK: - Row/column insert-delete
    //
    // All O(populated cells), not O(rows*columns) -- only entries whose
    // row/col actually shifts need touching.

    func insertRow(at row: Int) {
        guard row >= 0, row <= rows else { return }
        rows += 1
        var shifted: [CellKey: CellRecord] = [:]
        shifted.reserveCapacity(cells.count)
        for (key, record) in cells {
            shifted[key.row >= row ? CellKey(row: key.row + 1, col: key.col) : key] = record
        }
        cells = shifted
    }

    func deleteRow(at row: Int) {
        guard row >= 0, row < rows else { return }
        rows -= 1
        var shifted: [CellKey: CellRecord] = [:]
        shifted.reserveCapacity(cells.count)
        for (key, record) in cells {
            if key.row == row { continue }
            shifted[key.row > row ? CellKey(row: key.row - 1, col: key.col) : key] = record
        }
        cells = shifted
    }

    func insertColumn(at col: Int) {
        guard col >= 0, col <= columns else { return }
        columns += 1
        var shifted: [CellKey: CellRecord] = [:]
        shifted.reserveCapacity(cells.count)
        for (key, record) in cells {
            shifted[key.col >= col ? CellKey(row: key.row, col: key.col + 1) : key] = record
        }
        cells = shifted
    }

    func deleteColumn(at col: Int) {
        guard col >= 0, col < columns else { return }
        columns -= 1
        var shifted: [CellKey: CellRecord] = [:]
        shifted.reserveCapacity(cells.count)
        for (key, record) in cells {
            if key.col == col { continue }
            shifted[key.col > col ? CellKey(row: key.row, col: key.col - 1) : key] = record
        }
        cells = shifted
    }

    // MARK: - Bridging to/from the existing parallel-array shapes
    //
    // The on-disk JSON sidecar (ReadWriteJSON.swift) and readExcel2's
    // producer arrays are intentionally left unchanged by this refactor --
    // only content/location/styleId/fontsize/fontcolor/bgcolor round-trip
    // through storage; bold/italic/underline/strike/border/align/numFmtId
    // are never persisted directly, they're re-resolved from styleId each
    // load (see resolveStyles(appd:) below), matching resolveCellStyles()'s
    // existing behavior.

    /// Builds a store from the loaded/parsed parallel arrays (as produced by
    /// isExcelSheetData/readExcel2 today). `location` entries are "col,row"
    /// strings (0-based column in .item, section in .row -- matches the
    /// existing `String(indexPath.item)+","+String(indexPath.section)` key
    /// shape used throughout ViewController.swift).
    convenience init(
        rows: Int,
        columns: Int,
        location: [String],
        content: [String],
        styleId: [String],
        fontSize: [String],
        fontColor: [String],
        bgColor: [String]
    ) {
        self.init(rows: rows, columns: columns)
        cells.reserveCapacity(location.count)
        for i in 0..<location.count {
            let parts = location[i].split(separator: ",")
            guard parts.count == 2, let col = Int(parts[0]), let row = Int(parts[1]) else { continue }
            guard contains(row: row, col: col) else { continue }
            var record = CellRecord()
            record.hasEntry = true
            record.content = i < content.count ? content[i] : ""
            record.styleId = i < styleId.count ? (Int(styleId[i]) ?? -1) : -1
            record.fontSize = i < fontSize.count ? fontSize[i] : ""
            record.fontColor = i < fontColor.count ? fontColor[i] : ""
            record.bgColor = i < bgColor.count ? bgColor[i] : ""
            cells[CellKey(row: row, col: col)] = record
        }
    }

    /// Inverse of the above, for saveJsonFile's existing dict shape.
    /// Only includes non-empty cells, matching how the parallel arrays never
    /// carried entries for blank cells either.
    func toParallelArrays() -> (
        location: [String], content: [String], styleId: [String],
        fontSize: [String], fontColor: [String], bgColor: [String]
    ) {
        var location: [String] = []
        var content: [String] = []
        var styleId: [String] = []
        var fontSize: [String] = []
        var fontColor: [String] = []
        var bgColor: [String] = []
        location.reserveCapacity(cells.count)
        content.reserveCapacity(cells.count)
        styleId.reserveCapacity(cells.count)
        fontSize.reserveCapacity(cells.count)
        fontColor.reserveCapacity(cells.count)
        bgColor.reserveCapacity(cells.count)
        for (key, record) in cells {
            guard record.hasEntry else { continue }
            location.append("\(key.col),\(key.row)")
            content.append(record.content)
            styleId.append(record.styleId == -1 ? "" : String(record.styleId))
            fontSize.append(record.fontSize)
            fontColor.append(record.fontColor)
            bgColor.append(record.bgColor)
        }
        return (location, content, styleId, fontSize, fontColor, bgColor)
    }

    /// Resolves bold/italic/underline/strike/border/align/wrapText/numFmtId
    /// for every populated cell from its styleId against AppDelegate's
    /// per-unique-style tables -- the CellStore equivalent of
    /// ViewController.resolveCellStyles(). O(populated cells), not
    /// O(rows*columns). Kept as a method here (rather than duplicated per
    /// view controller) so all three VCs share one implementation once
    /// migrated.
    func resolveStyles(appd: AppDelegate) {
        for key in Array(cells.keys) {
            var record = cells[key]!
            defer { cells[key] = record }

            guard record.styleId >= 0,
                  record.styleId < appd.xfFontIds.count,
                  record.styleId < appd.xfFillIds.count else { continue }

            let fontId = appd.xfFontIds[record.styleId]
            if fontId >= 0 && fontId < appd.fontSizes.count {
                if !appd.fontSizes[fontId].isEmpty { record.fontSize = appd.fontSizes[fontId] }
                if !appd.fontColors[fontId].isEmpty { record.fontColor = appd.fontColors[fontId] }
                record.bold = appd.fontBolds[fontId]
                record.italic = appd.fontItalics[fontId]
                record.underline = appd.fontUnderlines[fontId]
                record.strike = appd.fontStrikes[fontId]
            }

            let fillId = appd.xfFillIds[record.styleId]
            if fillId >= 0 && fillId < appd.fillColors.count && !appd.fillColors[fillId].isEmpty {
                record.bgColor = appd.fillColors[fillId]
            }

            if record.styleId < appd.cellXfs.count {
                let borderId = appd.cellXfs[record.styleId]
                if borderId >= 0 && borderId < appd.borderLeftStyles.count {
                    record.borderLeft = BorderEdge(style: appd.borderLeftStyles[borderId], color: appd.borderLeftColors[borderId])
                    record.borderRight = BorderEdge(style: appd.borderRightStyles[borderId], color: appd.borderRightColors[borderId])
                    record.borderTop = BorderEdge(style: appd.borderTopStyles[borderId], color: appd.borderTopColors[borderId])
                    record.borderBottom = BorderEdge(style: appd.borderBottomStyles[borderId], color: appd.borderBottomColors[borderId])
                }
            }

            if record.styleId < appd.xfHorizontalAligns.count {
                record.horizontalAlign = appd.xfHorizontalAligns[record.styleId]
                record.verticalAlign = appd.xfVerticalAligns[record.styleId]
                record.wrapText = appd.xfWrapTexts[record.styleId]
            }

            // Matches cellForItemAt's legacy numFmt lookup
            // (appd.numFmtIds[appd.excelStyleIdx[styleId]], ViewController.swift:883)
            // one-for-one -- styleId here is the same "s" attribute index.
            if record.styleId < appd.numFmtIds.count {
                record.numFmtId = appd.numFmtIds[record.styleId]
            }
        }
    }
}
