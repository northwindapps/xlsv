//
//  AISpreadsheetBridge.swift
//  XLSV
//
//  Shared glue so ViewController and FileFillViewController expose their
//  spreadsheet state to the LLM feature identically, instead of each growing
//  its own near-duplicate copy (the recurring drift this codebase keeps
//  fixing "in both controllers").
//
//  A controller conforms by declaring `: AISpreadsheetContextProviding` -- all
//  requirements are already stored properties on both -- and calls
//  `presentAIChat()` from a button action.
//

import UIKit

protocol AISpreadsheetContextProviding: UIViewController {
    var location: [String] { get }
    var content: [String] { get }
    var f_location: [String] { get }
    var f_calculated: [String] { get }
    var ROWSIZE: Int { get }
    var COLUMNSIZE: Int { get }
    var selectedSheet: Int { get }
    var tempRangeSelected: [IndexPath] { get }
    var currentindex: IndexPath! { get }
}

extension AISpreadsheetContextProviding {

    private var appd: AppDelegate { UIApplication.shared.delegate as! AppDelegate }

    var aiCurrentSheetName: String {
        let names = appd.sheetNames
        if selectedSheet >= 0 && selectedSheet < names.count { return names[selectedSheet] }
        return "Sheet"
    }

    /// Live in-memory snapshot of the sheet currently on screen.
    func aiCurrentSheetSnapshot() -> SheetSnapshot {
        SheetSnapshot(name: aiCurrentSheetName,
                      rowSize: ROWSIZE,
                      columnSize: COLUMNSIZE,
                      location: location,
                      content: content,
                      formulaLocation: f_location,
                      formulaResult: f_calculated)
    }

    /// Every sheet in the workbook. The active sheet comes from live memory
    /// (it may have unsaved edits); the others are read from their JSON
    /// sidecars on disk. CSV documents have only the one sheet.
    func aiBookSnapshots() -> [SheetSnapshot] {
        let names = appd.sheetNames
        let ids = appd.sheetNameIds
        guard names.count > 1, names.count == ids.count else {
            return [aiCurrentSheetSnapshot()]
        }

        var out: [SheetSnapshot] = []
        for i in 0..<names.count {
            if i == selectedSheet {
                out.append(aiCurrentSheetSnapshot())
                continue
            }
            let reader = ReadWriteJSON()
            guard reader.readJsonFile(title: "sheet\(ids[i])") else { continue }
            out.append(SheetSnapshot(name: names[i],
                                     rowSize: reader.rowsize,
                                     columnSize: reader.columnsize,
                                     location: reader.location,
                                     content: reader.content,
                                     formulaLocation: [],
                                     formulaResult: []))
        }
        return out.isEmpty ? [aiCurrentSheetSnapshot()] : out
    }

    /// The cells the "Selection" scope should send: the diamond-handle drag
    /// range if there is one, otherwise just the single cursor cell (so a plain
    /// tap is enough to ask about one cell).
    func aiSelectedCells() -> [IndexPath] {
        if !tempRangeSelected.isEmpty { return tempRangeSelected }
        if let c = currentindex { return [c] }
        return []
    }

    /// Builds and presents the chat panel.
    func presentAIChat() {
        let chat = AIChatViewController(
            currentSheet: { [weak self] in self?.aiCurrentSheetSnapshot() },
            book: { [weak self] in self?.aiBookSnapshots() ?? [] },
            selection: { [weak self] in self?.aiSelectedCells() ?? [] }
        )
        let nav = UINavigationController(rootViewController: chat)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
}

// Both controllers already carry every stored property the protocol needs;
// the LLM feature only ever touches them through this conformance.
extension ViewController: AISpreadsheetContextProviding {}
extension FileFillViewController: AISpreadsheetContextProviding {}
