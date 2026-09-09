//
//  SheetContextBuilder.swift
//  XLSV
//
//  Turns the in-memory parallel arrays (location/content/f_location/
//  f_calculated) that both ViewController and FileFillViewController maintain
//  into a compact text table the LLM can read. Works off a plain-value
//  SheetSnapshot rather than touching either controller, mirroring how
//  CellStore's convenience init takes the arrays by value.
//
//  Serialization format is TSV with a spreadsheet-style header row (A, B, C...)
//  and 1-based row numbers in the first column, e.g.
//
//      \tA\tB\tC
//      1\tName\tQty\tPrice
//      2\tApple\t3\t1.20
//
//  Fully-empty rows and trailing empty columns are dropped. Formula cells are
//  shown as their computed value (what the user sees on screen), not the
//  formula text.
//

import Foundation

struct SheetSnapshot {
    let name: String
    let rowSize: Int
    let columnSize: Int
    /// "col,row" 0-based keys, index-aligned with `content`.
    let location: [String]
    let content: [String]
    /// "col,row" 0-based keys, index-aligned with `formulaResult`.
    let formulaLocation: [String]
    let formulaResult: [String]
}

enum SheetContextBuilder {

    /// 0-based column index -> "A", "B", ... "Z", "AA", ...
    static func columnLetter(_ index: Int) -> String {
        var n = index
        var s = ""
        repeat {
            s = String(UnicodeScalar(UInt8(65 + n % 26))) + s
            n = n / 26 - 1
        } while n >= 0
        return s
    }

    struct Result {
        let text: String
        let cellsIncluded: Int
        let truncated: Bool
    }

    /// Serializes the whole snapshot, stopping once `maxCells` populated cells
    /// have been emitted.
    static func table(from snapshot: SheetSnapshot, maxCells: Int) -> Result {
        let values = mergedValues(snapshot)
        return render(values: values,
                      rowSize: snapshot.rowSize,
                      columnSize: snapshot.columnSize,
                      restrictTo: nil,
                      maxCells: maxCells)
    }

    /// Serializes only the cells in `selection` (IndexPath.item = column,
    /// IndexPath.section = row -- matching tempRangeSelected throughout both
    /// view controllers).
    static func table(from snapshot: SheetSnapshot,
                      selection: [IndexPath],
                      maxCells: Int) -> Result {
        guard !selection.isEmpty else {
            return Result(text: "(no cells selected)", cellsIncluded: 0, truncated: false)
        }
        let allowed = Set(selection.map { "\($0.item),\($0.section)" })
        let values = mergedValues(snapshot)
        return render(values: values,
                      rowSize: snapshot.rowSize,
                      columnSize: snapshot.columnSize,
                      restrictTo: allowed,
                      maxCells: maxCells)
    }

    // MARK: - Private

    /// One "col,row" -> display-string map, formula results overriding raw
    /// content at the same position.
    private static func mergedValues(_ s: SheetSnapshot) -> [String: String] {
        var map: [String: String] = [:]
        map.reserveCapacity(s.content.count + s.formulaResult.count)
        for i in 0..<min(s.location.count, s.content.count) {
            let v = s.content[i]
            if !v.isEmpty { map[s.location[i]] = v }
        }
        for i in 0..<min(s.formulaLocation.count, s.formulaResult.count) {
            let v = s.formulaResult[i]
            if !v.isEmpty { map[s.formulaLocation[i]] = v }
        }
        return map
    }

    private static func render(values: [String: String],
                               rowSize: Int,
                               columnSize: Int,
                               restrictTo allowed: Set<String>?,
                               maxCells: Int) -> Result {
        // Bound the scan to where data actually is -- ROWSIZE/COLUMNSIZE are
        // padded well past the populated extent (see CellStore's notes).
        var maxRow = -1
        var maxCol = -1
        for key in values.keys {
            let parts = key.split(separator: ",")
            guard parts.count == 2, let c = Int(parts[0]), let r = Int(parts[1]) else { continue }
            if allowed != nil && !allowed!.contains(key) { continue }
            if r > maxRow { maxRow = r }
            if c > maxCol { maxCol = c }
        }
        guard maxRow >= 0, maxCol >= 0 else {
            return Result(text: "(no data)", cellsIncluded: 0, truncated: false)
        }
        maxRow = min(maxRow, max(rowSize - 1, 0))
        maxCol = min(maxCol, max(columnSize - 1, 0))

        var lines: [String] = []
        // Header: blank corner + column letters.
        lines.append("\t" + (0...maxCol).map { columnLetter($0) }.joined(separator: "\t"))

        var included = 0
        var truncated = false

        rowLoop: for r in 0...maxRow {
            var cells: [String] = []
            var rowHasData = false
            for c in 0...maxCol {
                let key = "\(c),\(r)"
                if allowed != nil && !allowed!.contains(key) {
                    cells.append("")
                    continue
                }
                if let v = values[key], !v.isEmpty {
                    if included >= maxCells {
                        truncated = true
                        break rowLoop
                    }
                    // Guard the TSV structure against embedded tabs/newlines.
                    let safe = v.replacingOccurrences(of: "\t", with: " ")
                               .replacingOccurrences(of: "\n", with: " ")
                    cells.append(safe)
                    rowHasData = true
                    included += 1
                } else {
                    cells.append("")
                }
            }
            if rowHasData {
                // Trim trailing empties for compactness.
                while let last = cells.last, last.isEmpty { cells.removeLast() }
                lines.append("\(r + 1)\t" + cells.joined(separator: "\t"))
            }
        }

        return Result(text: lines.joined(separator: "\n"),
                      cellsIncluded: included,
                      truncated: truncated)
    }
}
