//
//  PendingXlsxChangeSet.swift
//  XLSV
//
//  In-memory tracking of xlsx cell edits that haven't been written to disk yet.
//  FileFillViewController-only (see the deferred-write redesign notes) --
//  ViewController.swift keeps writing every edit to disk immediately via
//  service.swift's testUpdateStringBox/testUpdateString, unchanged.
//

import Foundation

struct PendingXlsxEditKey: Hashable {
    let sheetIndex: Int
    let cellId: String   // A1-style, e.g. "O2" -- same format excelEntry already uses
}

struct PendingXlsxEdit {
    var content: String          // literal value or "=formula" (excelEntry's `element`)
    var calculatedValue: String  // resolved value if content is a formula, else "" (excelEntry's `calculated`)
}

// Deliberately narrow: just location (the dictionary key), content, and the
// already-resolved calculated value -- no style/border fields. Style is
// looked up fresh at flush time from appd.excelStyleLocationAlphabet/
// excelStyleIdx, exactly as testUpdateString already does internally, so
// there's nothing else this object needs to carry.
final class PendingXlsxChangeSet {
    private(set) var edits: [PendingXlsxEditKey: PendingXlsxEdit] = [:]

    var isDirty: Bool { !edits.isEmpty }

    func record(sheetIndex: Int, cellId: String, content: String, calculatedValue: String) {
        edits[PendingXlsxEditKey(sheetIndex: sheetIndex, cellId: cellId)] =
            PendingXlsxEdit(content: content, calculatedValue: calculatedValue)
    }

    func edits(forSheet sheetIndex: Int) -> [PendingXlsxEditKey: PendingXlsxEdit] {
        edits.filter { $0.key.sheetIndex == sheetIndex }
    }

    func clear() {
        edits.removeAll()
    }
}
