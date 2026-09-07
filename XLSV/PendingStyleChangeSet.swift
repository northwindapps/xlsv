//
//  PendingStyleChangeSet.swift
//  XLSV
//
//  In-memory tracking of per-cell style edits (text color / fill color / font
//  size) made from the in-app format panel that haven't been written to the
//  .xlsx yet. Sibling of PendingXlsxChangeSet -- kept separate because style
//  edits are resolved through StyleTableEditor at flush time (one styles.xml
//  rewrite for the whole batch), not spliced per-edit.
//
//  Each entry is a *delta*: only the attributes the user actually changed are
//  non-nil. Repeated edits to the same cell merge (last write wins per attribute),
//  so toggling text color then font size on one cell leaves a single entry
//  carrying both.
//

import Foundation

struct PendingStyleEditKey: Hashable {
    let sheetIndex: Int
    let cellId: String   // A1-style, same as PendingXlsxEditKey
}

struct PendingStyleEdit {
    var textColorHex: String?   // "#RRGGBB", nil = leave text color as-is
    var fillColorHex: String?   // "#RRGGBB", nil = leave fill as-is
    var fontSize: Double?       // points, nil = leave size as-is

    var isEmpty: Bool { textColorHex == nil && fillColorHex == nil && fontSize == nil }
}

final class PendingStyleChangeSet {
    private(set) var edits: [PendingStyleEditKey: PendingStyleEdit] = [:]

    var isDirty: Bool { !edits.isEmpty }

    func record(sheetIndex: Int, cellId: String,
                textColorHex: String? = nil, fillColorHex: String? = nil, fontSize: Double? = nil) {
        let key = PendingStyleEditKey(sheetIndex: sheetIndex, cellId: cellId)
        var edit = edits[key] ?? PendingStyleEdit()
        if let textColorHex = textColorHex { edit.textColorHex = textColorHex }
        if let fillColorHex = fillColorHex { edit.fillColorHex = fillColorHex }
        if let fontSize = fontSize { edit.fontSize = fontSize }
        guard !edit.isEmpty else { return }
        edits[key] = edit
    }

    func edits(forSheet sheetIndex: Int) -> [PendingStyleEditKey: PendingStyleEdit] {
        edits.filter { $0.key.sheetIndex == sheetIndex }
    }

    func clear() {
        edits.removeAll()
    }
}
