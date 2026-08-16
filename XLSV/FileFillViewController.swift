//
//  ViewController.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/11/22.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit
import MessageUI
import QuartzCore
import CoreData
import Zip
import SSZipArchive
import CoreFoundation
import GoogleMobileAds

let reuseIdentifierF = "customCellF"
class FileFillViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate,UITextViewDelegate,MFMailComposeViewControllerDelegate,UICollectionViewDelegateFlowLayout,UIDocumentPickerDelegate,UIGestureRecognizerDelegate, BannerViewDelegate{

    // Temporary instrumentation for the window.rootViewController-swap leak
    // investigation (see [[project_rootviewcontroller_swap_leak]] memory note) --
    // confirms whether dismiss()-before-swap actually lets this instance deallocate.
    // Safe to remove once the fix is confirmed on-device.
    deinit {
        print("DEINIT FileFillViewController \(ObjectIdentifier(self))")
    }

    @IBOutlet weak var bannerview: BannerView!
    @IBOutlet weak var menuButton: UIButton!

    @IBOutlet weak var FileCollectionView: UICollectionView!
    @IBOutlet weak var cellSizeSlicer: UISlider!
    
    
    @IBOutlet weak var unsavedDataReiminderBUtton: UIButton!
    
    // saveAsLocalJson's actual disk write (JSONSerialization + file write) used to
    // run synchronously on the main thread on every single cell-edit commit --
    // for CSV mode specifically, this fires on every keystroke-commit (see
    // saveAsLocalJson's call sites), and for a 100k-row file that's a multi-MB
    // JSON rebuild+write blocking the UI thread on every edit. Serial (not
    // concurrent) so saves from rapid consecutive edits still land in the order
    // they were issued -- a concurrent queue could let an older edit's save finish
    // after a newer one and silently clobber it back to stale content.
    private let localJsonSaveQueue = DispatchQueue(label: "com.xlsv.filefill.localJsonSave")

    var KEYBOARDLOCATION:CGFloat = 0.0
    @objc var List: Array<AnyObject> = []
    
    var location = [String]()
    var locationInExcel = [String]() //reset before storeinput
    var content = [String]()
    var old_localFileNames = [String]()
    //
    var search_text = ""
    var replace_text = ""
    var csview = false
    
    @IBOutlet weak var hiddenTextField: UITextField!
    
    //mergedcells
    var nousecells = [[Int]]()
    var columnNames = [String]()
    var localFileNames = [String]()
    var sum_str = ""
    
    //Font location
//    var cursor = String()
    var changeaffected = [String]()
    
    var tcolor = [String]()
    var textsize = [String]()
    var bgcolor = [String]()

    // Raw per-cell style index from the original xlsx (Cell.styleIndex / the "s"
    // attribute), loaded straight from the saved sheet JSON. "" when a cell has no
    // explicit style.
    var cellStyleId = [String]()

    // Resolved from cellStyleId + appd's style tables (populated by
    // Service.testExtractStyle) once per sheet load -- see resolveCellStyles().
    // Kept for a later xlsx export to re-emit close to the original formatting, and
    // not currently rendered anywhere else.
    var cellBold = [String]()
    var cellItalic = [String]()
    var cellUnderline = [String]()
    var cellStrike = [String]()
    var cellBorderLeftStyle = [String]()
    var cellBorderLeftColor = [String]()
    var cellBorderRightStyle = [String]()
    var cellBorderRightColor = [String]()
    var cellBorderTopStyle = [String]()
    var cellBorderTopColor = [String]()
    var cellBorderBottomStyle = [String]()
    var cellBorderBottomColor = [String]()
    var cellHorizontalAlign = [String]()
    var cellVerticalAlign = [String]()
    var cellWrapText = [String]()


    var columninNumber = [String]()
    var rowinNumber = [String]()
    
    var COLUMNSIZE = 0
    var ROWSIZE = 0
    var FONTEDIT :String = ""
    var orientaion = ""
    var cell_scalevalue = 1.0
    var settingCellSelected = false
    
    var tag_int :Int!
    
    var current_range : NSRange!
    
    //
    var customview3 :Customview3!
    var rsview: RangeSelectionOpsView!
    
    var stringboxText = ""
    var pastemode : Bool = false
    var getvaluemode :Bool = false
    var getRefmode : Bool = false
    var clipboard = ""
    
    //http://stackoverflow.com/questions/28360919/my-table-view-reuse-the-selected-cells-when-scroll-in-swift
    
    //http://stackoverflow.com/questions/31706404/ios-8-and-swift-call-a-function-in-another-class-from-view-controller
    //var global = ns()
    var global2 = NilController()
    
    var boolean :Bool! //coulmnsize_check
    
    //var numberview = numberkey()
    
    var calcmemory = "0"
    
    var labelsizedouble = 0.0
    var labelsizedouble2 = 0.0
    
    
    var DATABASE_STR = ""
    
    var imageData: NSData? = nil
    
    var up_bool = false
    var down_bool = false
    var right_bool = false
    var left_bool = false

    // Post-edit refresh strategy for a single-cell commit. true: patch the
    // JSON sidecar cache from the in-memory state storeInput()/excelEntry()
    // already set, skipping the xlsx unzip/reparse in loadExcelSheet ->
    // readExcel2 (see patchJsonCacheAndRefresh). false: fall back to the
    // original full loadExcelSheet() reload. Kept as a switch rather than
    // replacing loadExcelSheet's call sites outright so the known-correct
    // path stays reachable; can be exposed in a settings view later.
    var useFastCellEditReload = true

    var selection_bool = false

    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    
    var customview2 :Customview2!
    var Fview :formatview!
    var datainputview :Datainputview!
    let speechInputHelper = SpeechInputHelper()
    var Hintview:Hint!

    // Row filter (see Datafilter.swift/.xib -- dialog opened by tapping a
    // column header). columnFilters is keyed by column index (indexPath.item);
    // a column's comparisons are ANDed together (e.g. ">=10,<=20" makes a
    // range), and columns are ANDed with each other. filteredOutRows is
    // computed once by applyRowFilters() -- "before rendering cells", per the
    // request -- rather than re-evaluated per cell during scroll.
    struct ColumnFilterCondition {
        enum Operator: String {
            case equal = "=="
            case greaterOrEqual = ">="
            case lessOrEqual = "<="
            case greater = ">"
            case less = "<"
        }
        struct Comparison {
            var op: Operator
            var operand: String
        }
        var comparisons: [Comparison]

        // Parses a comma-separated chain of comparisons (e.g. ">=10,<=20"
        // for a range, "==apple", or a bare "apple" as shorthand for
        // "==apple"). Longer operators (==, >=, <=) are checked before their
        // single-char prefixes (>, <) so ">=10" isn't misread as ">"+"=10".
        static func parse(_ input: String) -> ColumnFilterCondition? {
            let parts = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            guard !parts.isEmpty else { return nil }
            let comparisons: [Comparison] = parts.map { part in
                for op: Operator in [.equal, .greaterOrEqual, .lessOrEqual, .greater, .less] {
                    if part.hasPrefix(op.rawValue) {
                        let operand = String(part.dropFirst(op.rawValue.count)).trimmingCharacters(in: .whitespaces)
                        return Comparison(op: op, operand: operand)
                    }
                }
                return Comparison(op: .equal, operand: part)
            }
            return ColumnFilterCondition(comparisons: comparisons)
        }

        // Reconstructs the parseable text this condition came from, so
        // reopening the dialog on an already-filtered column shows what was
        // typed rather than starting blank.
        func displayString() -> String {
            comparisons.map { $0.op.rawValue + $0.operand }.joined(separator: ",")
        }

        func matches(_ rawValue: String) -> Bool {
            // Double.init(String) does not trim whitespace/newlines -- a cell
            // value like "50\n" or "50 " (trailing content stored alongside
            // the number, e.g. from a pasted/imported value) would otherwise
            // fail to parse and silently drop out of every numeric
            // comparison, even == against the exact same number.
            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            for c in comparisons {
                switch c.op {
                case .equal:
                    if let opNum = Double(c.operand), let valNum = Double(value) {
                        if valNum != opNum { return false }
                    } else if value != c.operand {
                        return false
                    }
                case .greaterOrEqual, .lessOrEqual, .greater, .less:
                    guard let opNum = Double(c.operand), let valNum = Double(value) else { return false }
                    switch c.op {
                    case .greaterOrEqual: if !(valNum >= opNum) { return false }
                    case .lessOrEqual: if !(valNum <= opNum) { return false }
                    case .greater: if !(valNum > opNum) { return false }
                    case .less: if !(valNum < opNum) { return false }
                    case .equal: break
                    }
                }
            }
            return true
        }
    }
    var datafilter: Datafilter!
    var columnFilters: [Int: ColumnFilterCondition] = [:]
    var filteredOutRows: Set<Int> = []
    private var currentFilterColumn: Int = -1
    
    //forexport
    var data: Data? = nil
    var byproduct: NSMutableString? = nil
    var currentindex : IndexPath!
    var cursor = ""//String! (1,1)
    var selectedSheet = 0 //initial
    
    //calculation
    var f_content = [String]()
    var f_calculated = [String]()
    var f_location_alphabet = [String]()
    var f_location = [String]()
    var input_order = [String]()
    
    //User feedback
    var selectingColor = "black"
    var selectingSize = 10
    var selectingBgColor = "white"
    
    //isExcelFile?
    var isExcel = false
    var isCSV = false
    var isMail = false
//    var sheetIdx = 0
    
    //RangeSelection reset at the start
    var tempRangeSelected = [IndexPath]()
    
    //
    var localFileName = [String]()
    var currentFileNameCollectionViewIdx = IndexPath(item: 0, section: 0)
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        myCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if collectionView === myCollectionView{
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            
            //#warning Incomplete method implementation -- Return the number of sections
            var rowsize = appd.DEFAULT_ROW_NUMBER//100

            if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
                let v = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
                if v > rowsize{
                    rowsize = v
                }
            }

            // NEWRsize in UserDefaults is stale/global, not this file's real
            // size (see isExcelSheetData's csvBranch comment) -- appd.numberofRow
            // may already hold the correct, larger value for the currently
            // loaded file, and this function must not stomp it back down to the
            // 1001 default just because myCollectionView (the header strip)
            // happened to reload.
            if appd.numberofRow > rowsize {
                rowsize = appd.numberofRow
            }

            if rowsize < 1{
                rowsize = 1
            }



            ROWSIZE = rowsize


            appd.numberofRow = rowsize

            // rowsize/ROWSIZE/appd.numberofRow above stay the *real* total
            // (row-insert/delete and other code depend on that) -- only the
            // section count actually handed to the collection view is
            // compacted, via appd.visibleRows built by applyRowFilters().
            if appd.rowFilterActive {
                return 1 + appd.visibleRows.count
            }
            return rowsize

        }else{
            return 1
        }

    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView === myCollectionView{
            //#warning Incomplete method implementation -- Return the number of items in the section
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            var columnsize = appd.DEFAULT_COLUMN_NUMBER //27
            if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
                let v = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
                if v > columnsize{
                    columnsize = v
                }
            }

            // See matching comment on numberOfSections's rowsize -- don't stomp
            // a correct, larger appd.numberofColumn back down to the default.
            if appd.numberofColumn > columnsize {
                columnsize = appd.numberofColumn
            }

            if columnsize < 1{
                columnsize = 1
            }

            COLUMNSIZE = columnsize// + 1

            appd.numberofColumn = columnsize

            return columnsize
            
        }else{
            
            return localFileNames.count
        }
    }
    
    //render part
    static let namedCellColors: [String: UIColor] = [
        "green": UIColor(red: 0/255, green: 102/255, blue: 0/255, alpha: 1),
        "water": UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1),
        "yellow": UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1),
        "orange": UIColor(red: 255/255, green: 102/255, blue: 0/255, alpha: 1),
        "lightGray": UIColor.lightGray,
        "magenta": UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1),
        "blue": UIColor(red: 51/255, green: 153/255, blue: 255/255, alpha: 1),
        "red": UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1),
        "brown": UIColor(red: 102/255, green: 61/255, blue: 0/255, alpha: 1),
        "purple": UIColor(red: 40/255, green: 0/255, blue: 100/255, alpha: 1),
        "gray": UIColor.gray,
        "white": UIColor.white
    ]

    func namedCellColor(_ name: String, default defaultColor: UIColor) -> UIColor {
        if name.hasPrefix("#"), let color = UIColor(hexString: name) {
            return color
        }
        return FileFillViewController.namedCellColors[name] ?? defaultColor
    }

    // Maps an xlsx <left/right/top/bottom style="..."> name to a screen border
    // width. Scaled down further from Excel's own relative weights (hair < thin
    // < medium < thick) since this app runs on phone/tablet screens, where
    // Excel-scale border weights read as disproportionately thick against a much
    // smaller, denser grid -- dash/dot patterns (dashed, dotted, dashDot, ...)
    // aren't rendered as dashes yet, just as a solid line at their base weight.
    func borderWidth(forStyle style: String) -> CGFloat {
        switch style {
        case "hair":
            return 0.3
        case "thin", "dashed", "dotted", "dashDot", "dashDotDot", "slantDashDot":
            return 0.75
        case "medium", "mediumDashed", "mediumDashDot", "mediumDashDotDot":
            return 1.5
        case "thick":
            return 2.0
        case "double":
            return 2.5
        default:
            return style.isEmpty ? 0 : 0.3
        }
    }

    // UIFont.systemFont(ofSize:).fontDescriptor.withSymbolicTraits(...) is unreliable
    // for the *dynamic* system font descriptor on iOS -- it can silently return nil
    // for bold/italic combinations, which made bold/italic quietly fall back to plain
    // regular. Apple's own boldSystemFont constructor doesn't have that problem, so
    // it's used directly for bold.
    //
    // Italic is handled separately via a synthetic shear on the font's own matrix,
    // not via the .traitItalic symbolic trait (what italicSystemFont/withSymbolicTraits
    // use under the hood). The trait only slants glyphs when the resolved font family
    // actually ships an italic face -- for non-Latin text (Japanese/Chinese/Korean),
    // iOS falls back to a CJK font (Hiragino Sans/PingFang) that has no italic design
    // at all, so the trait request silently renders upright. A shear matrix works at
    // the glyph-rendering level regardless of script or which font ends up handling
    // the actual glyphs, so it slants Latin and CJK text alike.
    private static let syntheticItalicMatrix = CGAffineTransform(a: 1, b: 0, c: CGFloat(tan(14.0 * Double.pi / 180)), d: 1, tx: 0, ty: 0)

    // UIFont.systemFont/boldSystemFont already ride UIKit's own font cache, but the
    // italic path below builds a custom font descriptor with a matrix transform and
    // constructs a UIFont from it directly -- that bypasses UIKit's cache entirely and
    // is a genuinely expensive CoreText operation, confirmed (via Instruments) to be a
    // meaningful chunk of cellForItemAt's cost when scrolling a large sheet, since every
    // formula cell is always italicized and cellForItemAt re-requests the same handful
    // of (size, bold, italic) combinations for every cell that scrolls into view.
    private static var fontCache: [FontCacheKey: UIFont] = [:]
    private struct FontCacheKey: Hashable { let size: CGFloat; let bold: Bool; let italic: Bool }

    func cellFont(size: CGFloat, bold: Bool, italic: Bool) -> UIFont {
        let key = FontCacheKey(size: size, bold: bold, italic: italic)
        if let cached = FileFillViewController.fontCache[key] { return cached }
        let font = FileFillViewController.makeCellFont(size: size, bold: bold, italic: italic)
        FileFillViewController.fontCache[key] = font
        return font
    }

    private static func makeCellFont(size: CGFloat, bold: Bool, italic: Bool) -> UIFont {
        let base = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        guard italic else { return base }
        let slantedDescriptor = base.fontDescriptor.withMatrix(FileFillViewController.syntheticItalicMatrix)
        return UIFont(descriptor: slantedDescriptor, size: size)
    }

    // Resolves cellStyleId (the raw per-cell style index saved at import time) into
    // actual font size/color, background color, and bold/italic/underline/strike,
    // using the style tables Service.testExtractStyle populates on appd. Must run
    // after both isExcelSheetData (location/cellStyleId) and testReadXMLSandBox
    // (appd's font/fill tables) -- see loadExcelSheet, where testReadXMLSandBox
    // already runs before isExcelSheetData, so the tables are ready in time.
    func resolveCellStyles() {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        print("DEBUG-RESOLVE table sizes: xfFontIds=\(appd.xfFontIds.count) xfFillIds=\(appd.xfFillIds.count)",
              "fontSizes=\(appd.fontSizes.count) fontColors=\(appd.fontColors.count) fillColors=\(appd.fillColors.count)")
        guard cellStyleId.count == location.count else {
            print("DEBUG-RESOLVE bailing: cellStyleId.count=\(cellStyleId.count) location.count=\(location.count)")
            return
        }

        cellBold = [String](repeating: "0", count: location.count)
        cellItalic = [String](repeating: "0", count: location.count)
        cellUnderline = [String](repeating: "0", count: location.count)
        cellStrike = [String](repeating: "0", count: location.count)
        cellBorderLeftStyle = [String](repeating: "", count: location.count)
        cellBorderLeftColor = [String](repeating: "", count: location.count)
        cellBorderRightStyle = [String](repeating: "", count: location.count)
        cellBorderRightColor = [String](repeating: "", count: location.count)
        cellBorderTopStyle = [String](repeating: "", count: location.count)
        cellBorderTopColor = [String](repeating: "", count: location.count)
        cellBorderBottomStyle = [String](repeating: "", count: location.count)
        cellBorderBottomColor = [String](repeating: "", count: location.count)
        cellHorizontalAlign = [String](repeating: "", count: location.count)
        cellVerticalAlign = [String](repeating: "", count: location.count)
        cellWrapText = [String](repeating: "0", count: location.count)

        var debugInBoundsHits = 0
        var debugNonDefaultColor = 0
        var debugWithBorder = 0
        var debugWithAlign = 0
        var debugWithBold = 0
        var debugWithItalic = 0
        for i in 0..<cellStyleId.count {
            guard let styleIdx = Int(cellStyleId[i]),
                  styleIdx >= 0,
                  styleIdx < appd.xfFontIds.count,
                  styleIdx < appd.xfFillIds.count else {
                continue
            }
            debugInBoundsHits += 1

            let fontId = appd.xfFontIds[styleIdx]
            if fontId >= 0 && fontId < appd.fontSizes.count {
                if !appd.fontSizes[fontId].isEmpty {
                    textsize[i] = appd.fontSizes[fontId]
                }
                if !appd.fontColors[fontId].isEmpty {
                    tcolor[i] = appd.fontColors[fontId]
                }
                cellBold[i] = appd.fontBolds[fontId] ? "1" : "0"
                cellItalic[i] = appd.fontItalics[fontId] ? "1" : "0"
                cellUnderline[i] = appd.fontUnderlines[fontId] ? "1" : "0"
                cellStrike[i] = appd.fontStrikes[fontId] ? "1" : "0"
                if cellBold[i] == "1" { debugWithBold += 1 }
                if cellItalic[i] == "1" { debugWithItalic += 1 }
            }

            let fillId = appd.xfFillIds[styleIdx]
            if fillId >= 0 && fillId < appd.fillColors.count && !appd.fillColors[fillId].isEmpty {
                bgcolor[i] = appd.fillColors[fillId]
            }

            // appd.cellXfs[styleIdx] holds the borderId for this style (the position
            // into <borders>) -- same lookup cellForItemAt's older excelStyleLocation
            // path already uses for border-presence detection.
            if styleIdx < appd.cellXfs.count {
                let borderId = appd.cellXfs[styleIdx]
                if borderId >= 0 && borderId < appd.borderLeftStyles.count {
                    cellBorderLeftStyle[i] = appd.borderLeftStyles[borderId]
                    cellBorderLeftColor[i] = appd.borderLeftColors[borderId]
                    cellBorderRightStyle[i] = appd.borderRightStyles[borderId]
                    cellBorderRightColor[i] = appd.borderRightColors[borderId]
                    cellBorderTopStyle[i] = appd.borderTopStyles[borderId]
                    cellBorderTopColor[i] = appd.borderTopColors[borderId]
                    cellBorderBottomStyle[i] = appd.borderBottomStyles[borderId]
                    cellBorderBottomColor[i] = appd.borderBottomColors[borderId]
                    if !cellBorderLeftStyle[i].isEmpty || !cellBorderRightStyle[i].isEmpty ||
                        !cellBorderTopStyle[i].isEmpty || !cellBorderBottomStyle[i].isEmpty {
                        debugWithBorder += 1
                        if debugWithBorder <= 10 {
                            print("DEBUG-BORDERFINAL i=\(i) borderId=\(borderId)",
                                  "left=(\(cellBorderLeftStyle[i]),\(cellBorderLeftColor[i]))",
                                  "right=(\(cellBorderRightStyle[i]),\(cellBorderRightColor[i]))",
                                  "top=(\(cellBorderTopStyle[i]),\(cellBorderTopColor[i]))",
                                  "bottom=(\(cellBorderBottomStyle[i]),\(cellBorderBottomColor[i]))")
                        }
                    }
                }
            }

            // Alignment is inline on the <xf> itself, so it's indexed directly by
            // styleIdx -- no separate id table to look up like font/fill/border.
            if styleIdx < appd.xfHorizontalAligns.count {
                cellHorizontalAlign[i] = appd.xfHorizontalAligns[styleIdx]
                cellVerticalAlign[i] = appd.xfVerticalAligns[styleIdx]
                cellWrapText[i] = appd.xfWrapTexts[styleIdx] ? "1" : "0"
                if !cellHorizontalAlign[i].isEmpty || !cellVerticalAlign[i].isEmpty { debugWithAlign += 1 }
            }

            if tcolor[i] != "black" || bgcolor[i] != "white" { debugNonDefaultColor += 1 }
        }
        print("DEBUG-RESOLVE cells=\(cellStyleId.count) inBoundsStyleIndex=\(debugInBoundsHits) withNonDefaultColor=\(debugNonDefaultColor) withBorder=\(debugWithBorder) withAlign=\(debugWithAlign) withBold=\(debugWithBold) withItalic=\(debugWithItalic)")
    }

    // location/f_location/excelStyleLocation are scanned per-cell during rendering (up to
    // hundreds of visible cells per reload). Linear .contains/.index(of:) scans over these
    // arrays made rendering O(visibleCells * n). These caches make repeat lookups O(1);
    // call invalidateLocationIndexCache()/invalidateFLocationIndexCache() after any in-place
    // write to location[i]/f_location[i] (appends/removeAll are already detected via count).
    private var locationIndexCache: [String: Int] = [:]
    private var locationIndexCacheCount = -1
    private var fLocationIndexCache: [String: Int] = [:]
    private var fLocationIndexCacheCount = -1
    private var excelStyleLocationIndexCache: [String: Int] = [:]
    private var excelStyleLocationIndexCacheCount = -1
    // Reverse of locationIndexCache -- keys on locationInExcel's A1-style labels
    // ("O2") instead of location's "col,row" strings, so a formula's cell
    // references can be resolved to a content/location index in O(1) instead of
    // locationInExcel.firstIndex(of:)'s O(n) scan. Used by
    // recalculateSingleCell's incremental formula path.
    private var excelLocationIndexCache: [String: Int] = [:]
    private var excelLocationIndexCacheCount = -1

    // Deferred-write tracking (see PendingXlsxChangeSet.swift) -- excelEntry/
    // excelEntryBulk record edits here instead of writing to the real .xlsx on
    // every keystroke; the real write only happens on Export/Save (see
    // flushPendingXlsxChangesIfNeeded). A fresh instance per Form Fill session
    // (HomeController always instantiates a new FileFillViewController) means
    // this starts empty automatically -- no explicit "new file" reset needed,
    // it's only cleared in resetAllContent()'s full-wipe flow and after a
    // successful flush.
    let pendingXlsxChanges = PendingXlsxChangeSet()

    private func invalidateLocationIndexCache() {
        locationIndexCacheCount = -1
    }

    private func invalidateFLocationIndexCache() {
        fLocationIndexCacheCount = -1
    }

    // location/f_location/excelStyleLocation get fully reassigned (not appended to)
    // whenever a different sheet's data loads (see isExcelSheetData). The count-based
    // checks above can't detect that -- a same-size sheet swap leaves the old sheet's
    // key->index mappings in place -- so any full reassignment must invalidate all four.
    private func invalidateAllRenderIndexCaches() {
        locationIndexCacheCount = -1
        fLocationIndexCacheCount = -1
        excelStyleLocationIndexCacheCount = -1
        excelLocationIndexCacheCount = -1
    }

    private func locationIndex(for key: String) -> Int? {
        if locationIndexCacheCount != location.count {
            locationIndexCache.removeAll(keepingCapacity: true)
            locationIndexCache.reserveCapacity(location.count)
            for (idx, loc) in location.enumerated() where locationIndexCache[loc] == nil {
                locationIndexCache[loc] = idx
            }
            locationIndexCacheCount = location.count
        }
        return locationIndexCache[key]
    }

    private func fLocationIndex(for key: String) -> Int? {
        if fLocationIndexCacheCount != f_location.count {
            fLocationIndexCache.removeAll(keepingCapacity: true)
            fLocationIndexCache.reserveCapacity(f_location.count)
            for (idx, loc) in f_location.enumerated() where fLocationIndexCache[loc] == nil {
                fLocationIndexCache[loc] = idx
            }
            fLocationIndexCacheCount = f_location.count
        }
        return fLocationIndexCache[key]
    }

    private func excelLocationIndex(for key: String) -> Int? {
        if excelLocationIndexCacheCount != locationInExcel.count {
            excelLocationIndexCache.removeAll(keepingCapacity: true)
            excelLocationIndexCache.reserveCapacity(locationInExcel.count)
            for (idx, loc) in locationInExcel.enumerated() where excelLocationIndexCache[loc] == nil {
                excelLocationIndexCache[loc] = idx
            }
            excelLocationIndexCacheCount = locationInExcel.count
        }
        return excelLocationIndexCache[key]
    }

    private func excelStyleLocationIndex(_ locations: [String], key: String) -> Int? {
        if excelStyleLocationIndexCacheCount != locations.count {
            excelStyleLocationIndexCache.removeAll(keepingCapacity: true)
            excelStyleLocationIndexCache.reserveCapacity(locations.count)
            for (idx, loc) in locations.enumerated() where excelStyleLocationIndexCache[loc] == nil {
                excelStyleLocationIndexCache[loc] = idx
            }
            excelStyleLocationIndexCacheCount = locations.count
        }
        return excelStyleLocationIndexCache[key]
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //something went wrong maybe fix it in future..maybe
        if location.count != textsize.count{
            textsize.removeAll()
            bgcolor.removeAll()
            tcolor.removeAll()
            for _ in 0..<location.count{
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
            }
        }
        
        //Render
        if collectionView === myCollectionView{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierF, for: indexPath) as! CustomCollectionViewCell
            
            
            cell.label2?.lineBreakMode = .byWordWrapping // or NSLineBreakMode.ByWordWrapping
            cell.label2?.numberOfLines = 0
            // Apply to every cell, not just row/column headers -- UILabel only
            // honors adjustsFontSizeToFitWidth when numberOfLines == 1, so this
            // is a no-op on multi-line wrapped content cells (numberOfLines stays
            // 0 above) and only actually shrinks single-line cell content that
            // would otherwise clip/overflow its column width.
            cell.label2?.adjustsFontSizeToFitWidth = true
            cell.label2?.minimumScaleFactor = 0.4

            removePanGestureRecognizerFromCell(cell)
            cell.setFilterBadge(visible: false)

            // realRow translates the (possibly filter-compacted) display
            // section back to the real, absolute row that content/location
            // are actually keyed by -- see realRow(forDisplaySection:).
            let key = String(indexPath.item)+","+String(realRow(forDisplaySection: indexPath.section))

            //content
            if let i = locationIndex(for: key) {

                let notFunc = content[i]
                let isBold = i < cellBold.count && cellBold[i] == "1"
                let isItalic = i < cellItalic.count && cellItalic[i] == "1"
                if let idx = fLocationIndex(for: key) {
                    if f_calculated.count-1 < idx{
                        cell.label2?.text = "error"
                    }else{
                        cell.label2?.text = f_calculated[idx]
                    }
                    let fl: CGFloat = CGFloat((textsize[i] as NSString).doubleValue)
                    // Formula cells are always italicized regardless of xlsx style,
                    // to visually flag them as computed -- xlsx bold still applies.
                    cell.label2?.font = cellFont(size: fl, bold: isBold, italic: true)
                    cell.label2?.textAlignment = .right

                }else if Double(notFunc) != nil {
                    cell.label2?.text = notFunc
                    let fl: CGFloat = CGFloat((textsize[i] as NSString).doubleValue)
                    cell.label2?.font = cellFont(size: fl, bold: isBold, italic: isItalic)
                    cell.label2?.textAlignment = .right
                }else{
                    cell.label2?.text = notFunc
                    let fl: CGFloat = CGFloat((textsize[i] as NSString).doubleValue)
                    cell.label2?.font = cellFont(size: fl, bold: isBold, italic: isItalic)
                    cell.label2?.textAlignment = .left
                }

                if (isBold || isItalic) && i < 30 {
                    print("DEBUG-FONT key=\(key) i=\(i) isBold=\(isBold) isItalic=\(isItalic)",
                          "resultFont=\(cell.label2?.font.fontName ?? "nil")",
                          "traits=\(cell.label2?.font.fontDescriptor.symbolicTraits.rawValue ?? 0)")
                }
            }else{
                //empty
                let fl: CGFloat = CGFloat(("11" as NSString).doubleValue)
                cell.label2?.font = UIFont.systemFont(ofSize: fl)
                cell.label2?.text = ""
                cell.label2?.textAlignment = .center
            }

            // Cells with real embedded newlines still need to wrap across those
            // lines -- but single-line text that's simply too wide for the column
            // (e.g. "how are you?" in a narrow column) should shrink to fit
            // instead of wrapping, since wrapping there just grows the row
            // unpredictably. adjustsFontSizeToFitWidth (set at the top of this
            // function) only takes effect when numberOfLines == 1.
            if let text = cell.label2?.text, !text.contains("\n") {
                cell.label2?.numberOfLines = 1
            }

            //xlsx alignment, resolved onto cellHorizontalAlign/cellVerticalAlign/
            // cellWrapText by resolveCellStyles(). Only overrides the content-type
            // default (numbers right, text left) when the xlsx explicitly sets a
            // horizontal alignment other than "general" -- matching how Excel itself
            // treats "General" as "use the type-based default", not an explicit value.
            if let i = locationIndex(for: key) {
                if i < cellHorizontalAlign.count {
                    switch cellHorizontalAlign[i] {
                    case "left", "fill":
                        cell.label2?.textAlignment = .left
                    case "center", "centerContinuous", "distributed":
                        cell.label2?.textAlignment = .center
                    case "right":
                        cell.label2?.textAlignment = .right
                    case "justify":
                        cell.label2?.textAlignment = .justified
                    default:
                        break // "general" or unset -- keep the type-based default above
                    }
                }

                if i < cellVerticalAlign.count {
                    switch cellVerticalAlign[i] {
                    case "top":
                        cell.label2?.verticalAlignment = .top
                    case "center", "distributed":
                        cell.label2?.verticalAlignment = .center
                    default:
                        cell.label2?.verticalAlignment = .bottom // xlsx's own default
                    }
                }

                // Always wrap (numberOfLines/lineBreakMode set at the top of this
                // function already do this) rather than switching to single-line
                // clipping when wrapText isn't explicitly "1" -- most real sheets
                // don't set wrapText on every cell, so a strict xlsx-faithful
                // single-line default made previously-readable wrapped cells clip.
            } else {
                cell.label2?.verticalAlignment = .bottom
            }

            #if !targetEnvironment(macCatalyst)
            if selection_bool {
                //number or fx only
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
                cell.addGestureRecognizer(panGesture)
            }
            #else
             let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
             cell.addGestureRecognizer(panGesture)
            #endif
     
                
           
            
            
            
            
           //Border
           cell.clearAllEdgeBorders()
           cell.label2?.layer.borderWidth = 0.0
           cell.label2?.layer.borderColor = nil
         
            
            if cursor == key {
                cell.label2?.layer.borderColor = UIColor(red: 255/255, green: 0/255, blue: 51/255, alpha: 1).cgColor
                cell.label2?.layer.borderWidth = 2.0
            }else if(changeaffected.contains(key)){

                cell.label2?.layer.borderColor = UIColor(red: 255/255, green: 0/255, blue: 51/255, alpha: 1).cgColor
                cell.label2?.layer.borderWidth = 2.0
            }


            //BG
            if let i = locationIndex(for: key) {

                // Reused cells keep whatever backgroundColor/textColor a previous
                // index path last set (UICollectionViewCell pooling) -- cells with
                // no explicit xlsx fill/font color must still be reset to the plain
                // defaults here, not just left alone, or fast scrolling flickers
                // between stale colors from a handful of recycled cell instances.
                cell.label2?.backgroundColor = bgcolor[i].count > 0
                    ? namedCellColor(bgcolor[i], default: UIColor.white)
                    : UIColor.white
                cell.label2?.textColor = tcolor[i].count > 0
                    ? namedCellColor(tcolor[i], default: UIColor.black)
                    : UIColor.black

            }else{
                cell.label2?.backgroundColor = UIColor.white
                cell.label2?.textColor = UIColor.black

                if indexPath.item == 0{

                    if indexPath.section > 0{
                        // Show the real row number (may have gaps once a
                        // filter is active), not the compacted display
                        // position -- see realRow(forDisplaySection:).
                        let realSectionRow = realRow(forDisplaySection: indexPath.section)
                        cell.label2?.text = String(realSectionRow)
                        rowinNumber.append("r" + String(realSectionRow))
                    }

                    cell.label2?.backgroundColor = UIColor.lightGray//UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1.0)
                    cell.label2?.layer.borderColor = UIColor.white.cgColor
                    cell.label2?.layer.borderWidth = 0.7
                    //cell.setBorder(width: 0.8, color: UIColor.lightGray, sides: .bottom)
                    cell.label2?.layer.borderWidth = 0.7
                    cell.label2?.textColor = UIColor.black
                    cell.label2?.textAlignment = .center
                    // The row-number/column-letter columns share INDEX_WIDTH/
                    // INDEX_HEIGHT (see cellSizeSlicer), which can shrink well
                    // below what a fixed font size needs for 2-3 digit row
                    // numbers -- shrink the text to fit instead of clipping it.
                    cell.label2?.adjustsFontSizeToFitWidth = true
                    cell.label2?.minimumScaleFactor = 0.4
                    cell.label2?.numberOfLines = 1
                }else if indexPath.section == 0{



                    if indexPath.item > 0{//0,0 == greyzone
                        cell.label2?.text = getExcelColumnName(columnNumber: indexPath.item)//ABCDE...
                        columninNumber.append(getExcelColumnName(columnNumber: indexPath.item))
                        // Small dot marking a column with an active Datafilter condition.
                        cell.setFilterBadge(visible: columnFilters[indexPath.item] != nil)
                    }

                    cell.label2?.layer.borderColor = UIColor.white.cgColor
                    cell.label2?.layer.borderWidth = 0.7
                    cell.label2?.backgroundColor = UIColor.lightGray//UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1.0)
                    cell.label2?.textColor = UIColor.black
                    cell.label2?.textAlignment = .center
                    cell.label2?.adjustsFontSizeToFitWidth = true
                    cell.label2?.minimumScaleFactor = 0.4
                    cell.label2?.numberOfLines = 1
                }else {
                    //normal cells
                    cell.label2?.backgroundColor = UIColor.white
                    cell.label2?.textColor = UIColor.black
                }
            }

            // UILabel has no bool for underline/strikethrough -- unlike bold/italic
            // those aren't font traits, they're paragraph-level text attributes, so
            // they need an NSAttributedString built from the label's already-final
            // text/font/color. When neither applies, leave plain .text alone: UILabel
            // resets its attributed storage whenever .text is set (already done above
            // for every cell), so a reused cell won't carry over a previous cell's
            // underline/strike.
            if let i = locationIndex(for: key),
               i < cellUnderline.count, i < cellStrike.count,
               (cellUnderline[i] == "1" || cellStrike[i] == "1"),
               let text = cell.label2?.text, let font = cell.label2?.font,
               let color = cell.label2?.textColor {
                var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                // Raw value 1 == NSUnderlineStyle.single (a single line) -- written as
                // a literal instead of referencing the enum case by name because this
                // project's toolchain is flagging that name as needing a rename in both
                // directions depending on the day; the raw Int is unambiguous either way.
                if cellUnderline[i] == "1" { attrs[.underlineStyle] = 1 }
                if cellStrike[i] == "1" { attrs[.strikethroughStyle] = 1 }
                cell.label2?.attributedText = NSAttributedString(string: text, attributes: attrs)
            }

//            //xlsx per-side borders, resolved onto cellBorder*Style/Color by
//            // resolveCellStyles(). Must reset every side on every cell (dequeued
//            // cells keep whatever a previous index path last set).
            if let i = locationIndex(for: key) {
                func edgeSpec(style: [String], color: [String]) -> (width: CGFloat, color: UIColor)? {
                    guard i < style.count, !style[i].isEmpty else { return nil }
                    let width = borderWidth(forStyle: style[i])
                    guard width > 0 else { return nil }
                    // xlsx's own default for a border with no explicit color is
                    // <color auto="1"/> ("automatic"), which Excel itself renders as
                    // black -- but a flat black line reads as heavier/harsher than
                    // this app wants on a phone/tablet screen, so unspecified-color
                    // borders render as a soft gray instead of true black.
                    let edgeColor = (i < color.count && !color[i].isEmpty)
                        ? namedCellColor(color[i], default: UIColor(white: 0.55, alpha: 1.0))
                        : UIColor(white: 0.55, alpha: 1.0)
                    return (width, edgeColor)
                }
                cell.setEdgeBorders(
                    left: edgeSpec(style: cellBorderLeftStyle, color: cellBorderLeftColor),
                    right: edgeSpec(style: cellBorderRightStyle, color: cellBorderRightColor),
                    top: edgeSpec(style: cellBorderTopStyle, color: cellBorderTopColor),
                    bottom: edgeSpec(style: cellBorderBottomStyle, color: cellBorderBottomColor)
                )
            } else {
                cell.setEdgeBorders(left: nil, right: nil, top: nil, bottom: nil)
            }

            //http://stackoverflow.com/questions/29381994/swift-check-string-for-nil-empty
            //http://qiita.com/satomyumi/items/b0d071cc906574086ac4
            
            //print("width size",cell.frame.width)
            let predifinedIds = [31]
            let ipstr = String(realRow(forDisplaySection: indexPath.section)) + "," + String(indexPath.row)
            let styleId = excelStyleLocationIndex(appd.excelStyleLocation, key: ipstr)
            if (styleId != nil && (appd.excelStyleIdx[styleId!] != -1) && appd.cellXfs.count != 0 && appd.numFmtIds.count != 0 && appd.numFmts.count != 0 && appd.excelStyleIdx.count != 0){
                var c = 0
                if appd.cellXfs.count <= appd.excelStyleIdx[styleId!] || appd.numFmtIds.count <= appd.excelStyleIdx[styleId!] {
                    return cell
                }
                let borderId = appd.cellXfs[appd.excelStyleIdx[styleId!]]
                let numId = appd.numFmtIds[appd.excelStyleIdx[styleId!]]
                var idx = appd.numFmts.firstIndex(of: String(numId))
                if idx == nil{
                    idx = appd.numFmtIds.firstIndex(of: numId)
                }
                //https://c-rex.net/samples/ooxml/e1/Part4/OOXML_P4_DOCX_numFmt_topic_ID0EHDH6.html
                if idx == nil && predifinedIds.contains(numId){
                    idx = 0
                }
                
                if (idx != nil) {
                    var a = false
                    
                    //id first
                    if numId == 14 {
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                             
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MM/dd/yyyy"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                    
                    if numId == 31 && !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                             
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy/MM/dd"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                    
                    if numId == 20 || (appd.formatCodes.count > idx! &&  appd.formatCodes[idx!] == "[h]:mm") || (appd.formatCodes.count > idx! && appd.formatCodes[idx!] == "hh:mm"){
                        if let labelText = cell.label2.text, let inputValue = Decimal(string:labelText) {
                            let totalHours = inputValue * Decimal(24)
                            let input24 = inputValue * Decimal(24)
                            let strHours = String(floor(input24.doubleValue))
                            let fractionHours = totalHours - Decimal(floor(input24.doubleValue))
                            let decimalMinutes = fractionHours * Decimal(60)
                           
                           
                            let roundingBehavior = NSDecimalNumberHandler(roundingMode: .plain, scale: 4, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
                            let resultAsNSDecimalNumber = NSDecimalNumber(decimal: decimalMinutes)
                            let roundedResult = resultAsNSDecimalNumber.rounding(accordingToBehavior: roundingBehavior)

                            var strMinutes = String(roundedResult.description)
                            if fractionHours * 60 < 10.0{
                                strMinutes = "0" + strMinutes
                            }
                            cell.label2.text = strHours.components(separatedBy: ".").first! + ":" + strMinutes.components(separatedBy: ".").first!
                            a = true
                        }
                    }
                    
                    //numId> 49 not predefined number by xlsx?
                    if numId > 49 && (appd.formatCodes.count > idx! && appd.formatCodes[idx!].contains("yyyy") && appd.formatCodes[idx!].contains("mm") && appd.formatCodes[idx!].contains("dd")) && !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                             
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy/MM/dd"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                    
                    if numId > 49 && ((appd.formatCodes.count > idx! && appd.formatCodes[idx!].contains("yyyy") && appd.formatCodes[idx!].contains("mm") ) || (appd.formatCodes.count > idx! && appd.formatCodes[idx!].contains("yyyy") && appd.formatCodes[idx!].contains("m"))) &&  !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400) // Your timestamp
                            
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy/MM"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                    
                if  numId > 49 && (appd.formatCodes.count > idx! && appd.formatCodes[idx!].contains("mm") && appd.formatCodes[idx!].contains("dd")) && !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                            
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MM/dd"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                            a = true
                        }
                    }
                
                    
                    if numId > 49 && (appd.formatCodes.count > idx! && appd.formatCodes[idx!] == "d") && !a{
                        if let labelText = cell.label2.text, let inputValue = Float(labelText) {
                            let timestamp = TimeInterval((inputValue - 25569) * 86400)  // Your timestamp
                            
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: timestamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "d"
                            
                            // Convert Date to String
                            let dateString = dateFormatter.string(from: date)
                            cell.label2.text = dateString
                        }
                    }
                    
                }
                // This block used to call cell.setBorder(...), which sets the
                // whole-cell layer.borderWidth/borderColor directly -- a second,
                // cruder border system running after setEdgeBorders(...) above
                // already drew the accurate per-edge xlsx borders via sublayers.
                // Since setEdgeBorders leaves layer.borderWidth at 0 (via
                // hasExcelBorder/defaultGridBorderWidth), this always painted an
                // extra 0.5-0.8pt lightGray border on every cell on top of/around
                // the real accent borders -- blending into the "gold/brown"
                // border color that was chased earlier in this file. Removed;
                // border rendering is now solely setEdgeBorders' responsibility.
                _ = borderId
            }
            
            return cell

                } else {
            // sheet cell tab menu
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellTabF", for: indexPath) as! FileCollectionViewCell
            let title = localFileNames[indexPath.item]
            cell.FileLabel.text = title
            
           
            let isSelected: Bool
            if isExcel {
                isSelected = (currentFileNameCollectionViewIdx != IndexPath() && indexPath.item == currentFileNameCollectionViewIdx.item)
            } else {
                isSelected = (indexPath.item == selectedSheet)
            }
            
            if isSelected {
                // 選択されているタブのスタイル
                cell.FileLabel.backgroundColor = UIColor.lightGray
                cell.FileLabel.textColor = UIColor.white
            } else {
                // 選択されていないタブのスタイル（ここで確実に白背景にリセット！）
                cell.FileLabel.backgroundColor = UIColor.white 
                cell.FileLabel.textColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
            }
            
            return cell
        }

    }
    
    // Method to remove the pan gesture recognizer from a cell
    func removePanGestureRecognizerFromCell(_ cell: UICollectionViewCell) {
        if let gestureRecognizers = cell.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer is UIPanGestureRecognizer {
                    cell.removeGestureRecognizer(recognizer)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
    
    func datainputFromOtherComtroller(sourceText:String,isBarcode:Bool=false){
        changeaffected.removeAll()
        
        //data input
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.collectionViewCellSizeChanged = 0
        let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
        appd.wsSheetIndex = sheetIdx!
        print("wsSheetIndex",appd.wsSheetIndex)
        
        //let pasteboard = UIPasteboard.general
        //pasteboard.string = ""

        // fontcolorClass.storeValues() aliases appd.RC/RL to this same
        // content/location buffer as part of a 9-deep undo ring buffer
        // (colorclass.outValues(), consumed only by restore() -- which has no
        // call site anywhere in the app, not in code, not in any storyboard, so
        // this whole mechanism is dead). Swift arrays are copy-on-write, so
        // that alias is cheap by itself, but it means the very next mutation of
        // content/location (storeInput, moments later) is no longer touching a
        // uniquely-referenced buffer, forcing a silent full-array deep copy --
        // a real, severe cost at 1.4M cells. Skipped for CSV; xlsx mode's
        // behavior is unchanged.
        if !isCSV {
            fontcolorClass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        }

        var element: String = sourceText

        if element.hasPrefix("=") {
            let targets = ["sum", "average", "min", "max"]
            for target in targets {
                // （options: .caseInsensitive）
                element = element.replacingOccurrences(
                    of: target,
                    with: target.uppercased(),
                    options: .caseInsensitive
                )
            }
        }
        
        //add more complicated functionality
        if autoComplete(src: element).count > 1 {
            element = autoComplete(src: element)
        }
        
        
        let IP :String = cursor   //String(currentindex!.item) + String(currentindex!.section)
        let t_item = IP.components(separatedBy: ",")[0]
        let t_section = IP.components(separatedBy: ",")[1]
        
        let IP_i = Int(t_item)!
        let IP_s = Int(t_section)!
        
        if isBarcode{
            let padAry = element.components(separatedBy: ";")
            for idx in 0..<padAry.count{
                let IPl = String(IP_i+idx) + "," + String(IP_s)
                if IP_i+idx <= 0 {
                    //it's
                }else{
                    var each = padAry[idx]
                    if each == "-"{
                        if location.contains(IPl){
                            let i = location.index(of: IPl)
                            each = content[i!]
                        }
                    }
                    storeInput(IPd: IPl, elementd: each)
                    let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                    excelEntry(srcString: each, cellId: alphabet + String(IP_s))
                }
            }
        }else{
            storeInput(IPd: IP, elementd: element)
            let alphabet = getExcelColumnName(columnNumber: IP_i)
            excelEntry(srcString: element, cellId: alphabet + String(IP_s))
        }
        XLSV.pasteboard.string = clipboard
        //It makes better UX by shiftting the selected cell
        changeaffected.removeAll()
        
        //update cursor
        if isBarcode{
            currentindex = IndexPath(item:currentindex.item, section: currentindex.section+1)
        }else{
            if right_bool{
                currentindex = IndexPath(item:currentindex.item+1, section: currentindex.section)
            }
            
            if down_bool{
                currentindex = IndexPath(item:currentindex.item, section: currentindex.section+1)
            }
        }
        cursor = String(currentindex.item) + "," + String(realRow(forDisplaySection: currentindex.section))
            
        saveuserF()
        saveuserD()
        
        if !isExcel{
            print("saved")
            saveAsLocalJson(filename: "csv_sheet1")
        }
   
        DispatchQueue.main.async {
            let appd = UIApplication.shared.delegate as! AppDelegate

            self.applyCellEditAndRefresh(idx: appd.wsSheetIndex) {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if self.myCollectionView.collectionViewLayout is CustomCollectionViewLayout {
                        self.myCollectionView.collectionViewLayout.invalidateLayout()
                        self.myCollectionView.reloadData()
                    }
                }
            }
        }
    }

    //Hiding Keyboard
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            let __shouldChangeTextInStart = CFAbsoluteTimeGetCurrent()
            changeaffected.removeAll()

            //data input
            input()

            saveuserF()
            saveuserD()

//            if selectedSheet >= 0{
            //if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex{
            if !isExcel{
                print("saved")
                saveAsLocalJson(filename: "csv_sheet1")
            }
            //}


            let locationIdx = locationIndex(for: cursor)
            if locationIdx != nil && content[locationIdx!] != ""{
                datainputview.stringbox.text = content[locationIdx!]
            }

            perfLog(String(format: "PERF shouldChangeTextIn.syncPortion: %.3fs isCSV=%@ content=%d", CFAbsoluteTimeGetCurrent() - __shouldChangeTextInStart, isCSV ? "true" : "false", content.count))

            DispatchQueue.main.async {
                let appd = UIApplication.shared.delegate as! AppDelegate

                self.applyCellEditAndRefresh(idx: appd.wsSheetIndex) {

                    perfLog(String(format: "PERF shouldChangeTextIn.total (through applyCellEditAndRefresh): %.3fs", CFAbsoluteTimeGetCurrent() - __shouldChangeTextInStart))

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if self.myCollectionView.collectionViewLayout is CustomCollectionViewLayout {
                            // reloadData/invalidateLayout already happened inside
                            // applyCellEditAndRefresh -> patchJsonCacheAndRefresh; doing it
                            // again here was pure duplicate work. animated:false avoids
                            // driving prepare() on every frame of the re-center scroll,
                            // which dominates edit latency on large (lazyInteriorCells) grids.
                            self.myCollectionView.selectItem(at: self.currentindex,
                                                             animated: false,
                                                             scrollPosition: [.centeredVertically, .centeredHorizontally])
                            self.collectionView(self.myCollectionView, didSelectItemAt: self.currentindex)

                        }
                    }
                }
            }





            return false
        }
        return true
    }
    
    
    //touch cell touch
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Close all subviews
        if Hintview != nil{
            Hintview.removeFromSuperview()
        }
        if customview2 != nil{
            customview2.removeFromSuperview()
        }
        if collectionView === myCollectionView{
            //reset change history
            currentindex = indexPath
            // cursor is compared against cellForItemAt's key, which is keyed
            // by real row -- translate the (possibly display-compacted)
            // currentindex.section accordingly.
            cursor = String(currentindex!.item)+","+String(realRow(forDisplaySection: currentindex!.section))


            getIndexlabel()
            
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appd.collectionViewCellSizeChanged = 0
                
                changeaffected.removeAll()
                //sizing column width and height
                if indexPath.item == 0{
                    //do nothing
                    //settingCellSelected = true
                    //numberviewopen()
                    
                    
                }else if indexPath.section == 0{
                    openDatafilter(forColumn: indexPath.item)
                }else{
                    //version 1.3.6 csv mode only not in excel file viewer mode
                    //if !isExcel && !settingCellSelected{
                    if !settingCellSelected{
                        if datainputview == nil{
                            //if there's not
                            opendatainputview()
                        
                        }
                        let locationIdx = locationIndex(for: cursor)
                        if (locationIdx != nil) && datainputview != nil {
                            datainputview.stringbox.text = content[locationIdx!]
                        }
                        if (locationIdx == nil && datainputview != nil){
                            datainputview.stringbox.text = ""
                        }
                        
                        self.myCollectionView.reloadData()
                    }
                }
            
        }else{
            //FileNameCollectionview Change Page
            //sheet cell get touched
            let locationstr = NSLocale.preferredLanguages.first ?? "en"
            var msgChoose = "Choose an action"
            var msgAdd = "Add Sheet"
            var msgDup = "Duplicate"
            var msgDel = "Delete Sheet"
            var msgRen = "Rename Sheet"
            var msgCancel = "Cancel"
            
            if locationstr.hasPrefix("ja") {
                msgChoose = "操作を選択してください"
                msgAdd = "シートを追加"
                msgDup = "複製"
                msgDel = "シートを削除"
                msgRen = "名前を変更"
                msgCancel = "キャンセル"
            } else if locationstr.hasPrefix("zh") {
                msgChoose = "选择操作"
                msgAdd = "新建工作表"
                msgDup = "副本"
                msgDel = "删除工作表"
                msgRen = "重命名"
                msgCancel = "取消"
            } else if locationstr.hasPrefix("fr") {
                msgChoose = "Choisir une action"
                msgAdd = "Ajouter feuille"
                msgDup = "Dupliquer"
                msgDel = "Supprimer feuille"
                msgRen = "Renommer"
                msgCancel = "Annuler"
            } else if locationstr.hasPrefix("de") {
                msgChoose = "Aktion wählen"
                msgAdd = "Blatt hinzufügen"
                msgDup = "Duplizieren"
                msgDel = "Blatt löschen"
                msgRen = "Umbenennen"
                msgCancel = "Abbrechen"
            } else if locationstr.hasPrefix("es") {
                msgChoose = "Elige una acción"
                msgAdd = "Añadir hoja"
                msgDup = "Duplicar"
                msgDel = "Eliminar hoja"
                msgRen = "Renombrar"
                msgCancel = "Cancelar"
            }

            let appd = UIApplication.shared.delegate as! AppDelegate
            let alert = UIAlertController(
                title: appd.sheetNames[indexPath.item],
                message: msgChoose,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: msgAdd, style: .default) { _ in
                self.createxlsxSheet()
            })

            alert.addAction(UIAlertAction(title: msgDup, style: .default) { _ in
                self.excelCopySheet()
            })

            alert.addAction(UIAlertAction(title: msgDel, style: .destructive) { _ in
                self.deletexlsxSheet()
            })

            alert.addAction(UIAlertAction(title: msgRen, style: .default) { _ in
                self.excelChangeSheetName()
            })

            alert.addAction(UIAlertAction(title: msgCancel, style: .cancel))
            
            
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()


            self.f_calculated.removeAll()
            self.f_content.removeAll()
            self.content.removeAll()
            self.location.removeAll()
            self.f_location_alphabet.removeAll()

            //print("sheet changed",indexPath.item)
            self.stringboxText = ""

            print("go to file view")
            print("selectedSheet",Int(appd.sheetNameIds[indexPath.item]))
            let sheetIdx = Int(appd.sheetNameIds[indexPath.item])

            // Row filter (columnFilters/filteredOutRows) is per-sheet data --
            // reset it on an actual sheet switch rather than carrying it over.
            // appd.wsSheetIndex still holds the *previous* sheet here (it's
            // only reassigned in the completion closure below), so this only
            // fires on a genuine switch, not a same-sheet reload (row/col
            // ops, rename, etc.).
            if sheetIdx != appd.wsSheetIndex {
                self.columnFilters.removeAll()
                self.filteredOutRows.removeAll()
                appd.rowFilterActive = false
                appd.visibleRows = []
            }

            // loadExcelSheet below is a synchronous, potentially multi-second
            // disk read/parse (same rationale as HomeController's overlay) --
            // showLoading() before the hop below lets the spinner actually
            // paint while it runs.
            self.showLoading()
            DispatchQueue.main.async {
                self.loadExcelSheet(idx:Int(appd.sheetNameIds[indexPath.item])! ){
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        // Flip the tab highlight only once the sheet has actually
                        // finished loading -- setting this before the async load
                        // above left the tab bar pointing at the new sheet while the
                        // grid still showed the old one whenever the app got
                        // backgrounded mid-load (nothing re-syncs the two later).
                        self.currentFileNameCollectionViewIdx = indexPath
                        // A plain tab tap used to leave appd.wsSheetIndex untouched --
                        // every other sheet-changing action (rename/delete/add/data
                        // input from another controller) does set it, so it went stale
                        // relative to currentFileNameCollectionViewIdx after a tap.
                        // appDidBecomeActive() below trusts wsSheetIndex as the source
                        // of truth on resume, so a stale value there was forcing the
                        // tab bar back to whatever sheet was last touched by one of
                        // those other actions instead of the one just tapped.
                        appd.wsSheetIndex = sheetIdx!
                        self.FileCollectionView.reloadData()
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                        self.hideLoading()
                        self.present(alert, animated: true)
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                        self.hideLoading()
                    }
                }

            }
      
        }
    }
    
    func loadExcelSheet(idx: Int, completion: (() -> Void)? = nil) {
        // Persisted here (rather than only on background/terminate) so an eviction
        // kill at any point still has the last successfully-requested sheet on
        // disk -- appd.wsSheetIndex itself is in-memory only and resets to 1 on a
        // fresh process, which is what caused the tab bar to snap back to sheet 1
        // after iOS silently killed a backgrounded instance of this app. Uses its
        // own key (not ViewController's lastWsSheetIndex_vc) since FF mode has its
        // own separate default file/workbook.
        UserDefaults.standard.set(idx, forKey: "lastWsSheetIndex_ff")
        do {
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.imported_xlsx_file_path == "" {
                self.isExcel = false
            }
            
            if appd.imported_xlsx_file_path != "" {
                print("yourExcelfile",appd.imported_xlsx_file_path)
                let ehp = ExcelHelper()
                let __readExcel2Start = CFAbsoluteTimeGetCurrent()
                ehp.readExcel2(path: appd.imported_xlsx_file_path, wsIndex: idx)
                print(String(format: "PERF loadExcelSheet.readExcel2: %.3fs", CFAbsoluteTimeGetCurrent() - __readExcel2Start))
                // Do any additional setup after loading the view.
                let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                //let url = serviceInstance.testSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
                let __testReadXMLStart = CFAbsoluteTimeGetCurrent()
                let notUsed = serviceInstance.testReadXMLSandBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
                print(String(format: "PERF loadExcelSheet.testReadXMLSandBox: %.3fs", CFAbsoluteTimeGetCurrent() - __testReadXMLStart))

                self.isExcel = true
            }

            //checkSheet
            let __isExcelSheetDataStart = CFAbsoluteTimeGetCurrent()
            isExcelSheetData(sheetIdx: idx)
            print(String(format: "PERF loadExcelSheet.isExcelSheetData: %.3fs", CFAbsoluteTimeGetCurrent() - __isExcelSheetDataStart))

            let __initSheetDataStart = CFAbsoluteTimeGetCurrent()
            initSheetData()
            print(String(format: "PERF loadExcelSheet.initSheetData: %.3fs", CFAbsoluteTimeGetCurrent() - __initSheetDataStart))

            let __storeValuesStart = CFAbsoluteTimeGetCurrent()
            // See the matching comment on datainputFromOtherComtroller's call --
            // dead undo mechanism, skipped for CSV to avoid the COW-copy trap.
            if !isCSV {
                fontcolorClass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
            }
            print(String(format: "PERF loadExcelSheet.storeValues: %.3fs", CFAbsoluteTimeGetCurrent() - __storeValuesStart))

            // Same reasoning as patchJsonCacheAndRefresh's guard: locationInExcel
            // is only consumed by formula processing and xlsx-XML-writing, both
            // no-ops for CSV -- confirmed via instrumentation to cost ~4.8s at
            // 1.4M cells on the initial CSV load.
            if !isCSV {
                let __initExcelLocationStart = CFAbsoluteTimeGetCurrent()
                initExcelLocation()
                print(String(format: "PERF loadExcelSheet.initExcelLocation: %.3fs", CFAbsoluteTimeGetCurrent() - __initExcelLocationStart))
            }

            // CSV cells have no cellStyleId (no styles.xml to resolve against) --
            // resolveCellStyles() is skipped outright for clarity/cost. But
            // skipping it means nothing ever resets cellBold/cellItalic/
            // cellBorder*/cellHorizontalAlign/cellVerticalAlign/cellWrapText --
            // resolveCellStyles()'s own guard (cellStyleId.count == location.count)
            // wouldn't help either, since it just returns without clearing
            // anything. cellForItemAt only bounds-checks "i < cellBold.count"
            // etc., which a leftover xlsx-sized array (from whatever file was
            // open before) always passes -- so a CSV opened right after an xlsx
            // silently rendered that xlsx's bold/italic/border/alignment
            // decoration at matching positions. CSV has no concept of any of
            // this, so always clear it outright.
            let __resolveCellStylesStart = CFAbsoluteTimeGetCurrent()
            if !isCSV {
                resolveCellStyles()
            } else {
                cellBold.removeAll()
                cellItalic.removeAll()
                cellUnderline.removeAll()
                cellStrike.removeAll()
                cellBorderLeftStyle.removeAll()
                cellBorderLeftColor.removeAll()
                cellBorderRightStyle.removeAll()
                cellBorderRightColor.removeAll()
                cellBorderTopStyle.removeAll()
                cellBorderTopColor.removeAll()
                cellBorderBottomStyle.removeAll()
                cellBorderBottomColor.removeAll()
                cellHorizontalAlign.removeAll()
                cellVerticalAlign.removeAll()
                cellWrapText.removeAll()
            }
            print(String(format: "PERF loadExcelSheet.resolveCellStyles: %.3fs", CFAbsoluteTimeGetCurrent() - __resolveCellStylesStart))


            localFileNames = appd.sheetNames //sheet1,sheet2
            FileCollectionView.reloadData()
            FileCollectionView.isHidden = isCSV




            for idx in 0..<COLUMNSIZE {
                let letters = getExcelColumnName(columnNumber: idx)
                columnNames.append(letters)
            }

            //Finally calculate -- CSV data has no formulas (=SUM(...) etc.), so
            // there's nothing for the formula-dependency-graph pass to find; skip
            // it rather than pay its cost scanning plain literal content for
            // formula prefixes that will never be there.
            let __calcMainStart = CFAbsoluteTimeGetCurrent()
            if !isCSV {
                calculatormode_update_main()
            }
            print(String(format: "PERF loadExcelSheet.calculatormode_update_main: %.3fs", CFAbsoluteTimeGetCurrent() - __calcMainStart))

            // Must run after calculatormode_update_main above, not before --
            // otherwise its whole-sheet recompute (driven by what readExcel2 just
            // read off disk) would immediately overwrite the reapplied values.
            reapplyPendingXlsxChanges(forSheet: idx)

            // An active filter's conditions (columnFilters) carry over across
            // a sheet switch, but filteredOutRows/appd.visibleRows were
            // computed against the *previous* sheet's content -- recompute
            // them against what was just loaded so the new sheet renders
            // correctly filtered rather than using stale results.
            if !columnFilters.isEmpty {
                applyRowFilters()
            }

            completion?()

        }catch {
            print(error)
        }
    }

    // Re-establishes any not-yet-flushed edits (see PendingXlsxChangeSet.swift)
    // on top of a fresh disk reload. loadExcelSheet's readExcel2 call above
    // repopulates content/location/f_calculated purely from what's on disk --
    // without this, switching sheet tabs and back would silently revert an
    // unflushed edit's visible effect, since loadExcelSheet runs on every tab
    // tap, not just when a genuinely new file is opened. Deliberately
    // reapplies in memory rather than flushing to disk here: flushing on an
    // ordinary tab switch would write to disk on an incidental UI action,
    // defeating the point of deferring the write to Export/Save.
    private func reapplyPendingXlsxChanges(forSheet sheetIndex: Int) {
        guard isExcel else { return }
        let ehp = ExcelHelper()
        for (key, edit) in pendingXlsxChanges.edits(forSheet: sheetIndex) {
            let posKey: String
            if let i = excelLocationIndex(for: key.cellId), i < content.count {
                content[i] = edit.content
                posKey = location[i]
            } else {
                // Cell had no prior entry at all (e.g. a blank template cell
                // never previously written to) -- readExcel2's reload has
                // nothing to overwrite, so append a fresh slot the same way
                // storeInput's "first entry" branch does. Style defaults match
                // storeInput's own selectingSize/selectingBgColor/selectingColor
                // initial values -- a toolbar style picked mid-session before
                // the original edit isn't recoverable here, so this always
                // falls back to the base style rather than guessing.
                let letters = String(key.cellId.prefix(while: { $0.isLetter }))
                let digits = String(key.cellId.drop(while: { $0.isLetter }))
                guard let col = ehp.columnToNumber(letters), let row = Int(digits) else { continue }
                posKey = "\(col),\(row)"
                content.append(edit.content)
                location.append(posKey)
                locationInExcel.append(key.cellId)
                cellStyleId.append("")
                textsize.append(String(10))
                bgcolor.append("white")
                tcolor.append("black")
            }
            if edit.content.hasPrefix("=") {
                if let k = fLocationIndex(for: posKey) {
                    f_calculated[k] = edit.calculatedValue
                } else {
                    f_location.append(posKey)
                    f_location_alphabet.append(key.cellId)
                    f_calculated.append(edit.calculatedValue)
                    invalidateFLocationIndexCache()
                }
            } else {
                removeFormulaEntry(posKey: posKey)
            }
        }
    }

    // Writes every not-yet-flushed edit (see PendingXlsxChangeSet.swift) into
    // the real .xlsx via service.swift's flushPendingEditsToXlsx, then clears
    // pendingXlsxChanges on success. No-op (returns true immediately) when
    // there's nothing pending. Call this before anything that reads
    // appd.imported_xlsx_file_path off disk -- export/save/email/iCloud
    // upload and the sheet-management operations (copy/add/delete/rename) --
    // since none of those re-serialize from memory themselves.
    @discardableResult
    func flushPendingXlsxChangesIfNeeded() -> Bool {
        guard pendingXlsxChanges.isDirty else { return true }
        let appd: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "", imp_formula: [String]())
        let ok = serviceInstance.flushPendingEditsToXlsx(fp: appd.imported_xlsx_file_path, edits: pendingXlsxChanges.edits)
        if ok {
            pendingXlsxChanges.clear()
            updateUnsavedDataReminderVisibility()
        }
        return ok
    }

    // Single entry point for the post-cell-edit refresh. Both call sites
    // used to call loadExcelSheet() directly; this just routes to the fast
    // path or the original path based on useFastCellEditReload, so flipping
    // the flag is the only thing needed to compare/revert.
    func applyCellEditAndRefresh(idx: Int, completion: (() -> Void)? = nil) {
        if useFastCellEditReload {
            patchJsonCacheAndRefresh(idx: idx, completion: completion)
        } else {
            loadExcelSheet(idx: idx, completion: completion)
        }
    }

    // Fast path for a single-cell edit commit. storeInput() already applied
    // the edit to content/location -- excelEntry() no longer writes it into
    // the xlsx file immediately (see PendingXlsxChangeSet.swift: it's recorded
    // in memory and only flushed to disk on Export/Save), but the in-memory
    // arrays are still the correct live state regardless -- so there's no need
    // to unzip and re-parse the whole xlsx again just to reconstruct state
    // that's already sitting correctly in memory --
    // that's what loadExcelSheet's readExcel2 + testReadXMLSandBox +
    // isExcelSheetData round trip does, and it's the "too slow" path flagged
    // in ExcelHelper.readExcel2's saveJsonFile comment.
    //
    // This only re-serializes the JSON sidecar cache (the "middleman json")
    // from the current in-memory arrays -- so a future full load, e.g. after
    // relaunch or switching sheets and back, still sees the edit -- and
    // reruns the remaining steps loadExcelSheet does after isExcelSheetData,
    // all of which are already in-memory-only (style resolution reads
    // appd.xfFontIds/xfFillIds/etc., populated once when the file was first
    // opened and unaffected by a plain value edit; formula recalc reads
    // content/location directly).
    func patchJsonCacheAndRefresh(idx: Int, completion: (() -> Void)? = nil) {
        let __patchJsonCacheAndRefreshStart = CFAbsoluteTimeGetCurrent()
        defer {
            perfLog(String(format: "PERF patchJsonCacheAndRefresh.total: %.3fs isCSV=%@ content=%d", CFAbsoluteTimeGetCurrent() - __patchJsonCacheAndRefreshStart, isCSV ? "true" : "false", content.count))
        }
        let appd: AppDelegate = UIApplication.shared.delegate as! AppDelegate

        if isExcel {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"

            let dict: [String: Any] = [
                "filename": "sheet" + String(idx) + ".xml",
                "date": dateFormatter.string(from: Date()),
                "content": content,
                "location": location,
                "fontsize": textsize,
                "fontcolor": tcolor,
                "bgcolor": bgcolor,
                "styleId": cellStyleId,
                "rowsize": ROWSIZE,
                "columnsize": COLUMNSIZE,
                "customcellWidth": appd.customSizedWidth,
                "customcellHeight": appd.customSizedHeight,
                "ccwLocation": appd.cswLocation,
                "cchLocation": appd.cshLocation,
                "formulaResult": [String](),
                "inputOrder": [String]()
            ]
            ReadWriteJSON().saveJsonFile(source: dict, title: "sheet" + String(idx) + ".xml")
        }

        let __initSheetDataStart = CFAbsoluteTimeGetCurrent()
        // skipRescan: true -- this is the post-single-cell-edit fast path, and
        // storeInput already keeps content clean/transformed incrementally for
        // the one cell that changed (see initSheetData's own doc comment).
        initSheetData(skipRescan: true)
        perfLog(String(format: "PERF patchJsonCacheAndRefresh.initSheetData: %.3fs content=%d", CFAbsoluteTimeGetCurrent() - __initSheetDataStart, content.count))

        let __storeValuesStart = CFAbsoluteTimeGetCurrent()
        // See the matching comment on datainputFromOtherComtroller's call --
        // dead undo mechanism, skipped for CSV to avoid the COW-copy trap.
        if !isCSV {
            fontcolorClass.storeValues(rl: location, rc: content, rsize: ROWSIZE, csize: COLUMNSIZE)
        }
        perfLog(String(format: "PERF patchJsonCacheAndRefresh.storeValues: %.3fs", CFAbsoluteTimeGetCurrent() - __storeValuesStart))

        // Full initExcelLocation() rebuild removed -- this function's only two
        // callers (shouldChangeTextIn, datainputFromOtherComtroller) already
        // call storeInput() first, which now keeps locationInExcel in sync
        // incrementally (see storeInput's edit/first-entry/clear cases). A full
        // rebuild here was pure redundant ~4.7s waste on a 1.4M-cell sheet on
        // every single keyboard-committed edit.

        if !isCSV {
            let __resolveCellStylesStart = CFAbsoluteTimeGetCurrent()
            resolveCellStyles()
            perfLog(String(format: "PERF patchJsonCacheAndRefresh.resolveCellStyles: %.3fs", CFAbsoluteTimeGetCurrent() - __resolveCellStylesStart))
        }
        // calculatormode_update_main() used to run here unconditionally on every
        // keyboard-committed edit -- but this function's only two callers
        // (shouldChangeTextIn's "\n" handler, datainputFromOtherComtroller) both
        // already call storeInput() first, which now recalculates the edited
        // cell itself via recalculateSingleCell (see storeInput). Re-running the
        // full whole-sheet calculatormode_update_main() here was pure redundant
        // ~4s+ waste on a 1.4M-cell sheet, AND could silently disagree with
        // storeInput's already-correct result -- confirmed via a self-referential
        // formula (typed directly into the cell it references) where this full
        // pass's circular-dependency handling left f_calculated empty/stale for
        // that cell while storeInput's scoped pass had already set it correctly,
        // and because FileCollectionView was never reloaded either (see below),
        // the cell kept showing raw "=..." text instead of either result.
        //
        // FileCollectionView itself was never reloaded after a keyboard edit at
        // all in this function (unlike its sibling loadExcelSheet, which does) --
        // that alone meant the edited cell never got a fresh cellForItemAt call
        // to pick up storeInput's result, regardless of which calculation ran.
        let __reloadStart = CFAbsoluteTimeGetCurrent()
        FileCollectionView.reloadData()
        perfLog(String(format: "PERF patchJsonCacheAndRefresh.reloadData: %.3fs", CFAbsoluteTimeGetCurrent() - __reloadStart))
        completion?()
    }

//    xlsx numFmtId
//    numFmtId    Format Code    Description
//    0    General    General format
//    1    0    Decimal
//    2    0.00    Decimal with two places
//    3    #,##0    Thousands separator
//    4    #,##0.00    Thousands separator with two places
//    9    0%    Percentage
//    10    0.00%    Percentage with two places
//    11    0.00E+00    Scientific notation
//    12    # ?/?    Fraction (1/4)
//    13    # ??/??    Fraction (1/16)
//    14    mm-dd-yy    Date
//    15    d-mmm-yy    Date
//    16    d-mmm    Date
//    17    mmm-yy    Date
//    18    h:mm AM/PM    Time
//    19    h:mm:ss AM/PM    Time
//    20    h:mm    Time
//    21    h:mm:ss    Time
//    22    m/d/yy h:mm    Date and time
//    37    #,##0_);(#,##0)    Accounting
//    38    #,##0_);[Red](#,##0)    Accounting (with red negative numbers)
//    39    #,##0.00_);(#,##0.00)    Accounting with two decimal places
//    40    #,##0.00_);[Red](#,##0.00)    Accounting with red negative numbers
//    45    mm:ss    Elapsed time
//    46    [h]:mm:ss    Elapsed time with hours
//    47    mmss.0    Elapsed time with decimal seconds
//    48    ##0.0E+0    Scientific with one place
//    49    @    Text
//
    
    
    //http://stackoverflow.com/questions/27674317/changing-cell-background-color-in-uicollectionview-in-swift
    //data input
    func opendatainputview(){
        //don't forget first call
        if datainputview != nil{
            datainputview.removeFromSuperview()
        }
        
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                // It's an iPhone
                if Double(SCREENSIZE) != nil && Double(KEYBOARDLOCATION) != nil &&  SCREENSIZE > 0 &&  KEYBOARDLOCATION > 0 && Int(SCREENSIZE - KEYBOARDLOCATION - 60.0) > 0 {
                    // The result is an integer and greater than 0
                    datainputview = Datainputview(frame: CGRect(x:0,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 360,height: 60))

                } else {
                    datainputview = Datainputview(frame: CGRect(x:0,y:200, width: 360,height: 60))
                }



                datainputview.downArrow.addTarget(self, action: #selector(imoveDown), for: UIControl.Event.touchUpInside)
                datainputview.rightArrow.addTarget(self, action: #selector(imoveRight), for: UIControl.Event.touchUpInside)
                datainputview.handWritingInputButton.addTarget(self, action: #selector(hwAction), for: UIControl.Event.touchUpInside)
                // Disabled here (not wired to speechAction) -- this
                // controller's speech feature never got the round of fixes
                // ViewController's did (threading race, decoupling from
                // datainputview, the speechView panel, etc.), so it's turned
                // off rather than left reachable in a known-buggier state.
                datainputview.speechButton.isEnabled = false
                
                break
            case .pad:
                
                // It's an iPad
                datainputview = Datainputview(frame: CGRect(x:Int(60),y:Int(SCREENSIZE - KEYBOARDLOCATION - 160.0), width: 642,height: 160))
                datainputview.downArrow.addTarget(self, action: #selector(moveDown), for: UIControl.Event.touchUpInside)
                datainputview.rightArrow.addTarget(self, action: #selector(moveRight), for: UIControl.Event.touchUpInside)
                
                
                
                //formula buttons
                datainputview.sinButton.addTarget(self, action: #selector(sinAction), for: UIControl.Event.touchUpInside)
                datainputview.asinButton.addTarget(self, action: #selector(asinAction), for: UIControl.Event.touchUpInside)
                datainputview.cosButton.addTarget(self, action: #selector(cosAction), for: UIControl.Event.touchUpInside)
                datainputview.acosButton.addTarget(self, action: #selector(acosAction), for: UIControl.Event.touchUpInside)
                datainputview.tanButton.addTarget(self, action: #selector(tanAction), for: UIControl.Event.touchUpInside)
                datainputview.atanButton.addTarget(self, action: #selector(atanAction), for: UIControl.Event.touchUpInside)
                datainputview.logdButton.addTarget(self, action: #selector(logdAction), for: UIControl.Event.touchUpInside)
                datainputview.lnButton.addTarget(self, action: #selector(lnAction), for: UIControl.Event.touchUpInside)
                datainputview.expButton.addTarget(self, action: #selector(expAction), for: UIControl.Event.touchUpInside)
                datainputview.powButton.addTarget(self, action: #selector(powAction), for: UIControl.Event.touchUpInside)
                //datainputview.dragbutton.addTarget(self, action: #selector(handlePan), for: UIControl.Event.touchUpInside)
                

                datainputview.piButton.addTarget(self, action: #selector(piAction), for: UIControl.Event.touchUpInside)

                datainputview.plusButton.addTarget(self, action: #selector(plusmarkAction), for: UIControl.Event.touchUpInside)
                datainputview.crossButton.addTarget(self, action: #selector(crossAction), for: UIControl.Event.touchUpInside)
                datainputview.openBraceButton.addTarget(self, action: #selector(openBraceAction), for: UIControl.Event.touchUpInside)
                datainputview.closeBraceButton.addTarget(self, action: #selector(closeBraceAction), for: UIControl.Event.touchUpInside)
                datainputview.commaButton.addTarget(self, action: #selector(commaAction), for: UIControl.Event.touchUpInside)
                datainputview.colonButton.addTarget(self, action: #selector(colonAction), for: UIControl.Event.touchUpInside)
                
                datainputview.handWritingInputButton.addTarget(self, action: #selector(hwAction), for: UIControl.Event.touchUpInside)
                // Disabled here (not wired to speechAction) -- this
                // controller's speech feature never got the round of fixes
                // ViewController's did (threading race, decoupling from
                // datainputview, the speechView panel, etc.), so it's turned
                // off rather than left reachable in a known-buggier state.
                datainputview.speechButton.isEnabled = false
                
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                datainputview.addGestureRecognizer(panGesture)
                datainputview.isUserInteractionEnabled = true
               
                
                break
            case .unspecified:
                // Uh, oh! What could it be?
                if Double(SCREENSIZE) != nil && Double(KEYBOARDLOCATION) != nil &&  SCREENSIZE > 0 &&  KEYBOARDLOCATION > 0 && Int(SCREENSIZE - KEYBOARDLOCATION - 60.0) > 0 {
                    // The result is an integer and greater than 0
                    datainputview = Datainputview(frame: CGRect(x:0,y:Int(SCREENSIZE - KEYBOARDLOCATION - 60.0), width: 360,height: 60))

                } else {
                    datainputview = Datainputview(frame: CGRect(x:0,y:200, width: 360,height: 60))
                }

                break
            default:
                break
            }
        
        
        up_bool = false
        down_bool = false
        right_bool = false
        left_bool = false
        
        
        datainputview.stringbox.delegate = self
        datainputview.stringbox.layer.borderWidth = 1
        datainputview.stringbox.layer.borderColor = UIColor.gray.cgColor
        
        datainputview.okbutton.addTarget(self, action: #selector(FileFillViewController.terminate), for: UIControl.Event.touchUpInside)
        
//        datainputview.returnbutton.addTarget(self, action: #selector(FileFillViewController.restore), for: UIControl.Event.touchUpInside)
//
        datainputview.returnbutton.addTarget(self, action: #selector(barcodeAction), for: UIControl.Event.touchUpInside)

        
        //give user a hint
        datainputview.getValuesButton.addTarget(self, action: #selector(showHint), for: UIControl.Event.touchUpInside)
        

        
        datainputview.stringbox.becomeFirstResponder()
        
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!

        
        
        if sum_str.count > 0 {
            datainputview.stringbox.text = sum_str
            sum_str = ""
        }
        
        self.view.addSubview(datainputview)

        
        
        //http://studyswift.blogspot.jp/2015/01/showhide-keyboard-while-using.html
        //https://stackoverflow.com/questions/46375700/programmatically-create-touchupinside-event-for-uitextfield
        
        
        
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let targetView = gesture.view else { return }
        let translation = gesture.translation(in: view)
        
        if gesture.state == .began {
            targetView.translatesAutoresizingMaskIntoConstraints = true
        }
        
        if gesture.state == .changed {
            targetView.center = CGPoint(
                x: targetView.center.x + translation.x,
                y: targetView.center.y + translation.y
            )
            gesture.setTranslation(.zero, in: view)
        }
    }
    
    //https://stackoverflow.com/questions/30937342/check-if-a-subview-is-in-a-view-using-swift
    @objc func showHint(){
        if Hintview != nil{
            if self.view.subviews.contains(Hintview){
                Hintview.removeFromSuperview()
            }else{
                Hintview = Hint(frame: CGRect(x:Int(15),y:Int(50), width: 300,height: 330))
                Hintview.hintCloseButton.addTarget(self, action: #selector(FileFillViewController.closeHview), for: UIControl.Event.touchUpInside)
                
                self.view.addSubview(Hintview)
            }
        }else{
            Hintview = Hint(frame: CGRect(x:Int(15),y:Int(50), width: 300,height: 330))
            Hintview.hintCloseButton.addTarget(self, action: #selector(FileFillViewController.closeHview), for: UIControl.Event.touchUpInside)
            
            self.view.addSubview(Hintview)
        }
    }
    
    @objc func getRef(){
        if getRefmode == false{
                getRefmode = true
                datainputview.getRefButton.setTitleColor(UIColor.yellow, for: .normal)
            }else if getRefmode == true{
                getRefmode = false
                datainputview.getRefButton.setTitleColor(UIColor.white, for: .normal)
            }
    }
    
    
    @objc func csvexport(result:[String])
    {
        
        if customview2 != nil{
            self.customview2.removeFromSuperview()
        }
        //http://stackoverflow.com/questions/32593516/how-do-i-exactly-export-a-csv-file-from-ios-written-in-swift
        let mailString = NSMutableString()

        var locationIndex: [String: Int] = [:]
        locationIndex.reserveCapacity(location.count)
        for (idx, loc) in location.enumerated() {
            if locationIndex[loc] == nil {
                locationIndex[loc] = idx
            }
        }

        for i in (1..<ROWSIZE)
        {
            for j in (1..<COLUMNSIZE)
            {
                let PATH :String =  String(j) + "," + String(i)//String(i) + "," + String(j)

                if let k = locationIndex[PATH] {
                    if result[k].contains(","){
                        mailString.append(result[k].replacingOccurrences(of: ",", with: "#comma#"))
                    }else if result[k].contains("\n"){

                    }else{

                        mailString.append(result[k])

                    }

                }
                else{

                    mailString.append("")

                }
                
                if j == COLUMNSIZE-1 {
                    //last element
                }else{
                    mailString.append(",")
                }
            }
            
            mailString.append("\n")
            
            
            
        }
        
        byproduct = mailString
        data = mailString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
        
        //save on a temo folder
        saveAsCSV(mailString: byproduct! as String, fileName: "tempCSV")
        
    }
    
    func saveAsCSV(mailString: String, fileName: String) {
        // Convert the string to data
        guard let data = mailString.data(using: .utf8) else {
            print("Failed to convert string to data.")
            return
        }
        
        let fileManager = FileManager.default
            
        // Get the path to save the file
        let pathDirectory = getRootDocumentsDirectory()
        let folderPath = pathDirectory.appendingPathComponent("importedCSV")
        let filePath = pathDirectory.appendingPathComponent("importedCSV").appendingPathComponent("\(fileName).csv")
        
        //is the folder created already?
        if !fileManager.fileExists(atPath: folderPath.path) {
            do {
                try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                print("Folder created successfully at \(folderPath.path)")
            } catch {
                print("An error occurred while creating the folder: \(error.localizedDescription)")
                return
            }
        }
        
        
        
        
        do {
            if fileManager.fileExists(atPath:filePath.path) {
                try fileManager.removeItem(at: filePath)
            }
            
            // Write the data to the file
            try data.write(to: filePath, options: .atomic)
            print("CSV file saved successfully at \(filePath.path)")
        } catch {
            print("An error occurred while saving the CSV file: \(error.localizedDescription)")
        }
    }
    
    
    @objc func back2(_ sender:UIButton)
    {
        selection_bool = false
        myCollectionView.reloadData()
        self.customview2.removeFromSuperview()
    }
    
    @objc func backRS(_ sender:UIButton)
    {
        selection_bool = false
        myCollectionView.reloadData()
        self.rsview.removeFromSuperview()
    }
    
    @objc func backRS2()
    {
        selection_bool = false
        myCollectionView.reloadData()
        if self.rsview != nil{
            self.rsview.removeFromSuperview()
        }
    }
    
    
    @objc func loadCreditview(_ sender:UIButton)
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //       postAction()
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "creditView" ) as! CreditController
        if isExcel{
            targetViewController.idx = Int(appd.sheetNameIds[selectedSheet])
        }
        targetViewController.modalPresentationStyle = .fullScreen
        self.present( targetViewController, animated: true, completion: nil)
        
        self.customview2.removeFromSuperview()
    }
    
    
    
    
    @objc func icloudview(_ sender:UIButton){
        
        var message = "Current data will be lost. Is that ok?"
        var yes = "OK"
        var no = "No"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            message = "現在のデータは失われます。それは大丈夫ですか？"
            yes = "はい"
            no = "いいえ"
        }else if locationstr.contains( "fr")
        {
            message = "Les données actuelles seront perdues. Est-ce que ça va?"
            yes = "oui"
            no = "non"
        }else if locationstr.contains( "zh"){
            
            message = "当前数据将丢失。这可以吗？"
            yes = "是"
            no = "否"
        }else if locationstr.contains( "de")
        {
            
            message = "Aktuelle Daten gehen verloren. Ist das in Ordnung?"
            yes = "ja"
            no = "nein"
        }else if locationstr.contains( "it")
        {
            
            message = "I dati attuali andranno persi. È ok?"
            yes = "si"
            no = "no"
        }else if locationstr.contains( "ru")
        {
            
            message = "Текущие данные будут потеряны. Это нормально?"
            yes = "да"
            no = "нет"
        }else if locationstr.contains("sv")
        {
            message = "Nuvarande data kommer att gå förlorade. Är det okej?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("da")
        {
            message = "Aktuelle data vil gå tabt. Er det i orden?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("ar")
        {
            message = "ستفقد البيانات الحالية. هل هذا جيد؟"
            yes = "نعم"
            no = "لا"
            
        }else if locationstr.contains("es")
        {
            message = "Los datos actuales se perderán. ¿Eso esta bien?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: yes, style: .default, handler: { action in
            //reset all
            self.location.removeAll()
            self.content.removeAll()
            self.bgcolor.removeAll()
            self.cursor = String()
            self.tcolor.removeAll()
            self.textsize.removeAll()
            self.pendingXlsxChanges.clear()
            self.updateUnsavedDataReminderVisibility()
            self.columnFilters.removeAll()
            self.filteredOutRows.removeAll()

            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()

            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.rowFilterActive = false
            appd.visibleRows = []

            //Delete all xml files
            let fileList = appd.sheetNameIds.map { "sheet\($0)" }
            
            for i in 0..<fileList.count{
                let name = fileList[i]
                
                self.deleteLocalJson(filename:name)
                
                self.localFileNames.removeAll()
                
                self.FileCollectionView.reloadData()
                
                self.customview2.removeFromSuperview()

            }
            
            //delete local excel -- FF mode's own dedicated copy, never
            // ViewController's initialXLSX.xlsx (see moveToFilefill()).
            let pathDirectory = self.getRootDocumentsDirectory()
            let filePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX_ff.xlsx")
            let fileManager = FileManager.default
            do {
                if fileManager.fileExists(atPath: filePath.path) {
                    try fileManager.removeItem(at: filePath)
                    print("File deleted successfully.")
                } else {
                    print("File does not exist.")
                }
            } catch {
                print("An error occurred while deleting the file: \(error.localizedDescription)")
            }

            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "iCloud" ) as! iCloudViewController//Landscape
            targetViewController.isFileFillMode = true
            targetViewController.modalPresentationStyle = .fullScreen
            self.present( targetViewController, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))

        self.present(alert, animated: true)
        
        
        
        self.customview2.removeFromSuperview()
        
    }
    
    
    @objc func resetSheet(_ sender:UIButton){
        
        var message = "Any unsaved data will be lost. Be sure to export is before resetting."
        var yes = "OK"
        var no = "No"
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        if locationstr.contains( "ja")
        {
            message = "現在のデータは失われます。それは大丈夫ですか？"
            yes = "はい"
            no = "いいえ"
        }else if locationstr.contains( "fr")
        {
            message = "Les données actuelles seront perdues. Est-ce que ça va?"
            yes = "oui"
            no = "non"
        }else if locationstr.contains( "zh"){
            
            message = "当前数据将丢失。这可以吗？"
            yes = "是"
            no = "否"
        }else if locationstr.contains( "de")
        {
            
            message = "Aktuelle Daten gehen verloren. Ist das in Ordnung?"
            yes = "ja"
            no = "nein"
        }else if locationstr.contains( "it")
        {
            
            message = "I dati attuali andranno persi. È ok?"
            yes = "si"
            no = "no"
        }else if locationstr.contains( "ru")
        {
            
            message = "Текущие данные будут потеряны. Это нормально?"
            yes = "да"
            no = "нет"
        }else if locationstr.contains("sv")
        {
            message = "Nuvarande data kommer att gå förlorade. Är det okej?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("da")
        {
            message = "Aktuelle data vil gå tabt. Er det i orden?"
            yes = "ja"
            no = "nej"
        }else if locationstr.contains("ar")
        {
            message = "ستفقد البيانات الحالية. هل هذا جيد؟"
            yes = "نعم"
            no = "لا"
            
        }else if locationstr.contains("es")
        {
            message = "Los datos actuales se perderán. ¿Eso esta bien?"
            yes = "si"
            no = "no"
        }else{
            
        }
        
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: yes, style: .default, handler: { action in
            //reset all
            self.location.removeAll()
            self.content.removeAll()
            self.bgcolor.removeAll()
            self.cursor = String()
            self.tcolor.removeAll()
            self.textsize.removeAll()
            self.pendingXlsxChanges.clear()
            self.updateUnsavedDataReminderVisibility()
            self.columnFilters.removeAll()
            self.filteredOutRows.removeAll()

            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()

            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.rowFilterActive = false
            appd.visibleRows = []
            appd.cswLocation.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.customSizedHeight.removeAll()
            appd.cswLocation_temp.removeAll()
            appd.cshLocation_temp.removeAll()
            appd.customSizedWidth_temp.removeAll()
            appd.customSizedHeight_temp.removeAll()
            appd.diff_end_index.removeAll()
            appd.diff_start_index.removeAll()
            appd.CELL_HEIGHT_EXCEL_GSHEET = -1.0
            appd.CELL_WIDTH_EXCEL_GSHEET = -1.0
            appd.sheetNames = [String]()
            appd.sheetNameIds = [String]()
            appd.imported_xlsx_file_path = ""
            appd.imported_xlsx_file_path = ""
            appd.isAppStarted = false
        
            let sheet1Json = ReadWriteJSON()
            sheet1Json.deleteJsonFile(title: "csv_sheet1")
            
            //delete local excel -- FF mode's own dedicated copy, never
            // ViewController's initialXLSX.xlsx (see moveToFilefill()).
            let pathDirectory = self.getRootDocumentsDirectory()
            let filePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX_ff.xlsx")
            let fileManager = FileManager.default
            do {
                if fileManager.fileExists(atPath: filePath.path) {
                    try fileManager.removeItem(at: filePath)
                    print("File deleted successfully.")
                } else {
                    print("File does not exist.")
                }
            } catch {
                print("An error occurred while deleting the file: \(error.localizedDescription)")
            }

            self.customview2.removeFromSuperview()
            
            let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "LoadingViewController" )//Landscape
            targetViewController.modalPresentationStyle = .fullScreen
            self.present( targetViewController, animated: true, completion: nil)
            
        }))
        alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
        
        self.present(alert, animated: true)
        self.customview2.removeFromSuperview()
        
    }
    
    @objc func goSettings(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "Settings" ) as! SettingsViewController
        if isExcel{
            targetViewController.idx = Int(appd.sheetNameIds[selectedSheet])
        }
        targetViewController.modalPresentationStyle = .fullScreen
        print("go to setting view")
      
        self.saveAsLocalJson(filename: "csv_sheet1")
        // Present the target view controller after LoadingFileController's view has appeared
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        
    }
    
    
    // Gives the user feedback during a synchronous, potentially multi-second
    // operation (row filtering over a large sheet, email export, save
    // backup) -- doesn't make the work itself any faster, same pattern/
    // rationale as HomeController's mode-button loading overlay.
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

    override func viewDidLoad() {
        hiddenTextField.becomeFirstResponder()
        menuButton.layer.borderWidth = 1.0
        myCollectionView.layer.borderWidth = 1.0
        myCollectionView.layer.borderColor = UIColor.gray.cgColor

        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(loadingSpinner)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingSpinner.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor),
        ])

        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate

        // Restore the sheet tab this controller was last showing -- appd.wsSheetIndex
        // is in-memory only, so on a fresh process (including an eviction-triggered
        // relaunch that looks to the user like a normal background resume) it would
        // otherwise sit at its default of 1 regardless of what was actually open.
        if let savedSheetIndex = UserDefaults.standard.object(forKey: "lastWsSheetIndex_ff") as? Int {
            appd.wsSheetIndex = savedSheetIndex
        }

        super.viewDidLoad()

        columninNumber.removeAll()
        columninNumber.append("null")
        rowinNumber.removeAll()
        rowinNumber.append("null")

        //http://qiita.com/xa_un/items/814a5cd4472674640f58
        tag_int = appd.tag_int
        myCollectionView.delegate = self
        orientaion = "P"
        
        // Tracks whether loadExcelSheet() already ran below, so the "checkSheet"
        // fallback further down knows whether it still needs to load anything.
        var didLoadSheetInViewDidLoad = false

        if appd.imported_xlsx_file_path == "" && isCSV == false{
            let pathDirectory = getRootDocumentsDirectory()
            // FileFillViewController's default file is kept separate from
            // ViewController's initialXLSX.xlsx (see moveToFilefill(), which is the
            // normal entry point and already hands over a dedicated "_ff" copy) --
            // this branch only matters for the edge case of entering FF mode with no
            // file already selected.
            let filePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX_ff.xlsx")
            let fileExists = FileManager.default.fileExists(atPath: filePath.path)
            isExcel = true
            if fileExists{
                appd.imported_xlsx_file_path=filePath.path
                // iCloudViewController.readExcel is a separate, older duplicate
                // parse+JSON-save that never learned about styleId -- loadExcelSheet
                // already does its own fresh ExcelHelper.readExcel2 parse (the one
                // with styleId) every time it's called, so routing through the
                // duplicate here was just wasted work parsing the file twice on
                // every cold launch.
                self.loadExcelSheet(idx: appd.wsSheetIndex)
                didLoadSheetInViewDidLoad = true
            }
            if !fileExists {
                print("File doesn't exist at path: \(filePath.path)")
                //loadinitialXLSX so it's reading from actual file
                if let filePath2 = Bundle.main.path(forResource: "initialXLSX", ofType: "xlsx"){
                    do {
                        let icc = iCloudViewController()
                        icc.loadInitialXLSX(url: URL(fileURLWithPath: filePath2))
                        // loadInitialXLSX unconditionally lands the bundled template at
                        // the shared initialXLSX.xlsx -- copy it over to this
                        // controller's own dedicated "_ff" path so FF mode still never
                        // ends up pointed at ViewController's file.
                        if !appd.imported_xlsx_file_path.isEmpty {
                            let sourceURL = URL(fileURLWithPath: appd.imported_xlsx_file_path)
                            if FileManager.default.fileExists(atPath: filePath.path) {
                                try? FileManager.default.removeItem(at: filePath)
                            }
                            try? FileManager.default.copyItem(at: sourceURL, to: filePath)
                            appd.imported_xlsx_file_path = filePath.path
                        }
                        // loadInitialXLSX only copies the bundled file into place and
                        // sets appd.imported_xlsx_file_path now -- it no longer parses
                        // it itself, so loadExcelSheet does the (styleId-aware) parse.
                        self.loadExcelSheet(idx: appd.wsSheetIndex)
                        didLoadSheetInViewDidLoad = true
                        //                    appd.imported_xlsx_file_path=filePath.path
                        //                    icc.readExcel(path: filePath.path)
                    } catch {
                        print("Error reading file: \(error)")
                    }
                }
            }
        }

        //checkSheet -- loadExcelSheet() above already runs isExcelSheetData/
        // initSheetData/storeValues/initExcelLocation *and* resolveCellStyles.
        // Calling those four again unconditionally (the old code) re-read the same
        // JSON and reset textsize/tcolor/bgcolor/cellBold back to plain defaults
        // with no resolveCellStyles() afterward to fix them back up -- so styling
        // never actually showed up on the first frame after a cold launch. Only
        // fall back to loading here when imported_xlsx_file_path was already set
        // *before* this viewDidLoad ran (e.g. presented straight from the
        // document-picker import flow, which sets the path itself beforehand).
        if !didLoadSheetInViewDidLoad {
            // appd.wsSheetIndex is the actual "currently selected sheet" state --
            // every other loadExcelSheet call site in this codebase uses it.
            // sheetNameIds.first (the old code here) is always the *first* sheet
            // in the workbook, so returning from LoadingFileController (settings
            // changes, the cell-size slider, etc.) was resetting back to sheet 1
            // instead of staying on whatever sheet was actually open.
            self.loadExcelSheet(idx: appd.wsSheetIndex)
        }

        // currentFileNameCollectionViewIdx (drives which FileCollectionView tab
        // gets the selection highlight) defaults to item 0 for a fresh
        // ViewController instance -- without this, the tab bar highlighted the
        // first sheet even though loadExcelSheet (whichever branch above ran it)
        // just correctly loaded the real (previously selected) sheet's content.
        // This has to run regardless of which branch loaded the sheet -- it used
        // to be nested inside the block above and only ran on the fallback path,
        // so the default-file cold-launch branch further up left the tab bar on
        // item 0 even when the restored wsSheetIndex pointed at a different tab.
        if let matchIndex = appd.sheetNameIds.firstIndex(of: String(appd.wsSheetIndex)) {
            self.currentFileNameCollectionViewIdx = IndexPath(item: matchIndex, section: 0)
            self.FileCollectionView.reloadData()
        }

        //https://stackoverflow.com/questions/31774006/how-to-get-height-of-keyboard
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )

        // appd.wsSheetIndex is shared with ViewController, and neither controller
        // re-syncs currentFileNameCollectionViewIdx against it when the app comes
        // back from the background (this VC stays alive the whole time, so
        // viewWillAppear/viewDidLoad never re-run) -- without this, a sheet switch
        // that changed wsSheetIndex while this VC wasn't the one driving it left
        // the tab bar highlighting a sheet other than the one actually on screen
        // after resume.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSNotification.Name.UIApplicationDidBecomeActive,
            object: nil
        )


//        bannerview.isHidden = true
//        bannerview.delegate = self
//        bannerview.adUnitID = "ca-app-pub-5284441033171047/5452654189"
//        bannerview.rootViewController = self
//        bannerview.load(Request())
        
        Thread.sleep(forTimeInterval: 0.5)
        let pointA = CGPoint.init(x: 600, y: 600)
        myCollectionView.setContentOffset(pointA, animated: true)
        myCollectionView.scrollToNextItem()
        
        localFileNames = appd.sheetNames //sheet1,sheet2
        FileCollectionView.reloadData()
        // A CSV file has no concept of multiple sheets (isExcelSheetData's
        // isExcel==false branch always reads the single "csv_sheet1" sidecar) --
        // the tab bar showing "sheet1" for it is misleading, so hide it entirely.
        FileCollectionView.isHidden = isCSV



        
        
        // columnNames and the formula recalc below are already done inside
        // loadExcelSheet() (called unconditionally, exactly once, earlier in this
        // same viewDidLoad) -- redoing them here just duplicated columnNames'
        // entries and reran the full formula recalc pass a second time on
        // unchanged data.

        DispatchQueue.main.async() {
            appd.collectionViewCellSizeChanged = 1
            self.myCollectionView.collectionViewLayout.invalidateLayout()
            self.myCollectionView.reloadData()
        }
        
        checkAndUpdateLaunchDateAlsoTakeDailyBackup()
        
        #if !targetEnvironment(macCatalyst)
//        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
//        doubleTapGesture.numberOfTapsRequired = 2
//        myCollectionView.addGestureRecognizer(doubleTapGesture)
        #endif

        cellSizeSlicer.addTarget(self, action: #selector(cellSizeSliderTouchDown(_:)), for: .touchDown)
        cellSizeSlicer.addTarget(self, action: #selector(cellSizeSliderChanged(_:)), for: .valueChanged)
        cellSizeSlicer.addTarget(self, action: #selector(cellSizeSliderReleased(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        configureCellSizeSlider()

        let isJapanese = (NSLocale.preferredLanguages.first ?? "en").hasPrefix("ja")
        unsavedDataReiminderBUtton.setTitle(isJapanese ? "未保存" : "Unsaved", for: .normal)
        unsavedDataReiminderBUtton.addTarget(self, action: #selector(unsavedDataReminderTapped), for: .touchUpInside)
        updateUnsavedDataReminderVisibility()

    }

    // Shows/hides unsavedDataReiminderBUtton to match whether there are
    // pending xlsx edits not yet flushed to disk (see PendingXlsxChangeSet.swift).
    // Call this at every point pendingXlsxChanges is mutated (record or clear).
    func updateUnsavedDataReminderVisibility() {
        unsavedDataReiminderBUtton.isHidden = !pendingXlsxChanges.isDirty
    }

    @objc func unsavedDataReminderTapped() {
        // Same "Save Backup" filename-prompt modal as the toolbar's save
        // button (filesave()) -- it already flushes pendingXlsxChanges
        // internally before writing, so the button hides itself via
        // updateUnsavedDataReminderVisibility() inside that flush once it
        // succeeds.
        filesave()
    }
    
    func checkAndUpdateLaunchDateAlsoTakeDailyBackup() {
        let calendar = Calendar.current
        let today = Date()
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate

        guard !calendar.isDate(appd.lastLaunchDate, inSameDayAs: today) else { return }

        appd.lastLaunchDate = today
        UserDefaults.standard.set(today, forKey: "lastLaunchDateKey")

        func proceedWithDailyBackup() {
            self.takeDailyBackup(msg: "daily_")
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let rlt = serviceInstance.removeXlsxBackup(forFileFill: true)
            if rlt == false{
                print("auto backup removal failed")
            }
        }

        guard pendingXlsxChanges.isDirty else {
            proceedWithDailyBackup()
            return
        }

        // Unflushed edits exist (see PendingXlsxChangeSet.swift) and this is
        // the once-daily backup trigger -- backing up now would otherwise
        // silently snapshot a stale on-disk file. Let the user choose.
        var message = "You have unsaved changes. Save them now before today's backup?"
        var saveNow = "Save now"
        var notNow = "Not now"
        let locationstr = (NSLocale.preferredLanguages[0] as String?) ?? "en"
        if locationstr.contains("ja") {
            message = "未保存の変更があります。今日のバックアップの前に保存しますか？"
            saveNow = "今すぐ保存"
            notNow = "後で"
        }

        let alert = UIAlertController(title: "Unsaved Changes", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: saveNow, style: .default) { [weak self] _ in
            self?.flushPendingXlsxChangesIfNeeded()
            proceedWithDailyBackup()
        })
        alert.addAction(UIAlertAction(title: notNow, style: .cancel) { _ in
            proceedWithDailyBackup()
        })
        // Deferred a turn -- this is called from viewDidLoad, before this
        // controller is necessarily in the window hierarchy yet.
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    
    
    //Filename Change
    //
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: myCollectionView)
        
        if let indexPath = myCollectionView.indexPathForItem(at: location) {
            print("Double-tapped cell at \(indexPath)")
            // Perform your double-tap action here
        }
        
        selection_bool = true
        myCollectionView.reloadData()
    }
    
    func extractExcelCellReferences(from expression: String) -> [String] {
        // Define a regular expression for Excel cell references
        let regexPattern = "[A-Za-z]+\\d+"
        
        // Compile the regex pattern
        let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
        
        // Extract matches from the input expression
        let matches = regex.matches(in: expression, options: [], range: NSRange(location: 0, length: expression.utf16.count))
        
        // Convert matches into strings
        return matches.compactMap { match in
            if let range = Range(match.range, in: expression) {
                return String(expression[range])
            }
            return nil
        }
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let cell = gesture.view as? CustomCollectionViewCell,
                //touched cell index not selected index
                let indexPath = myCollectionView.indexPath(for: cell)
        else { return }
        let startRow = indexPath.section
        let startCol = indexPath.item
        let idxInLocation = locationIndex(for: cursor) ?? -1
        let lIndex = excelLocationIndex(for: label.text ?? "") ?? -1
        
        switch gesture.state {
        case .began:
            print("start")
            tempRangeSelected = []
            tempRangeSelected.append(indexPath)
            // Change background color to indicate dragging started
            cell.label2.backgroundColor = UIColor.systemBlue // Change the color dynamically
            let locationCG = gesture.location(in: myCollectionView)
            if let newIndexPath = myCollectionView.indexPathForItem(at: locationCG) {
                if let cell2 = myCollectionView.cellForItem(at: newIndexPath) as? CustomCollectionViewCell {
                    //cell2.label2.layer.borderWidth = 1.0
                    cell2.label2.backgroundColor = UIColor.systemBlue
                    if (tempRangeSelected.firstIndex(of: newIndexPath) == nil){
                        tempRangeSelected.append(newIndexPath)
                    }
                }
            }
            break
            
        case .changed:
            let locationCG = gesture.location(in: myCollectionView)
            if let newIndexPath = myCollectionView.indexPathForItem(at: locationCG) {
                if let cell2 = myCollectionView.cellForItem(at: newIndexPath) as? CustomCollectionViewCell {
                    //cell2.label2.layer.borderWidth = 1.0
                    cell2.label2.backgroundColor = UIColor.systemBlue
                    if (tempRangeSelected.firstIndex(of: newIndexPath) == nil){
                        tempRangeSelected.append(newIndexPath)
                    }
                }
            }
            break
            
        case .ended, .cancelled:
            let locationCG = gesture.location(in: myCollectionView)
            if let newIndexPath = myCollectionView.indexPathForItem(at: locationCG) {
                tempRangeSelected.append(newIndexPath)
            }
            print("selected(row,col)",tempRangeSelected)
            // Restore the original background color
            print("ended")
            
            // 重複を排除してソート（選択順ではなく座標順にするため）
            let sortedSelection = Array(Set(tempRangeSelected)).sorted {
                $0.section == $1.section ? $0.item < $1.item : $0.section < $1.section
            }
            
            // 全てのIndexPathが同じ行（section）にあるか
            let isSingleRow = tempRangeSelected.allSatisfy { $0.section == tempRangeSelected.first?.section }

            // 全てのIndexPathが同じ列（item）にあるか
            let isSingleCol = tempRangeSelected.allSatisfy { $0.item == tempRangeSelected.first?.item }

            if isSingleRow && isSingleCol {
                panGestureShow2()
                print("single cell selection")
                
            } else if isSingleRow || isSingleCol {
                print("one row direction selection")
                if idxInLocation != -1{
                    print("content",content[idxInLocation])
                    var titleLabel = "AutoFill"
                    var msgDate = "Fill the selected range with dates?"
                    var msgMore = "Advanced..."
                    var msgFunction = "    Fill range with functions?"
                    let locationstr = (NSLocale.preferredLanguages[0] as String?)!
                    if locationstr.contains("ja"){
                        msgDate = "選択範囲を日付順に埋めますか？"
                        msgMore = "その他"
                        msgFunction = "選択範囲に関数を入力しますか？"
                    }else if locationstr.contains("fr"){
                        msgDate = "Remplir la sélection avec des dates ?"
                        msgMore = "Plus..."
                        msgFunction = "Remplir avec les fonctions ?"
                    }else if locationstr.contains("zh"){
                        msgDate = "是否按日期顺序填充选定区域？"
                        msgMore = "更多选项"
                        msgFunction = "是否按顺序填充函数？"
                    }else if locationstr.contains("de"){
                        msgDate = "Bereich mit Datumswerten füllen?"
                        msgMore = "Optionen"
                        msgFunction = "Bereich mit Funktionen füllen?"
                    }else if locationstr.contains("es"){
                        msgDate = "¿Rellenar el rango con fechas?"
                        msgMore = "Opciones"
                        msgFunction = "¿Rellenar rango con funciones?"
                    }
                    
                    let inputText = content[idxInLocation]
                            //If the content was a date
                            if isValidDate(text: inputText) {
                                let alert = UIAlertController(
                                    title: titleLabel,
                                    message: msgDate,
                                    preferredStyle: .alert
                                )
                                
                                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                                    self.takeDailyBackup(msg: "before_seqDate_")
                                    if isSingleCol{
                                        self.fillDateInSelectedCellContent(direction: 0)
                                    }else{
                                        self.fillDateInSelectedCellContent(direction: 1)
                                    }
                                })
                                alert.addAction(UIAlertAction(title: msgMore, style: .default){ _ in
                                    self.panGestureShow2()
                                })
                                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel){ _ in
                                    self.selection_bool = false
                                    self.myCollectionView.reloadData()
                                })
                                self.present(alert, animated: true)
                            }else if(inputText.replacingOccurrences(of: " ", with: "").hasPrefix("=")){
                                let alert = UIAlertController(title: titleLabel,
                                                              message: msgFunction,
                                                            preferredStyle: .alert)
                                
                                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                                    self.takeDailyBackup(msg: "before_seqFunc_")
                                    if isSingleCol{
                                        self.fillFunctionInSelectedCellContent(direction: 0)
                                    }else{
                                        self.fillFunctionInSelectedCellContent(direction: 1)
                                    }
                                })
                                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel){ _ in
                                    self.selection_bool = false
                                    self.myCollectionView.reloadData()
                                })
                                alert.addAction(UIAlertAction(title: msgMore, style: .default){ _ in
                                    self.panGestureShow2()
                                })
                                self.present(alert, animated: true)
                            }
                            else{
                                //TODO improve UX
                                panGestureShow2()
                            }
                }else{
                    //TODO improve UX
                    panGestureShow2()
                }
               
            } else {
                //TODO improve UX
                panGestureShow2()
            }

           
            
            //myCollectionView.reloadData()
            break
        default:
            break
        }
    }
    
    func isValidDate(text: String) -> Bool {
        let pattern = "^\\d{4}/\\d{2}/\\d{2}$"
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    
    func panGestureShow2() {
        // FileFillViewController is form-filling mode: row/col insert-delete and
        // multi-cell copy/paste aren't supported here, so unlike ViewController's
        // panGestureShow2(), this never creates or shows RangeSelectionOpsView --
        // just clear any leftover selection state instead.
        if rsview != nil {
            rsview.removeFromSuperview()
        }
        tempRangeSelected = []
    }
    
    @objc func rowInsertOperation() {
        if isExcel {
            takeDailyBackup(msg: "before_rowInsert_")
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            
            let rowsToInsert = Set(tempRangeSelected.map { $0.section })
            let minRow = rowsToInsert.min() ?? 0
            let numberOfRowsToInsert = rowsToInsert.count
            
            //dealing with index inconsistancy by reversed
            for i in (0..<location.count).reversed() {
                let locComponents = location[i].split(separator: ",")
                guard locComponents.count == 2,
                      let col = Int(locComponents[0]),
                      let row = Int(locComponents[1]) else { continue }
                
                if row >= minRow {
                    let newRow = row + numberOfRowsToInsert

                    location[i] = "\(col),\(newRow)"
                    invalidateLocationIndexCache()

                    //"A7" -> "A8"
                    let excelCol = ExcelHelper().GetExcelColumnName(columnNumber: col)
                    locationInExcel[i] = "\(excelCol)\(newRow)"
                }
                
                if !isExcel{
                    print("saved")
                    saveAsLocalJson(filename: "csv_sheet1")
                }
                
                //excel
                changeaffected.removeAll()
            }
            
            content = content.filter { $0 != "" }
            locationInExcel = locationInExcel.filter { $0 != "" }
            print("newcontent(col,row)",content)
            print("newExcellocation(col,row)",locationInExcel)
            
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let rlt = serviceInstance.testRangeOperationsBox(fp: appd.imported_xlsx_file_path,content: content, locationInExcel:locationInExcel )
            
            if rlt == nil{
                print("Something went wrong")
                return
            }
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
            
            print("go to file view")
            tempRangeSelected = []
            
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
                //                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
                
            }
        }
    }
    
    
    @objc func rowDeleteOperation() {
        if isExcel {
            takeDailyBackup(msg: "before_rowDelete_")
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            
            let rowsToDelete = Set(tempRangeSelected.map { $0.section })
            let minRow = rowsToDelete.min() ?? 0
            let numberOfRowsToDelete = rowsToDelete.count
            
            //dealing with index inconsistancy by reversed
            for i in (0..<location.count).reversed() {
                let locComponents = location[i].split(separator: ",")
                guard locComponents.count == 2,
                      let col = Int(locComponents[0]),
                      let row = Int(locComponents[1]) else { continue }
                
                if rowsToDelete.contains(row) {
                    location[i] = ""
                    invalidateLocationIndexCache()
                    locationInExcel[i] = ""
                    content[i] = ""
                    tcolor[i] = ""
                    textsize[i] = ""
                    bgcolor[i] = ""
                } else if row > minRow {
                    //shift + 1
                    let newRow = row - numberOfRowsToDelete
                    location[i] = "\(col),\(newRow)"
                    invalidateLocationIndexCache()

                    //"A10" -> "A9")
                    let excelCol = ExcelHelper().GetExcelColumnName(columnNumber: col)
                    locationInExcel[i] = "\(excelCol)\(newRow)"
                }
                
                if !isExcel{
                    print("saved")
                    saveAsLocalJson(filename: "csv_sheet1")
                }
                
                //excel
                changeaffected.removeAll()
            }
            
            content = content.filter { $0 != "" }
            locationInExcel = locationInExcel.filter { $0 != "" }
            print("newcontent(col,row)",content)
            print("newExcellocation(col,row)",locationInExcel)
            
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let rlt = serviceInstance.testRangeOperationsBox(fp: appd.imported_xlsx_file_path,content: content, locationInExcel:locationInExcel )
            
            if rlt == nil{
                print("Something went wrong")
                return
            }
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
            
            print("go to file view")
            tempRangeSelected = []
            
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
                //                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
                
            }
        }
    }

    
    @objc func columnInsertOperation(){
        if isExcel {
            takeDailyBackup(msg: "before_colInsert_")
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let columnsToInsert = Set(tempRangeSelected.map { $0.item })
            let minCol = columnsToInsert.min() ?? 0
            let numberOfColsToInsert = columnsToInsert.count
            
            //use reversed to prevent causing index corruption
            for i in (0..<location.count).reversed() {
                let locComponents = location[i].split(separator: ",")
                guard locComponents.count == 2,
                      let col = Int(locComponents[0]),
                      let row = Int(locComponents[1]) else { continue }
                
                if col >= minCol {
                    let newCol = col + numberOfColsToInsert
                    location[i] = "\(newCol),\(row)"
                    invalidateLocationIndexCache()
                    let excelCol = ExcelHelper().GetExcelColumnName(columnNumber: newCol)
                    locationInExcel[i] = "\(excelCol)\(row)"
                }
                
                if !isExcel{
                    print("saved")
                    saveAsLocalJson(filename: "csv_sheet1")
                }
                
                //excel
                changeaffected.removeAll()
            }
            
            content = content.filter { $0 != "" }
            locationInExcel = locationInExcel.filter { $0 != "" }
            print("newcontent(col,row)",content)
            print("newExcellocation(col,row)",locationInExcel)
            
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let rlt = serviceInstance.testRangeOperationsBox(fp: appd.imported_xlsx_file_path,content: content, locationInExcel:locationInExcel )
            
            if rlt == nil{
                print("Something went wrong")
                return
            }
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
            
            print("go to file view")
            tempRangeSelected = []
            
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
                //                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
                
            }
        }
    }
    
    @objc func columnDeleteOperation() {
        if isExcel {
            takeDailyBackup(msg: "before_colDel_")
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let columnsToDelete = Set(tempRangeSelected.map { $0.item })
            let minCol = columnsToDelete.min() ?? 0
            let numberOfColsToDelete = columnsToDelete.count
            
            //use reversed to prevent causing index corruption
            for i in (0..<location.count).reversed() {
                let locComponents = location[i].split(separator: ",")
                guard locComponents.count == 2,
                      let col = Int(locComponents[0]),
                      let row = Int(locComponents[1]) else { continue }
                
                if columnsToDelete.contains(col) {
                    location[i] = ""
                    invalidateLocationIndexCache()
                    locationInExcel[i] = ""
                    content[i] = ""
                    tcolor[i] = ""
                    textsize[i] = ""
                    bgcolor[i] = ""
                } else if col > minCol {
                    let newCol = col - numberOfColsToDelete
                    location[i] = "\(newCol),\(row)"
                    invalidateLocationIndexCache()
                    let excelCol = ExcelHelper().GetExcelColumnName(columnNumber: newCol)
                    locationInExcel[i] = "\(excelCol)\(row)"//AB1,G12
                }
                
                if !isExcel{
                    print("saved")
                    saveAsLocalJson(filename: "csv_sheet1")
                }
                
                //excel
                changeaffected.removeAll()
            }
            
            content = content.filter { $0 != "" }
            locationInExcel = locationInExcel.filter { $0 != "" }
            print("newcontent(col,row)",content)
            print("newExcellocation(col,row)",locationInExcel)
            
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let rlt = serviceInstance.testRangeOperationsBox(fp: appd.imported_xlsx_file_path,content: content, locationInExcel:locationInExcel )
            
            if rlt == nil{
                print("Something went wrong")
                return
            }
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
            
            print("go to file view")
            tempRangeSelected = []
            
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
                //                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
                
            }
        }
        backRS2()
    }
    
    @objc func clearSelectedCellContent(){
        if isExcel {
            takeDailyBackup(msg: "before_cellDel_")
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            
            for (i,each) in tempRangeSelected.enumerated() {
                let column = each.item
                let row = each.section
                //(column,row) location
                let locIndex = location.firstIndex(of: String(column)+","+String(row))
                if locIndex == nil{
                    continue
                }
                if !isExcel{
                    print("saved")
                    saveAsLocalJson(filename: "csv_sheet1")
                }
                
                //excel
                changeaffected.removeAll()
                
                
                if location.count > locIndex!{
                    location[locIndex!] = ""
                    invalidateLocationIndexCache()
                    locationInExcel[locIndex!] = ""
                    content[locIndex!] = ""
                    tcolor[locIndex!] = ""
                    textsize[locIndex!] = ""
                    bgcolor[locIndex!] = ""

                }

                let k = f_location.firstIndex(of: String(column)+","+String(row))
                if k != nil && f_calculated.count > k!{
                    f_calculated[k!] = ""
                    f_location_alphabet[k!] = ""
                    f_location[k!] = ""
                    invalidateFLocationIndexCache()
                }
            }
            
            content = content.filter { $0 != "" }
            locationInExcel = locationInExcel.filter { $0 != "" }
            
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let rlt = serviceInstance.testRangeOperationsBox(fp: appd.imported_xlsx_file_path,content: content, locationInExcel:locationInExcel )
            
            if rlt == nil{
                print("Something went wrong")
                return
            }
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
            
            print("go to file view")
            tempRangeSelected = []
            
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
                //                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
                
            }
        }
    }

    @objc func copyPasteSelectedCellContent() {
        if isExcel && currentindex != nil {
            let ecol = ExcelHelper().GetExcelColumnName(columnNumber: currentindex.item)
            let alert = UIAlertController(
                title: "Copy & Paste Selected Cell Values",
                message: "Do you want to paste them starting from cell " + ecol + String(realRow(forDisplaySection: currentindex.section)) + "?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                self.takeDailyBackup(msg: "before_copyPaste_")
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
                appd.wsSheetIndex = sheetIdx!
                print("wsSheetIndex",appd.wsSheetIndex)


                // tempRangeSelected holds display sections (possibly filter-
                // compacted) -- translate to real rows before touching
                // content/location, which are keyed by real row.
                let realRangeSelected = self.tempRangeSelected.map {
                    IndexPath(item: $0.item, section: self.realRow(forDisplaySection: $0.section))
                }

                //find copy origin point(left top)
                let minCol = realRangeSelected.map { $0.item }.min() ?? 0
                let minRow = realRangeSelected.map { $0.section }.min() ?? 0

                //find paste origin point
                let destBaseCol = self.currentindex.item
                let destBaseRow = self.realRow(forDisplaySection: self.currentindex.section)

                var locationIndex: [String: Int] = [:]
                locationIndex.reserveCapacity(self.location.count)
                for (idx, loc) in self.location.enumerated() {
                    if locationIndex[loc] == nil {
                        locationIndex[loc] = idx
                    }
                }

                var copyBuffer: [(colOffset: Int, rowOffset: Int, value: String)] = []

                for each in realRangeSelected {
                    if let idx = locationIndex["\(each.item),\(each.section)"] {
                        copyBuffer.append((
                            colOffset: each.item - minCol,
                            rowOffset: each.section - minRow,
                            value: self.content[idx]
                        ))
                    }
                }

                //start copying
                for item in copyBuffer {
                    let destCol = destBaseCol + item.colOffset
                    let destRow = destBaseRow + item.rowOffset
                    let destLocStr = "\(destCol),\(destRow)"

                    if let existingIdx = locationIndex[destLocStr] {
                        self.content[existingIdx] = item.value
                    } else {
                        locationIndex[destLocStr] = self.location.count
                        self.location.append(destLocStr)
                        self.content.append(item.value)
                        self.textsize.append(String(self.selectingSize))
                        self.tcolor.append(self.selectingColor)
                        self.bgcolor.append(self.selectingBgColor)
                        let excelCol = ExcelHelper().GetExcelColumnName(columnNumber: destCol)
                        self.locationInExcel.append("\(excelCol)\(destRow)")
                    }
                }

                let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                let rlt = serviceInstance.testRangeOperationsBox(fp: appd.imported_xlsx_file_path,content: self.content, locationInExcel:self.locationInExcel )
                
                if rlt == nil{
                    print("Something went wrong")
                    return
                }
                
                //sheet cell get touched
                appd.collectionViewCellSizeChanged = 1
                appd.cswLocation.removeAll()
                appd.customSizedWidth.removeAll()
                appd.cshLocation.removeAll()
                appd.customSizedHeight.removeAll()
                
                
                self.f_calculated.removeAll()
                self.f_content.removeAll()
                self.content.removeAll()
                self.location.removeAll()
                self.f_location_alphabet.removeAll()
                
                //print("sheet changed",indexPath.item)
                self.stringboxText = ""
                
                print("go to file view")
                self.tempRangeSelected = []
                
                
                // Present the target view controller after LoadingFileController's view has appeared
                DispatchQueue.main.async {
                    //                self.present(targetViewController, animated: true, completion: nil)
                    self.loadExcelSheet(idx: appd.wsSheetIndex){
                        // Assuming `collectionView` is your UICollectionView instance
                        if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                            customLayout.resetCellAttrsDictionaryItemZindex()
                            customLayout.prepare()
                            customLayout.invalidateLayout() // Call the method on the instance
                            self.myCollectionView.reloadData()
                        } else {
                            print("CustomCollectionViewLayout is not set as the current layout")
                        }
                    }
                    
                }
                
            })
            alert.addAction(UIAlertAction(title: "No", style: .cancel){ _ in
            })
            self.present(alert, animated: true)
        }
        backRS2()
    }
    
    @objc func fillDateInSelectedCellContent(direction:Int ) {
        guard let firstIndexPath = tempRangeSelected.first,
              let firstIdx = location.firstIndex(of: "\(firstIndexPath.item),\(firstIndexPath.section)") else { return }
        
        let baseDateString = content[firstIdx] // "2026/03/01"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        
        guard let startDate = formatter.date(from: baseDateString) else { return }
        let calendar = Calendar.current

        // Sort selected range from top left
        let sortedSelection = tempRangeSelected.sorted {
            $0.section == $1.section ? $0.item < $1.item : $0.section < $1.section
        }

        var excelIndice = [String]()
        var generatedDates = [String]()

        for (i, each) in sortedSelection.enumerated() {
            if i == sortedSelection.count - 1 {
                print("This is the last item")
                continue
            }
            let column = each.item
            let row = each.section
            let posKey = "\(column),\(row)"
            
            if let nextDate = calendar.date(byAdding: .day, value: i, to: startDate) {
                let nextDateString = formatter.string(from: nextDate)
                generatedDates.append(nextDateString)
            }

            if let j = location.firstIndex(of: posKey) {
                // locationInExcel is never populated for CSV (initExcelLocation()
                // is skipped there), so indexing/removing from it here would
                // crash ("Index out of range") the moment location's real index
                // exceeds locationInExcel's stale/empty size -- exactly what
                // happened dragging a "=..." fill on a large CSV. excelIndice's
                // actual values are never read below either way (only its
                // count), so track presence with posKey instead for CSV.
                if !isCSV {
                    excelIndice.append(locationInExcel[j])
                    locationInExcel.remove(at: j)
                } else {
                    excelIndice.append(posKey)
                }

                location.remove(at: j)
                content.remove(at: j)
                tcolor.remove(at: j)
                textsize.remove(at: j)
                bgcolor.remove(at: j)
            }

            if let k = f_location.firstIndex(of: posKey) {
                f_calculated.remove(at: k)
                f_location_alphabet.remove(at: k)
                f_location.remove(at: k)
            }
        }

        if excelIndice.count > 0 {
            var sourceStr = generatedDates.joined(separator: ":")
            if sourceStr != "" {
                if direction == 0{
                    down_bool = true
                    sourceStr += "↓"
                    
                }else{
                    right_bool = true
                    sourceStr += "→"
                }
                virtual_input(source:sourceStr, cellId: getIndexlabel())//the red text on the left top
            }
            
        }

        if !isExcel {
            saveAsLocalJson(filename: "csv_sheet1")
        }

        if !isCSV {
            calculatormode_update_main()
        }
        myCollectionView.reloadData()
        backRS2()
    }

    @objc func fillFunctionInSelectedCellContent(direction: Int) {
        guard let firstIndexPath = tempRangeSelected.sorted(by: { $0.section == $1.section ? $0.item < $1.item : $0.section < $1.section }).first,
              let firstIdx = location.firstIndex(of: "\(firstIndexPath.item),\(firstIndexPath.section)") else { return }
        
        let baseFormula = content[firstIdx] //"=A3+1"
        let sortedSelection = tempRangeSelected.sorted { (a, b) -> Bool in
            if direction == 0 {
                return a.item == b.item ? a.section < b.section : a.item < b.item
            } else {
                return a.section == b.section ? a.item < b.item : a.section < b.section
            }
        }

        var generatedFormulas = [String]()

        for (i, each) in sortedSelection.enumerated() {
            if i == sortedSelection.count - 1 {
                print("This is the last item")
                continue
            }
            let posKey = "\(each.item),\(each.section)"

            let colOffset = each.item - firstIndexPath.item
            let rowOffset = each.section - firstIndexPath.section
            let newFormula = shiftFormula(baseFormula, colOffset: colOffset, rowOffset: rowOffset)
            generatedFormulas.append(newFormula)

            if let j = location.firstIndex(of: posKey) {
                // locationInExcel is never populated for CSV (initExcelLocation()
                // is skipped there) -- removing from it here crashed ("Index out
                // of range") the moment location's real index exceeded
                // locationInExcel's stale/empty size, e.g. dragging a "=..."
                // formula fill on a large CSV. The values collected here were
                // never read anywhere below (dead code, confirmed via grep), so
                // just drop this array entirely rather than guard a no-op.
                if !isCSV {
                    locationInExcel.remove(at: j)
                }

                location.remove(at: j)
                content.remove(at: j)
                tcolor.remove(at: j)
                textsize.remove(at: j)
                bgcolor.remove(at: j)
            }
            
            if let k = f_location.firstIndex(of: posKey) {
                f_calculated.remove(at: k)
                f_location_alphabet.remove(at: k)
                f_location.remove(at: k)
            }
        }


        for (i, eachFormula) in generatedFormulas.enumerated() {
            let targetIndexPath = sortedSelection[i]
        
            cursor = "\(targetIndexPath.item),\(targetIndexPath.section)"
            
            down_bool = false
            right_bool = false
            
            let colName = ExcelHelper().GetExcelColumnName(columnNumber: targetIndexPath.item)
            virtual_input(source: eachFormula, cellId: colName + String(targetIndexPath.section))
        }
            
            
        

        if !isExcel { saveAsLocalJson(filename: "csv_sheet1") }
        if !isCSV {
            calculatormode_update_main()
        }
        myCollectionView.reloadData()
        backRS2()
    }

    func shiftFormula(_ formula: String, colOffset: Int, rowOffset: Int) -> String {
        // セル番地（例: A1, B10, AA100）にマッチする正規表現
        let pattern = "([A-Z]+)([0-9]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return formula }
        
        let nsString = formula as NSString
        var offsetFormula = formula
        
        //reverse to prevent index corruption
        let matches = regex.matches(in: formula, options: [], range: NSRange(location: 0, length: nsString.length)).reversed()
        
        for match in matches {
            let colRange = match.range(at: 1)
            let rowRange = match.range(at: 2)
            
            let colStr = nsString.substring(with: colRange)
            let rowStr = nsString.substring(with: rowRange)
            
            if let rowInt = Int(rowStr) {
                let newRow = rowInt + rowOffset
                let colInt = excelColumnToIndex(colStr)
                let newColStr = indexToExcelColumn(colInt + colOffset)
                
                let newReference = "\(newColStr)\(newRow)"
                offsetFormula = (offsetFormula as NSString).replacingCharacters(in: match.range, with: newReference)
            }
        }
        return offsetFormula
    }

    func excelColumnToIndex(_ col: String) -> Int {
        var result = 0
        for char in col.uppercased().unicodeScalars {
            result = result * 26 + Int(char.value - 64)
        }
        return result
    }

    func indexToExcelColumn(_ index: Int) -> String {
        var n = index
        var result = ""
        while n > 0 {
            let remainder = (n - 1) % 26
            result = String(UnicodeScalar(65 + remainder)!) + result
            n = (n - 1) / 26
        }
        return result
    }

    
    // Function to increment the row of an Excel-style cell reference by a given volume
    func incrementRow(for cell: String, incrementVolume: Int) -> String {
        let parsedCol = ExcelHelper().alphabetOnlyString(text:cell)
        let rowNumber = ExcelHelper().numberOnlyString(text: cell)
        return parsedCol + String((Int(rowNumber) ?? 0)+incrementVolume)
    }

    // Function to increment the column of an Excel-style cell reference by a given volume
    func incrementColumn(for cell: String, incrementVolume: Int) -> String {
        let parsedCol = ExcelHelper().alphabetOnlyString(text:cell)
        let rowNumber = ExcelHelper().numberOnlyString(text: cell)
        // Convert the column letters to an integer, increment, and convert back to letters
        let incrementedColumn = incrementColumnLetters(parsedCol, incrementVolume: incrementVolume)
        return incrementedColumn + rowNumber
    }

    // Function to handle column incrementation by a given volume (e.g., "A" -> "B", "Z" -> "AA", etc.)
    func incrementColumnLetters(_ column: String, incrementVolume: Int) -> String {
        let parsedIntCol = ExcelHelper().columnToInt(ExcelHelper().alphabetOnlyString(text:column)) ?? 0
        let letters = GetExcelColumnName(columnNumber: parsedIntCol+incrementVolume)
        let number = ExcelHelper().numberOnlyString(text: column)
        return letters+number
    }

    // Function to increment an array of cell references by a given volume, either in rows or columns
    func incrementCells(in cells: [String], isIncrementRow: Bool, incrementVolume: Int) -> [String] {
        return cells.map { cell in
            if isIncrementRow {
                return incrementRow(for: cell, incrementVolume: incrementVolume)
            } else {
                return incrementColumn(for: cell, incrementVolume: incrementVolume)
            }
        }
    }


    
    //the end of viewdidload
//    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
//        bannerview.isHidden = false
//      print("bannerViewDidReceiveAd")
//    }
//
//    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
//        bannerview.isHidden = true
//      print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
//    }
    
    func getRootDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func initExcelLocation(){
        //updating locationInExcel(is content already loaded at here?)
        locationInExcel.removeAll()
        locationInExcel.reserveCapacity(location.count)
        // One split reused for both column/row instead of two separate
        // components(separatedBy:) calls per cell (each re-splits the whole
        // string) -- halves the splitting cost across 1.4M+ cells on a large sheet.
        for i in 0..<location.count{
            let parts = location[i].components(separatedBy: ",")
            if let colStr = parts.first, let colInt = Int(colStr), let rowStr = parts.last {
                let column = getExcelColumnName(columnNumber: colInt)
                locationInExcel.append(column + rowStr)
            }
        }
    }
    
    
    func initString() {
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        COLUMNSIZE = appd.DEFAULT_COLUMN_NUMBER
        ROWSIZE = appd.DEFAULT_ROW_NUMBER
        
        
        let appheight = UserDefaults.standard
        appheight.set(COLUMNSIZE, forKey: "NEWCsize")
        appheight.synchronize()
        
        let appheight2 = UserDefaults.standard
        appheight2.set(ROWSIZE, forKey: "NEWRsize")
        appheight2.synchronize()
        
    }
    
    
    
    @objc func restore()
    {
        //It's now restoreing.
        (content,location,COLUMNSIZE,ROWSIZE) = fontcolorClass.outValues()
        myCollectionView.reloadData()
        
    }
    
    
    
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        print("return")
        textField.resignFirstResponder()
        return true
    }
    
    
    //http://stackoverflow.com/questions/35782218/swift-how-to-make-mfmailcomposeviewcontroller-disappear
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    
    //http://stackoverflow.com/questions/32851720/how-to-remove-special-characters-from-string-in-swift-2
    func removeSpecialCharsFromString(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("1234567890-.")
        return String(text.filter {okayChars.contains($0) })
    }
    
    func removeSpecialCharsFromStringOprators(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("MaximnSuAvg%^×÷")
        return String(text.filter {okayChars.contains($0) })
    }
    
    
    
    //http://code-examples-ja.hateblo.jp/entry/2016/09/21/Swift3
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    
    
    @IBAction func show2(_ sender: AnyObject) {
        
        if customview2 != nil{
            
            customview2.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 285,height: 275))
            break
        case 1:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 285,height: 275))
            break
        case 2:
            customview2 = Customview2(frame: CGRect(x:5,y:50, width: 285,height: 275))
            break
        case 3:
            customview2 = Customview2(frame: CGRect(x:5,y:10, width: 285,height: 275))
            break
        case 4:
            customview2 = Customview2(frame: CGRect(x:5,y:200, width: 285,height: 275))
            break
        case 5:
            customview2 = Customview2(frame: CGRect(x:5,y:190, width: 285,height: 275))
            break
            
            
            
            
            
        default:
            customview2 = Customview2(frame: CGRect(x:5,y:150, width: 285,height: 275))
            break
            
        }
        
        
        
        
        customview2.layer.borderWidth = 1
        
        customview2.layer.cornerRadius = 8;
        
        
        customview2.layer.borderColor = UIColor.black.cgColor
        
        customview2.back.addTarget(self, action: #selector(FileFillViewController.back2(_:)), for: UIControl.Event.touchUpInside)
        
        customview2.localLoad.addTarget(self, action: #selector(FileFillViewController.icloudview(_:)), for: UIControl.Event.touchUpInside)
        
        customview2.reset.isHidden = true
        //customview2.reset.addTarget(self, action: #selector(FileFillViewController.resetSheet(_:)), for: UIControl.Event.touchUpInside)
        
      
        customview2.emailButton.addTarget(self, action: #selector(FileFillViewController.excelEmail), for: UIControl.Event.touchUpInside)
        
        customview2.savefile.addTarget(self, action: #selector(FileFillViewController.filesave), for: UIControl.Event.touchUpInside)
        
        customview2.localSave.addTarget(self, action: #selector(FileFillViewController.loadCreditview), for: UIControl.Event.touchUpInside)
        
        customview2.backups.addTarget(self, action: #selector(FileFillViewController.moveToBackupsView), for: UIControl.Event.touchUpInside)
        
        customview2.filefillmode.addTarget(self, action: #selector(FileFillViewController.moveToHome), for: UIControl.Event.touchUpInside)
        
  
        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
        
        self.view.addSubview(customview2)
    }
    
    @objc func moveToHome(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let targetViewController = storyboard.instantiateViewController(withIdentifier: "Home") as! HomeController

        // This screen was reached via HomeController.present(...), a real modal
        // presentation -- presenter and presented view controller hold each other
        // strongly. Swapping window.rootViewController directly (without dismissing
        // first) only drops the window's reference; the old HomeController and this
        // VC keep each other alive forever, leaking both plus everything retained
        // (e.g. CustomCollectionViewLayout's full cellAttrsDictionary). dismiss()
        // as fire-and-forget cleanup to break that pair -- deliberately NOT nesting
        // the root swap inside its completion, since when this VC was instead
        // reached via another moveToX root swap (no presentation involved) there is
        // nothing to dismiss and the completion handler firing in that case isn't
        // something to depend on; the swap below always runs regardless.
        self.dismiss(animated: false, completion: nil)
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            window.rootViewController = targetViewController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }

    }

    @objc func moveToPlayground(){
        self.customview2.removeFromSuperview()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let targetViewController = storyboard.instantiateViewController(withIdentifier: "StartLine2") as! PlaygroundViewController

        // See moveToHome() above for why dismiss() runs as fire-and-forget cleanup
        // rather than gating the root swap on its completion firing.
        self.dismiss(animated: false, completion: nil)
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            window.rootViewController = targetViewController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }

    }
    
    //create excel todo
    @objc func createxlsxSheet(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        excelAddSheet()
        if customview2 != nil{
            customview2.removeFromSuperview()
        }
    }
    
    @objc func deletexlsxSheet(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        excelDeleteSheet()
        if customview2 != nil{
            customview2.removeFromSuperview()
        }
    }
    
    @objc func moveToBackupsView(){
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "Backups" ) as! BackupTableViewController
        targetViewController.isFileFillMode = true
        targetViewController.modalPresentationStyle = .fullScreen
        targetViewController.onRestoreComplete = { [weak self] in
            self?.reloadAfterRestore()
        }
        present(targetViewController, animated: true, completion: nil)
        if customview2 != nil{
            customview2.removeFromSuperview()
        }
    }

    // Called via BackupTableViewController's onRestoreComplete after a Restore
    // action updates appd.imported_xlsx_file_path (xlsx) or clears it + writes
    // the csv_sheet1 JSON sidecar (csv) and dismisses back to this same,
    // already-presented instance -- reloads the newly-restored file in place
    // instead of BackupTableViewController constructing an entirely new
    // FileFillViewController and swapping window.rootViewController, which
    // needed both the old (already fully loaded) and new instances resident
    // in memory at once and was confirmed to cause an OOM crash on the
    // 100k-row test file. Mirrors the reset-then-loadExcelSheet pattern
    // already used for an ordinary sheet-tab switch (see the tab-tap handler
    // above), just for a different file's worth of data instead of a
    // different sheet within the same file -- including the pendingXlsxChanges
    // clear that a same-file sheet switch deliberately does NOT do (see
    // reapplyPendingXlsxChanges), since a genuinely different file has no
    // relation to whatever was still unflushed from the old one.
    func reloadAfterRestore() {
        let appd: AppDelegate = UIApplication.shared.delegate as! AppDelegate

        isExcel = !appd.imported_xlsx_file_path.isEmpty
        isCSV = !isExcel
        pendingXlsxChanges.clear()
        updateUnsavedDataReminderVisibility()
        columnFilters.removeAll()
        filteredOutRows.removeAll()
        appd.rowFilterActive = false
        appd.visibleRows = []

        appd.collectionViewCellSizeChanged = 1
        appd.cswLocation.removeAll()
        appd.customSizedWidth.removeAll()
        appd.cshLocation.removeAll()
        appd.customSizedHeight.removeAll()

        f_calculated.removeAll()
        f_content.removeAll()
        content.removeAll()
        location.removeAll()
        f_location_alphabet.removeAll()
        stringboxText = ""

        // isExcelSheetData assigns these straight from a freshly-decoded
        // sheet1Json (e.g. "textsize = sheet1Json.fontsize") -- the decode
        // itself builds the whole new array (up to ~1.4M entries) before that
        // assignment runs. On a brand-new VC instance these start out empty,
        // so the old restore path (which always built a fresh VC) never paid
        // for both copies at once. Now that this same instance is reused,
        // failing to clear these first meant the OLD file's full-size arrays
        // stayed resident right through the NEW file's decode -- doubling
        // peak memory for every one of these arrays simultaneously, which is
        // exactly the kind of spike that would surge/crash on a 100k-row file.
        cellStyleId.removeAll()
        textsize.removeAll()
        bgcolor.removeAll()
        tcolor.removeAll()
        f_location.removeAll()
        // Appended to unconditionally on every loadExcelSheet call (never
        // cleared anywhere), so it grows by COLUMNSIZE entries on every
        // restore/tab-switch. Small per-call, but there's no reason to keep
        // the previous file's column-letter cache around either.
        columnNames.removeAll()

        // Restoring a different file entirely -- always start at sheet 1
        // rather than whatever sheet the previous file happened to have
        // selected, which might not even exist in the new workbook.
        appd.wsSheetIndex = 1

        loadExcelSheet(idx: appd.wsSheetIndex) { [weak self] in
            guard let self = self else { return }
            if let matchIndex = appd.sheetNameIds.firstIndex(of: String(appd.wsSheetIndex)) {
                self.currentFileNameCollectionViewIdx = IndexPath(item: matchIndex, section: 0)
            }
            self.FileCollectionView.reloadData()
            self.myCollectionView.reloadData()
        }
    }
    
    @objc func filterEmptyContent(){
        var filterContent = [String]()
        var filterLocation = [String]()
        var filterFontSize = [String]()
        var filterFontColor = [String]()
        var filterBgColor = [String]()
        // cellStyleId is loaded from the saved sheet JSON in the same order/length as
        // location/content (see ExcelHelper.readExcel2), but only when a fresh import
        // populated it -- guard against a shorter/absent array from an older save.
        let hasStyleId = cellStyleId.count == content.count
        var filterStyleId = [String]()
        for i in 0..<content.count {
            let check = content[i].replacingOccurrences(of: " ", with: "")
            if check.count != 0{
                filterContent.append(content[i])
                filterLocation.append(location[i])

                filterFontSize.append(textsize[i])



                filterFontColor.append(tcolor[i])
                filterBgColor.append(bgcolor[i])
                if hasStyleId {
                    filterStyleId.append(cellStyleId[i])
                }
            }

        }

        content = filterContent
        location = filterLocation
        textsize = filterFontSize
        tcolor = filterFontColor
        bgcolor = filterBgColor
        if hasStyleId {
            cellStyleId = filterStyleId
        }
    }
    @objc func saveAsLocalJson(filename:String) {
        // See the matching comment in initSheetData() -- content/location are
        // already guaranteed clean for CSV mode by construction, so this full
        // re-scan is redundant there. Confirmed via instrumentation: this and
        // initSheetData's copy were each independently costing ~3.5s at 1.4M
        // cells, back to back, on every single edit.
        let __saveJsonFilterStart = CFAbsoluteTimeGetCurrent()
        if !isCSV {
            filterEmptyContent()
        }
        perfLog(String(format: "PERF saveAsLocalJson.filterEmptyContent: %.3fs isCSV=%@ filename=%@ content=%d", CFAbsoluteTimeGetCurrent() - __saveJsonFilterStart, isCSV ? "true" : "false", filename, content.count))

        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let today: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH-mm-ss"
        let date = dateFormatter.string(from: today)
        
        
        // Values captured into the dict here (Swift arrays are copy-on-write) --
        // safe to hand off to a background queue even if content/location mutate
        // again on the main thread before the write below actually runs.
        let dict : [String:Any] = ["filename": filename,
                                   "date": date,
                                   "content": content,
                                   "location": location,
                                   "fontsize": textsize,
                                   "fontcolor": tcolor,
                                   "bgcolor": bgcolor,
                                   "rowsize": ROWSIZE,
                                   "columnsize": COLUMNSIZE,
                                   "customcellWidth":appDelegate.customSizedWidth,
                                   "customcellHeight": appDelegate.customSizedHeight,
                                   "ccwLocation": appDelegate.cswLocation,
                                   "cchLocation": appDelegate.cshLocation,
                                   "formulaResult":f_calculated,
                                   "inputOrder":input_order]

        localJsonSaveQueue.async {
            ReadWriteJSON().saveJsonFile(source: dict, title: filename)
        }
        
        
        
    }
    
    @objc func deleteLocalJson(filename:String) {
        
        let test = ReadWriteJSON()
        test.deleteJsonFile(title: filename)
    }
    
    @objc func sliderValueChanged(_ sender:Any){
        let rounded = Int(floor(Fview.sizeslider.value))
        Fview.sizelabel.text = String(rounded)
        
        let IP :String = cursor
        
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            if location.index(of: IP) == nil{
                content.append("")
                location.append(IP)
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
            }
            break
            
        default:
            if location.index(of: IP) == nil{
                content.append("")
                location.append(IP)
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
            }
            break
        }
        
        
        
        let i = location.index(of: IP)
        textsize[i!] = String(rounded)
        selectingSize = rounded
        
        myCollectionView.reloadData()
        
        saveuserF()
        saveuserD()
        
    }
    
    private func configureCellSizeSlider() {
        cellSizeSlicer.minimumValue = 15
        cellSizeSlicer.maximumValue = 220
        cellSizeSlicer.isEnabled = true

        if UserDefaults.standard.object(forKey: "GLOBAL_CELL_WIDTH") != nil {
            cellSizeSlicer.value = UserDefaults.standard.float(forKey: "GLOBAL_CELL_WIDTH")
        } else if let layout = myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
            cellSizeSlicer.value = Float(layout.CELL_WIDTH)
        } else {
            cellSizeSlicer.value = 70
        }
    }

    private func applyGlobalCellSizeSliderValue(_ value: Float) {
        let width = max(Double(cellSizeSlicer.minimumValue), Double(value))
        let height = max(10.0, width / 4.0)
        let indexSize = max(10.0, height)
        let appd: AppDelegate = UIApplication.shared.delegate as! AppDelegate

        UserDefaults.standard.set(width, forKey: "GLOBAL_CELL_WIDTH")
        UserDefaults.standard.set(height, forKey: "GLOBAL_CELL_HEIGHT")
        UserDefaults.standard.set(indexSize, forKey: "GLOBAL_INDEX_SIZE")

        appd.cswLocation.removeAll()
        appd.customSizedWidth.removeAll()
        appd.cshLocation.removeAll()
        appd.customSizedHeight.removeAll()
        UserDefaults.standard.set(appd.customSizedWidth, forKey: "NEW_CELL_WIDTH")
        UserDefaults.standard.set(appd.cswLocation, forKey: "NEW_CELL_WIDTH_LOCATION")
        UserDefaults.standard.set(appd.customSizedHeight, forKey: "NEW_CELL_HEIGHT")
        UserDefaults.standard.set(appd.cshLocation, forKey: "NEW_CELL_HEIGHT_LOCATION")
        UserDefaults.standard.synchronize()

        appd.collectionViewCellSizeChanged = 1

        DispatchQueue.main.async {
//                self.present(targetViewController, animated: true, completion: nil)
            self.loadExcelSheet(idx: appd.wsSheetIndex){
                // Assuming `collectionView` is your UICollectionView instance
                if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                    customLayout.resetCellAttrsDictionaryItemZindex()
                    customLayout.prepare()
                    customLayout.invalidateLayout() // Call the method on the instance
                    self.myCollectionView.reloadData()
                } else {
                    print("CustomCollectionViewLayout is not set as the current layout")
                }
            }
            
        }
    }

    @objc func cellSizeSliderTouchDown(_ slider: UISlider) {
        hiddenTextField.resignFirstResponder()
        myCollectionView.isUserInteractionEnabled = false
    }

    // .valueChanged fires many times per drag (every point of finger movement).
    // applyGlobalCellSizeSliderValue does a full collectionViewCellSizeChanged=1 +
    // invalidateLayout() + reloadData() -- a full rebuild of the whole (possibly
    // 200k+ cell) grid. Calling that on every tick was firing overlapping reloads
    // faster than UICollectionView could finish the previous one, which is what
    // was producing the corrupted-looking grid. Intentionally a no-op here now --
    // the grid only actually resizes once, in cellSizeSliderReleased below.
    @objc func cellSizeSliderChanged(_ slider: UISlider) {
    }

    @objc func cellSizeSliderReleased(_ slider: UISlider) {
        myCollectionView.isUserInteractionEnabled = true
        applyGlobalCellSizeSliderValue(slider.value)
        saveAsLocalJson(filename: "csv_sheet1")
    }

//    func numberviewopen() {
//
//        if numberview != nil {
//            numberview.removeFromSuperview()
//        }
//        
//        
//        //if UIDevice.current.orientation.isLandscape{
//        var width = "width"
//        var height = "height"
//        let locationstr = (NSLocale.preferredLanguages[0] as String?)!
//        
//        if locationstr.contains( "ja")
//        {
//            width = "横幅"
//            height = "縦幅"
//        }else if locationstr.contains( "fr")
//        {
//            width = "largeur"
//            height = "la taille"
//        }else if locationstr.contains( "zh"){
//            width = "宽度"
//            height = "高度"
//        }else if locationstr.contains( "de")
//        {
//            width = "Breite"
//            height = "Höhe"
//        }else if locationstr.contains( "it")
//        {
//            
//            width = "altezza"
//            height = "larghezza"
//        }else if locationstr.contains( "ru")
//        {
//            width = "ширина"
//            height = "высота"
//        }
//        
//        numberview = numberkey(frame: CGRect(x:40,y:100, width: 210,height: 145))
//        
//        numberview.layer.borderWidth = 1
//        
//        numberview.layer.cornerRadius = 8;
//        
//        numberview.layer.borderColor = UIColor.black.cgColor
//        
//        numberview.inputfield.delegate = self
//        
//        //
//        numberview.back.addTarget(self, action: #selector(FileFillViewController.backactionnum(_:)), for: UIControl.Event.touchUpInside)
//        
//        numberview.plusOne.addTarget(self, action: #selector(FileFillViewController.plusAction(_:)), for: UIControl.Event.touchUpInside)
//        
//        
//        numberview.minusOne.addTarget(self, action: #selector(FileFillViewController.minusAction(_:)), for: UIControl.Event.touchUpInside)
//        
//        numberview.width_height_selector.setTitle(width, forSegmentAt: 0)
//        numberview.width_height_selector.setTitle(height, forSegmentAt: 1)
//        
//        
//        self.view.addSubview(numberview)
//    }
//    
//    
    
    
    //*********************//
    
    
    @objc func formatbackaction(_ sender:UIButton)
    {
        
        
        
        //
        
        //if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex {
            saveAsLocalJson(filename: "csv_sheet1")
        //}
        
        Fview.removeFromSuperview()
    }
    
    @objc func c1(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=water"
            selectingColor="water"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=water"
            selectingBgColor="water"
        }
        
        fonteditmode()
        
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c2(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=brown"
            selectingColor="brown"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=brown"
            selectingBgColor="brown"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c5(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=white"
            selectingColor="white"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=white"
            selectingBgColor="white"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c6(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=blue"
            selectingColor="blue"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=blue"
            selectingBgColor="blue"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c7(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=magenta"
            selectingColor="magenta"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=magenta"
            selectingBgColor="magenta"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c8(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=red"
            selectingColor="red"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=red"
            selectingBgColor="red"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c9(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=orange"
            selectingColor="orange"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=orange"
            selectingBgColor="orange"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c10(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=black"
            selectingColor="black"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=black"
            selectingBgColor="black"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c11(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=green"
            selectingColor="green"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=green"
            selectingBgColor="green"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c12(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=gray"
            selectingColor="gray"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=gray"
            selectingBgColor="gray"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c13(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=purple"
            selectingColor="purple"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=purple"
            selectingBgColor="purple"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c14(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=yellow"
            selectingColor="yellow"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=yellow"
            selectingBgColor="yellow"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    @objc func c15(_ sender:UIButton)
    {
        if Fview.fontsegment.selectedSegmentIndex == 0{
            FONTEDIT = "color=lightGray"
            selectingColor="lightGray"
        }else if Fview.fontsegment.selectedSegmentIndex == 1{
            FONTEDIT = "bg=lightGray"
            selectingBgColor="lightGray"
        }
        
        fonteditmode()
        
        //Fview.removeFromSuperview()
        
        
    }
    
    
    
    //**********************BUTTONS*************************************************//
    
//    @objc func backactionnum(_ sender:UIButton)
//    {
//        let indexItem = Int(currentindex.item)
//        let indexSection = Int(currentindex.section)
//        let temp_value = numberview.inputfield.text!
//        let value = temp_value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        appd.collectionViewCellSizeChanged = 1
//        
//        if Double(value) != nil{
//            
//            
//            if numberview.width_height_selector.selectedSegmentIndex == 0{
//                
//                if Double(value)! < 20.0{
//                    
//                }else{
//                    if appd.cswLocation_temp.contains(indexItem){
//                        let idx = appd.cswLocation_temp.firstIndex(of: indexItem)
//                        appd.customSizedWidth_temp[idx!] = Double(value)!
//                    }
//                    appd.customSizedWidth_temp.append(Double(value)!)
//                    appd.cswLocation_temp.append(indexItem)
//                    
//                }
//                
//            }else if numberview.width_height_selector.selectedSegmentIndex == 1{
//                
//                
//                if Double(value)! < 20.0{
//                    
//                }else {
//                    if appd.cshLocation_temp.contains(indexSection){
//                        let idx = appd.cshLocation_temp.firstIndex(of: indexSection)
//                        appd.customSizedHeight_temp[idx!] = Double(value)!
//                    }
//                    appd.customSizedHeight_temp.append(Double(value)!)
//                    appd.cshLocation_temp.append(indexSection)
//                                    
//                    
//                }
//                
//                
//                
//                
//            }
//            
//        }
//        
//        
//        
//        numberview.removeFromSuperview()
//        
//        
//        print("go to file view")
//        //print("selectedSheet",Int(appd.sheetNameIds[selectedSheet]))
//        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "LoadingFileController" ) as! LoadingFileController //Landscape
//        targetViewController.isFromFF = true
//        if isExcel{
//            targetViewController.idx = Int(appd.sheetNameIds[selectedSheet])
//        }
//        targetViewController.modalPresentationStyle = .fullScreen
//        // Present the target view controller after LoadingFileController's view has appeared
//        DispatchQueue.main.async {
//            self.present(targetViewController, animated: true, completion: nil)
//        }
//
//    }
//    
    
    
    @objc func plusAction(_ sender:UIButton)
    {
        let indexItem = Int(currentindex.item)
        let indexSection = Int(currentindex.section)
        var plus = 0
        let horrible = UserDefaults.standard
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if indexSection == 0{
            
            (location,content) = fontcolorClass.horribleMethod4Col(tempArray: location,tempArrayContent: content, colInt: indexItem)
            
            
            plus = COLUMNSIZE+1
            
            horrible.set(plus, forKey: "NEWCsize")
            horrible.synchronize()
            
            
            
        }else if indexItem == 0{
            
            (location,content) = fontcolorClass.horribleMethod4Row(tempArray: location,tempArrayContent: content, rowInt: indexSection)
            
            
            plus = ROWSIZE+1
            
            
            horrible.set(plus, forKey: "NEWRsize")
            horrible.synchronize()
            
            
        }
        
        
        
        
        
        horrible.set(location, forKey: "NEWTMLOCATION")
        horrible.synchronize()
        
        
        horrible.set(content, forKey: "NEWTMCONTENT")
        horrible.synchronize()
        
//        if selectedSheet >= 0{
        //if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex{
            saveAsLocalJson(filename: "csv_sheet1")
        //}
        
        
        DispatchQueue.main.async() {
            appd.collectionViewCellSizeChanged = 1
            self.myCollectionView.collectionViewLayout.invalidateLayout()
            self.myCollectionView.reloadData()
        }
        
        
        
    }
    
    @objc func minusAction(_ sender:UIButton)
    {
        let indexItem = Int(currentindex.item)
        let indexSection = Int(currentindex.section)
        var minus = 0
        let horrible = UserDefaults.standard
        
        if indexSection == 0{
            
            (location,content) = fontcolorClass.horribleMethod4ColMinus(tempArray: location,tempArrayContent:content , colInt: indexItem)
            
            
            minus = COLUMNSIZE-1
            horrible.set(minus, forKey: "NEWCsize")
            horrible.synchronize()
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.cswLocation.contains(indexItem){
                let idx = appd.cswLocation.index(of: indexItem)
                appd.cswLocation.remove(at: idx!)
                appd.customSizedWidth.remove(at: idx!)
            }
            
            //
            
            let r2 = UserDefaults.standard
            r2.set(appd.customSizedWidth, forKey: "NEW_CELL_WIDTH")
            r2.synchronize()
            
            let r3 = UserDefaults.standard
            r3.set(appd.cswLocation, forKey: "NEW_CELL_WIDTH_LOCATION")
            r3.synchronize()
            
            
            
            
        }else if indexItem == 0{
            
            (location,content) = fontcolorClass.horribleMethod4RowMinus(tempArray: location,tempArrayContent: content, rowInt: indexSection)
            
            
            minus = ROWSIZE-1
            
            horrible.set(minus, forKey: "NEWRsize")
            horrible.synchronize()
            
            
            
            let appd:AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.cshLocation.contains(indexSection){
                let idx = appd.cshLocation.index(of: indexSection)
                appd.cshLocation.remove(at: idx!)
                appd.customSizedHeight.remove(at: idx!)
            }
            
            //
            let r2 = UserDefaults.standard
            r2.set(appd.customSizedHeight, forKey: "NEW_CELL_HEIGHT")
            r2.synchronize()
            
            let r3 = UserDefaults.standard
            r3.set(appd.cshLocation, forKey: "NEW_CELL_HEIGHT_LOCATION")
            r3.synchronize()
            
            
            
        }
        
        
        
        horrible.set(location, forKey: "NEWTMLOCATION")
        horrible.synchronize()
        
        
        horrible.set(content, forKey: "NEWTMCONTENT")
        horrible.synchronize()
        
        
//        if selectedSheet >= 0{
        //if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex{
            saveAsLocalJson(filename: "csv_sheet1")
        //}
        
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        DispatchQueue.main.async() {
            appd.collectionViewCellSizeChanged = 1
            self.myCollectionView.collectionViewLayout.invalidateLayout()
            self.myCollectionView.reloadData()
        }
        
        
    }
    
    @objc func autoComplete(src:String)->String{
        var dotdot = src.replacingOccurrences(of: "↓", with: "…").replacingOccurrences(of: "→", with: "…").replacingOccurrences(of: "...", with: "…")
        
        
        let ary = dotdot.components(separatedBy: "…")
        if ary.count > 1{
            if ary.count == 3{
                //1.0...10↓-0.5 case
                if Double(ary[0]) != nil && Int(ary[1]) != nil && Double(ary[2]) != nil{
                    if (Double(ary[0]) != nil) && Int(ary[1])! > 0{
                        var product = ""
                        var cnt = Double(ary[0])!
                        for i in 0 ..< Int(ary[1])!{
                            product = product + String(cnt) + ":"
                            cnt += Double(ary[2])!
                        }
                        
                        if down_bool == true {
                            product = product + "↓"
                        }else if right_bool == true {
                            product = product + "→"
                        }else{
                            product = product + "↓"
                        }
                        return product
                    }else{
                        return ""
                    }
                }
                //1000...10↓ case
                if Int(ary[0]) != nil && Int(ary[1]) != nil{
                    if (Int(ary[0]) != nil) && Int(ary[1])! > 0{
                        var product = ""
                        var cnt = Int(ary[0])!
                        for i in 0 ..< Int(ary[1])!{
                            product = product + String(cnt) + ":"
                            cnt += 1
                        }
                        
                        if down_bool == true {
                            product = product + "↓"
                        }else if right_bool == true {
                            product = product + "→"
                        }else{
                            product = product + "↓"
                        }
                        return product
                    }else{
                        return ""
                    }
                }
                
                //just string
                if Double(ary[0]) == nil && Int(ary[1]) != nil{
                    if (Double(ary[0]) == nil) && Int(ary[1])! > 0{
                        var product = ""
                        for i in 0 ..< Int(ary[1])!{
                            product = product + ary[0] + ":"
                        }
                        
                        if down_bool == true {
                            product = product + "↓"
                        }else if right_bool == true {
                            product = product + "→"
                        }else{
                            product = product + "↓"
                        }
                        return product
                    }else{
                        return ""
                    }
                }
                    
                
                return ""
                
            }
        }else{
            return ""
        }
        return ""
    }
    
    //copy
    @objc func terminate(){
        if pastemode == false && getRefmode == false {
            datainputview.stringbox.resignFirstResponder()
            for subview in self.view.subviews.filter({ $0 is Datainputview }){
                subview.removeFromSuperview()
            }
            datainputview = nil
        }
    }
    
    @objc func closeHview(){
        if Hintview != nil{
            Hintview.removeFromSuperview()
        }
    }

    // MARK: - Row filter (Datafilter dialog, opened by tapping a column header)

    func openDatafilter(forColumn column: Int) {
        currentFilterColumn = column

        if datafilter == nil {
            datafilter = Datafilter(frame: CGRect(x: 15, y: 50, width: 250, height: 170))
            datafilter.closebutton.addTarget(self, action: #selector(closeDatafilter), for: .touchUpInside)
            datafilter.applybutton.addTarget(self, action: #selector(applyDatafilterTapped), for: .touchUpInside)
            datafilter.deselectbutton.addTarget(self, action: #selector(deselectDatafilterTapped), for: .touchUpInside)
        }

        // Pre-populate with whatever condition is already active on this
        // column, so reopening the dialog shows the current filter instead
        // of always starting blank.
        datafilter.conditionfield.text = columnFilters[column]?.displayString()

        if datafilter.superview == nil {
            self.view.addSubview(datafilter)
        }
    }

    @objc func closeDatafilter() {
        if datafilter != nil {
            datafilter.removeFromSuperview()
        }
    }

    @objc func applyDatafilterTapped() {
        guard currentFilterColumn >= 0 else { return }

        if let condition = ColumnFilterCondition.parse(datafilter.conditionfield.text ?? "") {
            columnFilters[currentFilterColumn] = condition
        } else {
            columnFilters.removeValue(forKey: currentFilterColumn)
        }

        closeDatafilter()
        applyRowFilters()
    }

    @objc func deselectDatafilterTapped() {
        guard currentFilterColumn >= 0 else { return }
        columnFilters.removeValue(forKey: currentFilterColumn)
        closeDatafilter()
        applyRowFilters()
    }

    // Computes filteredOutRows/visibleRows once -- "before rendering cells" --
    // rather than re-evaluating every column filter per cell during scroll.
    // colA AND colB AND ... across columns; within one column, whichever of
    // the four fields were set are ANDed together (see
    // ColumnFilterCondition.matches). Uses locationIndex(for:)'s existing
    // O(1) (col,row) lookup cache -- no need for a separate per-column array,
    // content/location just aren't sorted by row at all.
    //
    // Non-matching rows are removed from the *display* coordinate space only
    // (visibleRows), never from content/location -- those keep their real,
    // absolute row numbers so formulas (which store row refs as literal
    // text, e.g. "=O2*2") and persisted xlsx data are never rewritten. A
    // prior attempt collapsed row height to 0 in place instead and crashed
    // (see memory feedback-zero-height-collapse-reverted); this compacts via
    // an explicit display->real mapping (appd.visibleRows,
    // realRow(forDisplaySection:)) consumed by numberOfSections/prepare()/
    // cellForItemAt instead.
    func applyRowFilters() {
        // The row scan below is O(ROWSIZE * columnFilters.count) with zero
        // feedback otherwise -- on a large sheet that's a real, multi-second
        // freeze. showLoading()/hideLoading() don't make it faster (same
        // rationale as HomeController's mode-button overlay); the
        // DispatchQueue.main.async hop just gives the spinner one runloop
        // turn to actually paint before the synchronous work below blocks
        // the main thread.
        showLoading()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.filteredOutRows.removeAll()

            if !self.columnFilters.isEmpty {
                for row in 1..<self.ROWSIZE {
                    var rowPasses = true
                    for (col, condition) in self.columnFilters {
                        let key = "\(col),\(row)"
                        guard let i = self.locationIndex(for: key) else {
                            rowPasses = false
                            break
                        }
                        // Formula cells store the literal formula text in
                        // content[i] (e.g. "=A1+B1") -- filter against the
                        // calculated result instead, same lookup
                        // cellForItemAt uses to decide what to display.
                        let valueToCheck: String
                        if let fIdx = self.fLocationIndex(for: key), fIdx < self.f_calculated.count {
                            valueToCheck = self.f_calculated[fIdx]
                        } else {
                            valueToCheck = self.content[i]
                        }
                        guard condition.matches(valueToCheck) else {
                            rowPasses = false
                            break
                        }
                    }
                    if !rowPasses {
                        self.filteredOutRows.insert(row)
                    }
                }
            }

            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.rowFilterActive = !self.columnFilters.isEmpty
            if appd.rowFilterActive {
                appd.visibleRows = (1..<self.ROWSIZE).filter { !self.filteredOutRows.contains($0) }
            } else {
                appd.visibleRows = []
            }

            // The grid just got smaller/reordered under the cursor -- if
            // currentindex no longer maps to a valid display row, clamp it back
            // to a safe position rather than letting every downstream frame/data
            // lookup keyed off currentindex run out of bounds.
            if let ci = self.currentindex, ci.section > 0 {
                let stillValid = appd.rowFilterActive
                    ? ci.section - 1 < appd.visibleRows.count
                    : true
                if !stillValid {
                    self.currentindex = appd.visibleRows.isEmpty ? nil : IndexPath(item: 1, section: 1)
                }
            }

            // The layout only rebuilds its row-count/each_height/yPOS arrays
            // (rather than taking the cheap "just refresh headers" path) when
            // dataSourceDidUpdate is true, which collectionViewCellSizeChanged
            // triggers -- see CustomCollectionViewLayout.prepare(). Without
            // this, reloadData() alone would leave the grid laid out at its
            // pre-filter row count.
            appd.collectionViewCellSizeChanged = 1
            self.myCollectionView.collectionViewLayout.invalidateLayout()
            self.myCollectionView.reloadData()

            self.hideLoading()
        }
    }

    // Single translation point between display coordinates (what
    // indexPath.section / currentindex.section are, once a filter has
    // compacted the grid) and real, absolute spreadsheet row numbers (what
    // content/location/formulas/persisted xlsx data are keyed by). Header
    // row (section == 0) and the no-filter case both fall through unchanged,
    // so call sites never need their own "if filtered" branch.
    func realRow(forDisplaySection section: Int) -> Int {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        guard appd.rowFilterActive, section > 0, section - 1 < appd.visibleRows.count else { return section }
        return appd.visibleRows[section - 1]
    }



    func noInternet(sheetIdx:Int){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let sheet1Json = ReadWriteJSON()
        let temp = sheet1Json.titleJsonFile()
        old_localFileNames = temp.reversed()
        
        if old_localFileNames.count > 0{
            sheet1Json.readJsonFIle(title: old_localFileNames[sheetIdx])
            content = sheet1Json.content
            location = sheet1Json.location
            textsize = sheet1Json.fontsize
            bgcolor = sheet1Json.bgcolor
            tcolor = sheet1Json.fontcolor
            COLUMNSIZE = sheet1Json.columnsize
            ROWSIZE = sheet1Json.rowsize
            appd.customSizedWidth = sheet1Json.customcellWidth
            appd.customSizedHeight = sheet1Json.customcellHeight
            appd.cswLocation = sheet1Json.ccwLocation
            appd.cshLocation = sheet1Json.cchLocation
            
        }
        
        //EXCEL FORMULA TRANSFORMATION STARTS
        //PI(),EXP(1)
        content = excel_fomula_transformation(src:content)
        
        //Taking out Empty Cells
        filterEmptyContent()
        
        //SOME THING WENT WRONG RESET PROCESS STARTS
        if location.count != content.count {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            location.removeAll()
            content.removeAll()
            
            bgcolor.removeAll()
            cursor = String()
            tcolor.removeAll()
            textsize.removeAll()
            
            initString()
        }
        
        if location.count != bgcolor.count || location.count != tcolor.count || location.count != textsize.count{
            bgcolor.removeAll()
            textsize.removeAll()
            tcolor.removeAll()
            
            
            
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                for _ in 0..<location.count{
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                }
                break
                
            default:
                for _ in 0..<location.count{
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                }
                break
            }
        }
        
        //FOR COLLECTIONVIEW
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") != nil) {
            appd.customSizedWidth = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") != nil) {
            appd.customSizedHeight = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") != nil) {
            appd.cswLocation = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") != nil) {
            appd.cshLocation = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            COLUMNSIZE = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
        }
        
        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
            ROWSIZE = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
        }
    }
    
    @objc func input(){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.collectionViewCellSizeChanged = 0
        let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
        appd.wsSheetIndex = sheetIdx!
        print("wsSheetIndex",appd.wsSheetIndex)
        
        //let pasteboard = UIPasteboard.general
        //pasteboard.string = ""

        // See the matching comment on datainputFromOtherComtroller's call --
        // dead undo mechanism, skipped for CSV to avoid the COW-copy trap.
        if !isCSV {
            fontcolorClass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        }

        var element: String = datainputview.stringbox.text!

        if element.hasPrefix("=") {
            let targets = ["sum", "average", "min", "max"]
            for target in targets {
                // （options: .caseInsensitive）
                element = element.replacingOccurrences(
                    of: target,
                    with: target.uppercased(),
                    options: .caseInsensitive
                )
            }
        }

        
        datainputview.stringbox.text = ""
        
        //add more complicated functionality
        if autoComplete(src: element).count > 1 {
            element = autoComplete(src: element)
        }
        
        
        let IP :String = cursor   //String(currentindex!.item) + String(currentindex!.section)
        let t_item = IP.components(separatedBy: ",")[0]
        let t_section = IP.components(separatedBy: ",")[1]
        
        let IP_i = Int(t_item)!
        let IP_s = Int(t_section)!
        var checkInput = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "")
        if !element.contains("...") && !element.contains(":"){
            element = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "")
        }
        
        var collocation = -1
        if element.contains("→"){
            let checkAlpha = alphabetOnlyString(text: element)
            if columnNames.index(of: checkAlpha) != nil {
                collocation = columnNames.index(of: checkAlpha)!
                checkInput = checkInput.replacingOccurrences(of: checkAlpha, with: String(collocation))
            }
        }
        
        if (element.contains(":") && element.contains("↓"))  || (element.contains(":") && element.contains("←")) || (element.contains(":") && element.contains("↑"))  || (element.contains(":") && element.contains("→")) {
            
            element = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "↑", with: "").replacingOccurrences(of: "←", with: "")
            //20200502
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                //storeInput(IPd: IP, elementd: element) implement this function in iphone too? i dont know it is a good idea
                let padAry = element.components(separatedBy: ":")
                
                if down_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s+idx)
                        if IP_s+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            let rlt = excelEntry(srcString: each, cellId: alphabet + String(IP_s+idx)) ?? true
                            if(!rlt){
                                
                                if (!rlt) {
                                    let alert = UIAlertController(
                                        title: "Something went wrong",
                                        message: "We recommend loading from backups.",
                                        preferredStyle: .alert
                                    )

                                    let loadAction = UIAlertAction(title: "Load from Backups", style: .default) { _ in
                                        self.moveToBackupsView()
                                    }
                                    
                                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

                                    alert.addAction(loadAction)
                                    alert.addAction(cancelAction)

                                    self.present(alert, animated: true, completion: nil)
                                }

                                
                            }
                        }
                    }
                    datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
                }
                
                if right_bool{
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i+idx) + "," + String(IP_s)
                        if IP_i+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s))
                        }
                    }
                    datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
                }
                break
                
                
            case .pad:
                let padAry = element.components(separatedBy: ":")
                
                if down_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s+idx)
                        if IP_s+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s+idx))
                        }
                    }
                    datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
                }
                
                
                
                if right_bool{
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i+idx) + "," + String(IP_s)
                        if IP_i+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s))
                        }
                    }
                    datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
                }
                
                break
                
            default:
                storeInput(IPd: IP, elementd: element)
                let alphabet = getExcelColumnName(columnNumber: IP_i)
                excelEntry(srcString: element, cellId: alphabet + String(IP_s))
                break
            }
            XLSV.pasteboard.string = clipboard
            //It makes better UX by shiftting the selected cell
            changeaffected.removeAll()
            if right_bool{
                currentindex = IndexPath(item:currentindex.item+1, section: currentindex.section)
            }
            
            if down_bool{
                currentindex = IndexPath(item:currentindex.item, section: currentindex.section+1)
            }
            cursor = String(currentindex.item) + "," + String(realRow(forDisplaySection: currentindex.section))
            
            stringboxText = element
            return
        }
        
        
        //it take care of empty string
        // storeInput already recalculates just this one cell (see
        // recalculateSingleCell) and updates f_location/f_location_alphabet/
        // f_calculated incrementally -- no full calculatormode_update_main()
        // rebuild needed here anymore. f_content is dead (never read anywhere,
        // only ever .removeAll()'d), kept as a no-op like its sibling call sites.
        storeInput(IPd: IP, elementd: element)
        f_content.removeAll()

        //always excel, no such thing as csv case
        if element == ""{
            //TODO want to modify xml
            element = " "
        }
        excelEntry(srcString: element,cellId: getIndexlabel())
        
        //It makes better UX
        changeaffected.removeAll()
        if right_bool{
            currentindex = IndexPath(item:currentindex.item+1, section: currentindex.section)
        }
        
        if down_bool{
            currentindex = IndexPath(item:currentindex.item, section: currentindex.section+1)
        }
        cursor = String(currentindex.item) + "," + String(realRow(forDisplaySection: currentindex.section))
        stringboxText = element
        
        return
    }
    
    @objc func virtual_input(source:String,cellId:String){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.collectionViewCellSizeChanged = 0
        let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
        appd.wsSheetIndex = sheetIdx!
        print("wsSheetIndex",appd.wsSheetIndex)
        
//        let pasteboard = UIPasteboard.general
//        pasteboard.string = ""

        // See the matching comment on datainputFromOtherComtroller's call --
        // dead undo mechanism, skipped for CSV to avoid the COW-copy trap.
        if !isCSV {
            fontcolorClass.storeValues(rl:location,rc:content,rsize:ROWSIZE,csize:COLUMNSIZE)
        }

        var element = source
        if element.hasPrefix("=") {
            let targets = ["sum", "average", "min", "max"]
            for target in targets {
                // （options: .caseInsensitive）
                element = element.replacingOccurrences(
                    of: target,
                    with: target.uppercased(),
                    options: .caseInsensitive
                )
            }
        }

        
        //add more complicated functionality
        if autoComplete(src: element).count > 1 {
            element = autoComplete(src: element)
        }
        
        
        let IP :String = cursor   //String(currentindex!.item) + String(currentindex!.section)
        let t_item = IP.components(separatedBy: ",")[0]
        let t_section = IP.components(separatedBy: ",")[1]
        
        let IP_i = Int(t_item)!
        let IP_s = Int(t_section)!
        var checkInput = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "")
        
        if !element.contains("...") && !element.contains(":"){
            element = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "")
        }
        
        var collocation = -1
        if element.contains("→"){
            let checkAlpha = alphabetOnlyString(text: element)
            if columnNames.index(of: checkAlpha) != nil {
                collocation = columnNames.index(of: checkAlpha)!
                checkInput = checkInput.replacingOccurrences(of: checkAlpha, with: String(collocation))
            }
        }
        
        if (element.contains(":") && element.contains("↓"))  || (element.contains(":") && element.contains("←")) || (element.contains(":") && element.contains("↑"))  || (element.contains(":") && element.contains("→")) {
            
            element = element.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "↑", with: "").replacingOccurrences(of: "←", with: "")
            //20200502
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                //storeInput(IPd: IP, elementd: element) implement this function in iphone too? i dont know it is a good idea
                let padAry = element.components(separatedBy: ":")
                
                if down_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s+idx)
                        if IP_s+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s+idx))
                        }
                    }
                }
                
                if right_bool{
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i+idx) + "," + String(IP_s)
                        if IP_i+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s))
                        }
                    }
                }
                break
                
                
            case .pad:
                let padAry = element.components(separatedBy: ":")
                
                if down_bool {
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i) + "," + String(IP_s+idx)
                        if IP_s+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s+idx))
                        }
                    }
                }
                
                
                
                if right_bool{
                    for idx in 0..<padAry.count{
                        let IPl = String(IP_i+idx) + "," + String(IP_s)
                        if IP_i+idx <= 0 {
                            //it's
                        }else{
                            var each = padAry[idx]
                            if each == "-"{
                                if location.contains(IPl){
                                    let i = location.index(of: IPl)
                                    each = content[i!]
                                }
                            }
                            storeInput(IPd: IPl, elementd: each)
                            let alphabet = getExcelColumnName(columnNumber: IP_i+idx)
                            clipboard = clipboard + alphabet + String(IP_s+idx) + "+"
                            excelEntry(srcString: each, cellId: alphabet + String(IP_s))
                        }
                    }
                }
                
                break
                
            default:
                storeInput(IPd: IP, elementd: element)
                let alphabet = getExcelColumnName(columnNumber: IP_i)
                excelEntry(srcString: element, cellId: alphabet + String(IP_s))
                break
            }
            XLSV.pasteboard.string = clipboard
            //It makes better UX
            changeaffected.removeAll()
            if right_bool{
                currentindex = IndexPath(item:currentindex.item+1, section: currentindex.section)
            }
            
            if down_bool{
                currentindex = IndexPath(item:currentindex.item, section: currentindex.section+1)
            }
            cursor = String(currentindex.item) + "," + String(realRow(forDisplaySection: currentindex.section))
            return
        }
        
        //it take care of empty string
        // storeInput already recalculates just this one cell (see
        // recalculateSingleCell) and updates f_location/f_location_alphabet/
        // f_calculated incrementally -- no full calculatormode_update_main()
        // rebuild needed here anymore. f_content is dead (never read anywhere,
        // only ever .removeAll()'d), kept as a no-op like its sibling call sites.
        // Multi-cell drag-fill callers (fillFunctionInSelectedCellContent /
        // fillDateInSelectedCellContent) still run their own full
        // calculatormode_update_main() pass after their loop of virtual_input
        // calls completes, so correctness across a filled range is unaffected.
        storeInput(IPd: IP, elementd: element)
        f_content.removeAll()

        //always excel, no such thing as csv case
        if element == ""{
            //TODO want to modify xml
            element = " "
        }
        excelEntry(srcString: element,cellId: cellId) //cellId, AB44, A5,B4...
        
        //It makes better UX
        changeaffected.removeAll()
        if right_bool{
            currentindex = IndexPath(item:currentindex.item+1, section: currentindex.section)
        }
        
        if down_bool{
            currentindex = IndexPath(item:currentindex.item, section: currentindex.section+1)
        }
        cursor = String(currentindex.item) + "," + String(realRow(forDisplaySection: currentindex.section))
        return
    }
    
    func excelEntry(srcString:String,cellId:String) -> Bool?
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        var element = srcString
        
        // \ / ? * : [ ] escaping command chars to literal
        let invalidChars = CharacterSet(charactersIn: "\\\"")
        element = element.components(separatedBy: invalidChars).joined()
        
        if isExcel && srcString.count > 0{
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            //excel work

            //https://p-space.jp/index.php/development/open-xml-sdk/84-openxmlsdk8
            //TODO save as a formula
            //if !element.hasPrefix("="){//mathematical expression doesnt support in Excel
                //update sheet1,or2,or3 or xml each data entry
                //date object
                //hh:mm case MAX 24*60*60[s]
            //TODO comment out for now
//                let hhmm = element.components(separatedBy: ":")
//                if hhmm.count == 2, let hh = Decimal(string: hhmm[0]), let mm = Decimal(string: hhmm[1]) {
//                    // Ensure hhmm array has two elements and both are successfully converted to Decimal
//                    
//                    // Calculate total number of seconds in a day
//                    let max = Decimal(24) * Decimal(60) * Decimal(60)
//                    
//                    // Calculate total number of seconds from HH:MM format
//                    let divid = hh * Decimal(60) * Decimal(60) + mm * Decimal(60)
//                    
//                    // Calculate the fraction representing the time
//                    element = String(describing: divid / max)
//                    numFmt = 20
//                }
//                
//                //date conversion
//                let dateString = element
//                // Create a DateFormatter to parse the date string
//                let dateFormatter = DateFormatter()
//                
//                // Create a DateFormatter to parse the date string
//                let dateFormatter2 = DateFormatter()
//                dateFormatter2.dateFormat = "MM/dd/yyyy"
//                
//                // Parse the date string
//                if let date = dateFormatter2.date(from: dateString) {
//                    // Define the Excel base date (January 1, 1900)
//                    let excelBaseDate = DateComponents(year: 1899, month: 12, day: 30)
//                    let calendar = Calendar(identifier: .gregorian)
//                    let excelBaseDateTimeInterval = calendar.date(from: excelBaseDate)!.timeIntervalSinceReferenceDate
//                    
//                    // Calculate the time interval between the given date and the Excel base date
//                    let dateTimeInterval = date.timeIntervalSinceReferenceDate
//                    let excelDateTimeInterval = dateTimeInterval - excelBaseDateTimeInterval
//                    
//                    // Calculate the corresponding serial number
//                    let serialNumber = Int(excelDateTimeInterval / (24 * 60 * 60))
//                    
//                    print("Excel serial number:", serialNumber) // Output: 39448
//                    element = String(serialNumber)
//                    numFmt = 14
//                    
//                }
                
            if element == " "{
                element = ""
            }
            let f_idx = f_location_alphabet.firstIndex(of: getIndexlabelForExcel())
            var calculated = ""
            if (f_idx != nil){
                calculated = f_calculated[f_idx!]
            }
            // Deferred write (see PendingXlsxChangeSet.swift): record in memory
            // instead of calling testUpdateStringBox on every keystroke. The
            // real xlsx write only happens at Export/Save
            // (flushPendingXlsxChangesIfNeeded).
            pendingXlsxChanges.record(sheetIndex: appd.wsSheetIndex, cellId: cellId, content: element, calculatedValue: calculated)
            updateUnsavedDataReminderVisibility()
        }
        return true
    }
    
    //for delete purpose
    func excelEntryBulk(srcString:String,cellId:String,bka:[String] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        var element = srcString
        if isExcel && srcString.count > 0{
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            //excel work
            // numFmt is computed by the date/time parsing below but no longer
            // consumed (used to be passed to testUpdateStringBox) -- kept as a
            // no-op sink since this whole function has zero call sites today
            // (see the deferred-write comment above excelEntry) and the
            // element-mutation side effects below still matter if it's ever
            // wired up.
            var numFmt = 0

            //https://p-space.jp/index.php/development/open-xml-sdk/84-openxmlsdk8
            //TODO save as a formula
            //if !element.hasPrefix("="){//mathematical expression doesnt support in Excel
                //update sheet1,or2,or3 or xml each data entry
                //date object
                //hh:mm case MAX 24*60*60[s]
                let hhmm = element.components(separatedBy: ":")
                if hhmm.count == 2, let hh = Decimal(string: hhmm[0]), let mm = Decimal(string: hhmm[1]) {
                    // Ensure hhmm array has two elements and both are successfully converted to Decimal
                    
                    // Calculate total number of seconds in a day
                    let max = Decimal(24) * Decimal(60) * Decimal(60)
                    
                    // Calculate total number of seconds from HH:MM format
                    let divid = hh * Decimal(60) * Decimal(60) + mm * Decimal(60)
                    
                    // Calculate the fraction representing the time
                    element = String(describing: divid / max)
                    numFmt = 20
                }
                
                //date conversion
                let dateString = element
                // Create a DateFormatter to parse the date string
                let dateFormatter = DateFormatter()
                
                // Create a DateFormatter to parse the date string
                let dateFormatter2 = DateFormatter()
                dateFormatter2.dateFormat = "MM/dd/yyyy"
                
                // Parse the date string
                if let date = dateFormatter2.date(from: dateString) {
                    // Define the Excel base date (January 1, 1900)
                    let excelBaseDate = DateComponents(year: 1899, month: 12, day: 30)
                    let calendar = Calendar(identifier: .gregorian)
                    let excelBaseDateTimeInterval = calendar.date(from: excelBaseDate)!.timeIntervalSinceReferenceDate
                    
                    // Calculate the time interval between the given date and the Excel base date
                    let dateTimeInterval = date.timeIntervalSinceReferenceDate
                    let excelDateTimeInterval = dateTimeInterval - excelBaseDateTimeInterval
                    
                    // Calculate the corresponding serial number
                    let serialNumber = Int(excelDateTimeInterval / (24 * 60 * 60))
                    
                    print("Excel serial number:", serialNumber) // Output: 39448
                    element = String(serialNumber)
                    numFmt = 14
                    
                }
                
            if element == " "{
                element = ""
            }
            // Deferred write, same as excelEntry -- record the primary cell and
            // every bulk-delete target as cleared instead of writing to disk.
            pendingXlsxChanges.record(sheetIndex: appd.wsSheetIndex, cellId: cellId, content: element, calculatedValue: "")
            for clearedCellId in bka {
                pendingXlsxChanges.record(sheetIndex: appd.wsSheetIndex, cellId: clearedCellId, content: "", calculatedValue: "")
            }
            updateUnsavedDataReminderVisibility()
        }
    }
    
    //rowDeleteOperation
    func excelRowsDelete(rowRange:[Int] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
            _ = serviceInstance.testRowsDeleteBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, rowRange: rowRange, locationInExcel: locationInExcel)
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
           
           
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
//                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
                
            }
        }
    }
    
    //excelRowsAdd
    func excelRowsAdd(rowRange:[Int] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
            _ = serviceInstance.testRowsAddBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, rowRange: rowRange, locationInExcel: locationInExcel)
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
           
           
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
                
            }
        }
    }
    
    //excelRowsAdd
    func excelColsAdd(colRange:[Int] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
            _ = serviceInstance.testColsAddBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, colRange: colRange, locationInExcel: locationInExcel)
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
           
           
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
//                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
                
            }
        }
    }
    
    func excelColsDelete(colRange:[Int] = [])
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
            _ = serviceInstance.testColsDeleteBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path, colRange: colRange, locationInExcel: locationInExcel)
            
            //sheet cell get touched
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            stringboxText = ""
        
            print("go to file view")
           
           
            
            // Present the target view controller after LoadingFileController's view has appeared
            DispatchQueue.main.async {
//                self.present(targetViewController, animated: true, completion: nil)
                self.loadExcelSheet(idx: appd.wsSheetIndex){
                    // Assuming `collectionView` is your UICollectionView instance
                    if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
                        customLayout.resetCellAttrsDictionaryItemZindex()
                        customLayout.prepare()
                        customLayout.invalidateLayout() // Call the method on the instance
                        self.myCollectionView.reloadData()
                    } else {
                        print("CustomCollectionViewLayout is not set as the current layout")
                    }
                }
            }
        }
    }
    
    func excelCopySheet(filename:String = "")
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            // Structural sheet operation reading straight off disk below --
            // must see any not-yet-flushed edits first (see PendingXlsxChangeSet.swift).
            flushPendingXlsxChangesIfNeeded()

            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            let service = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            
            
            let rlt = service.testGetSheetDataBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)
            
            
            if rlt == nil{
                print("Error: sheetData is nil")
                return
            }
            excelAddSheet(filename: filename,copySheetData: rlt!)
        }
        
        
    }
    
    func excelAddSheet(filename:String = "", copySheetData:String = "")
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if isExcel {
            // Structural sheet operation -- see the matching comment in excelCopySheet.
            // Harmless no-op here when already flushed by an excelCopySheet caller.
            flushPendingXlsxChangesIfNeeded()

            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            
            
            print("wsSheetIndex",appd.wsSheetIndex)
            var message = "Set a sheet name."
            var yes = "OK"
            var no = "No"
            let locationstr = (NSLocale.preferredLanguages[0] as String?)!
            
            
            let alert = UIAlertController(title: "SHEET NAME", message: message, preferredStyle: .alert)
            alert.addTextField()
            
            
            let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
                var name = alert.textFields?[0].text
                
                let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                
                //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
                let today: Date = Date()
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy HH-mm-ss"
                if name == "" || (self.localFileNames.firstIndex(of: name!) != nil){
                    name = dateFormatter.string(from: today)
                }
            
                _ = serviceInstance.testAddSheetBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path,filename: name!,copySheetData: copySheetData)
                
                //Not got a new sheet in appd .. seems working
                let ic = iCloudViewController()
                ic.getExcelSheetNamesAndIds(path: appd.imported_xlsx_file_path)
                
                let nameId = appd.sheetNames.firstIndex(of: name!)
                //TODO Fetch New One's sheetIndex from xml
                let sheetId = appd.sheetNameIds[nameId!]
                appd.wsSheetIndex = Int(sheetId)!
                
                
                //sheet cell get touched
                appd.collectionViewCellSizeChanged = 1
                appd.cswLocation.removeAll()
                appd.customSizedWidth.removeAll()
                appd.cshLocation.removeAll()
                appd.customSizedHeight.removeAll()
                
                
                self.f_calculated.removeAll()
                self.f_content.removeAll()
                self.content.removeAll()
                self.location.removeAll()
                self.f_location_alphabet.removeAll()
                
                //print("sheet changed",indexPath.item)
                self.stringboxText = ""
            
                print("go to file view")
               
                DispatchQueue.main.async {
                    self.loadExcelSheet(idx: Int(appd.wsSheetIndex)){
//                        print("after_sheetNameIds",appd.sheetNameIds)
//                        print("after_Names",appd.sheetNames)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let index = self.localFileNames.firstIndex(of: name!) {
                                self.currentFileNameCollectionViewIdx = IndexPath(item: index, section: 0)
                                self.FileCollectionView.reloadData()
                                self.myCollectionView.reloadData()
                            }else{
                                print("Index not found, something went wrong")
                            }
                        }
                    }
                }
                
//                // Present the target view controller after LoadingFileController's view has appeared
//                DispatchQueue.main.async {
//    //                self.present(targetViewController, animated: true, completion: nil)
//                    self.loadExcelSheet(idx: appd.wsSheetIndex){
//                        // Assuming `collectionView` is your UICollectionView instance
//                        if let customLayout = self.myCollectionView.collectionViewLayout as? CustomCollectionViewLayout {
//                            customLayout.resetCellAttrsDictionaryItemZindex()
//                            customLayout.prepare()
//                            customLayout.invalidateLayout() // Call the method on the instance
//                            self.myCollectionView.reloadData()
//                            self.FileCollectionView.reloadData()
//                        } else {
//                            print("CustomCollectionViewLayout is not set as the current layout")
//                        }
//                    }
//                    
//                }
                
                if (self.customview2 != nil){
                    self.customview2.removeFromSuperview()
                }
                
            })
            
            alert.addAction(confirmAction)
            alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func excelDeleteSheet(filename:String = "")
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if appd.sheetNames.count <= 1 {
            let errorAlert = UIAlertController(title: "ERROR", message: "The book needs at least one sheet.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(errorAlert, animated: true)
            return
        }
        
        if isExcel {
            // Structural sheet operation -- see the matching comment in excelCopySheet.
            flushPendingXlsxChangesIfNeeded()

            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            var message = "Set a sheet name."
            var yes = "OK"
            var no = "No"
            let locationstr = (NSLocale.preferredLanguages[0] as String?)!


            let alert = UIAlertController(title: "SHEET NAME", message: message, preferredStyle: .alert)
            alert.addTextField()
            
            alert.textFields?[0].text = localFileNames[currentFileNameCollectionViewIdx.item]
            
            let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
                
                var name = alert.textFields?[0].text
                
                let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                
                //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
                let today: Date = Date()
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy HH-mm-ss"
                if name == ""{
                    name = dateFormatter.string(from: today)
                }
                print("before",appd.sheetNameIds)
                print("before",appd.sheetNames)
                _ = serviceInstance.testDeleteSheetBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path,sheetname: name!)
                
                //sheet cell get touched
                appd.collectionViewCellSizeChanged = 1
                appd.cswLocation.removeAll()
                appd.customSizedWidth.removeAll()
                appd.cshLocation.removeAll()
                appd.customSizedHeight.removeAll()
                
                self.f_calculated.removeAll()
                self.f_content.removeAll()
                self.content.removeAll()
                self.location.removeAll()
                self.f_location_alphabet.removeAll()
                
                //print("sheet changed",indexPath.item)
                self.stringboxText = ""
            
                print("go to file view")
                
                DispatchQueue.main.async {
                    appd.sheetNameIds.remove(at: Int(self.currentFileNameCollectionViewIdx.item))
                    appd.sheetNames.remove(at: Int(self.currentFileNameCollectionViewIdx.item))
                    appd.wsSheetIndex = Int(appd.sheetNameIds.first!)!
                    self.loadExcelSheet(idx: Int(appd.sheetNameIds.first!)!){
                        self.currentFileNameCollectionViewIdx = IndexPath(item: 0, section: 0)
                        self.FileCollectionView.reloadData()
                        self.myCollectionView.reloadData()
                        // Assuming `collectionView` is your UICollectionView instance
                    }
                }
               
                // Present the target view controller after LoadingFileController's view has appeared
                //self.customview2.removeFromSuperview()
                
            })
            
            alert.addAction(confirmAction)
            alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func excelChangeSheetName(filename:String = "")
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        
        
        if isExcel {
            // Structural sheet operation -- see the matching comment in excelCopySheet.
            flushPendingXlsxChangesIfNeeded()

            let sheetIdx = Int(appd.sheetNameIds[self.currentFileNameCollectionViewIdx.item])
            appd.wsSheetIndex = sheetIdx!
            print("wsSheetIndex",appd.wsSheetIndex)
            var message = "Set a new sheet name."
            var yes = "OK"
            var no = "No"
            let locationstr = (NSLocale.preferredLanguages[0] as String?)!
            
            
            let alert = UIAlertController(title: "NEW SHEET NAME", message: message, preferredStyle: .alert)
            alert.addTextField()
            
            let oldname = localFileNames[currentFileNameCollectionViewIdx.item]
            alert.textFields?[0].text = localFileNames[currentFileNameCollectionViewIdx.item]
            
            let confirmAction = UIAlertAction(title: yes, style: .default, handler: { action in
                
                var name = alert.textFields?[0].text ?? ""
                
                name = name.replacingOccurrences(of: "&", with: "&amp;")
                                         .replacingOccurrences(of: "<", with: "&lt;")
                
                if let index = self.localFileNames.firstIndex(of: name) {
                    let errorAlert = UIAlertController(title: "ERROR", message: "Duplication in sheet names", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                    return
                }
                
             
                
                let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                
                //fp: String = "", cellIdxString:String = "", ovwritten:[String] = [], ovwriting:[String] = []
                let today: Date = Date()
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy HH-mm-ss"
                if name == ""{
                    name = dateFormatter.string(from: today)
                }
                print("before",appd.sheetNameIds)
                print("before",appd.sheetNames)
                _ = serviceInstance.testChangeSheetNameBox(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path,sheetname: oldname,newsheetname: name)
                
                //sheet cell get touched
                appd.collectionViewCellSizeChanged = 1
                appd.cswLocation.removeAll()
                appd.customSizedWidth.removeAll()
                appd.cshLocation.removeAll()
                appd.customSizedHeight.removeAll()
                
                self.f_calculated.removeAll()
                self.f_content.removeAll()
                self.content.removeAll()
                self.location.removeAll()
                self.f_location_alphabet.removeAll()
                
                //print("sheet changed",indexPath.item)
                self.stringboxText = ""
            
                print("go to file view")
                
                DispatchQueue.main.async {
                    appd.sheetNameIds.removeAll()
                    appd.sheetNames.removeAll()
                    appd.wsSheetIndex = Int(appd.wsSheetIndex)
                    self.loadExcelSheet(idx: Int(appd.wsSheetIndex)){
                        print("after_sheetNameIds",appd.sheetNameIds)
                        print("after_Names",appd.sheetNames)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let index = self.localFileNames.firstIndex(of: name) {
                                self.currentFileNameCollectionViewIdx = IndexPath(item: index, section: 0)
                                self.FileCollectionView.reloadData()
                            }
                        }
                    }
                }
               
                // Present the target view controller after LoadingFileController's view has appeared
                //self.customview2.removeFromSuperview()
                
            })
            
            alert.addAction(confirmAction)
            alert.addAction(UIAlertAction(title: no, style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func storeInput(IPd:String, elementd:String)
    {
        let __storeInputStart = CFAbsoluteTimeGetCurrent()
        // storeInput is the single chokepoint every cell content commit passes
        // through (typing + Enter, paste, formula results, clear), so this is
        // where runtime edit history gets recorded rather than at each caller.
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let oldValue = locationIndex(for: IPd).map { content[$0] } ?? ""
        if oldValue != elementd {
            appd.editHistory.append(CellEditRecord(location: IPd, oldValue: oldValue, newValue: elementd, timestamp: Date()))
        }

        if elementd.replacingOccurrences(of: " ", with: "").count > 0{
            if let i = locationIndex(for: IPd) {

                // colorclass.storeValues() (called separately, just before
                // storeInput, from input()/patchJsonCacheAndRefresh) aliases
                // appd.RC/appd.RL to this same content/location buffer as part of
                // a 9-deep undo ring buffer. Swift arrays are copy-on-write, so
                // that alias is cheap by itself -- but it means the very next
                // mutation of content/location (here) is no longer touching a
                // uniquely-referenced buffer, forcing Swift to silently deep-copy
                // the entire array before applying this one-cell edit. Timing
                // isolates exactly that.
                let __mutateStart = CFAbsoluteTimeGetCurrent()
                content[i] = isCSV ? elementd : transformFormulaSyntax(elementd)
                location[i] = IPd
                perfLog(String(format: "PERF storeInput.mutateExisting: %.3fs content=%d", CFAbsoluteTimeGetCurrent() - __mutateStart, content.count))

                // location[i] still equals IPd (that's how i was found), so
                // locationInExcel[i] is already correct -- no rebuild needed.
                if !isCSV {
                    recalculateAfterEdit(index: i, posKey: IPd)
                }

            }else{
                content.append(isCSV ? elementd : transformFormulaSyntax(elementd))
                location.append(IPd)

                switch UIDevice.current.userInterfaceIdiom {
                case .pad:
                    //updated
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                    break

                default:
                    //updated
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                    break
                }

                // First entry into a previously-empty cell -- locationInExcel
                // needs a matching new entry appended (not rebuilt from scratch;
                // see the perf note below on why a full rebuild here crashed).
                if !isCSV {
                    let newIndex = content.count - 1
                    let parts = IPd.components(separatedBy: ",")
                    if let colStr = parts.first, let colInt = Int(colStr), let rowStr = parts.last {
                        locationInExcel.append(getExcelColumnName(columnNumber: colInt) + rowStr)
                    } else {
                        locationInExcel.append("")
                    }
                    recalculateAfterEdit(index: newIndex, posKey: IPd)
                }

            }
        }else{
            if let i = locationIndex(for: IPd) {
                content.remove(at: i)
                location.remove(at: i)
                textsize.remove(at: i)
                bgcolor.remove(at: i)
                tcolor.remove(at: i)
                if !isCSV {
                    if i < locationInExcel.count {
                        locationInExcel.remove(at: i)
                    }
                    removeFormulaEntry(posKey: IPd)
                }
            }
        }

        // locationInExcel/f_location/f_calculated are now updated incrementally
        // above (just the touched cell), not via a full initExcelLocation() +
        // calculatormode_update_main() rebuild across the whole sheet on every
        // single edit. Confirmed via PERF log that initExcelLocation() alone
        // cost 4.68s per keystroke on a 100k-row/1.4M-cell file, with
        // calculatormode_update_main() immediately after it and no completion
        // log -- i.e. this was blocking the main thread long enough for iOS to
        // kill the app mid-calculation. Tradeoff: other formula cells that
        // reference the one just edited won't live-update until they're
        // themselves re-entered (see recalculateSingleCell's comment).
        perfLog(String(format: "PERF storeInput.total: %.3fs", CFAbsoluteTimeGetCurrent() - __storeInputStart))
    }
    
    func saveuserD() {
        // location/content used to be dumped here in full (NEWTMLOCATION/
        // NEWTMCONTENT) on every single cell-edit commit, each followed by an
        // explicit synchronize() -- UserDefaults.set() already persists on its
        // own, synchronize() just forces a redundant synchronous full-plist
        // flush, and for a large sheet (100k+ cells) that's a severe freeze on
        // every return-key press. Nothing in the three active view controllers
        // ever reads those two keys back (only orphaned legacy screens do:
        // CalcViewController, SearchController, SharedReadFile, StyleReadFile,
        // inDevViewController -- none reachable from the current app flow), so
        // this was pure cost for no benefit. NEWCsize/NEWRsize are still read
        // back elsewhere (initString/initSheetData/isExcelSheetData's CSV
        // branch), so those stay -- just without synchronize().
        let appheight = UserDefaults.standard
        appheight.set(COLUMNSIZE, forKey: "NEWCsize")

        let appheight2 = UserDefaults.standard
        appheight2.set(ROWSIZE, forKey: "NEWRsize")
    }
    
    func alphabetOnlyString(text: String) -> String {
        let okayChars = Set("ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
        return text.filter {okayChars.contains($0) }
    }
    
    // Used to dump bgcolor/tcolor/textsize (full sheet, every cell) into
    // UserDefaults on every cell-edit commit, each followed by an explicit
    // synchronize() -- same cost/dead-weight class as saveuserD's removed
    // writes above. Kept as a no-op rather than deleting the call sites, since
    // this is called from several places.
    func saveuserF(){
    }
    
    
    func show3() {
        
        if customview3 != nil{
            
            customview3.removeFromSuperview()
        }
        
        switch tag_int {
        case 0:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 155))
            break
        case 1:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 155))
            break
        case 2:
            customview3 = Customview3(frame: CGRect(x:5,y:50, width: 250,height: 155))
            break
        case 3:
            customview3 = Customview3(frame: CGRect(x:5,y:10, width: 250,height: 155))
            break
        case 4:
            customview3 = Customview3(frame: CGRect(x:5,y:200, width: 250,height: 155))
            break
        case 5:
            customview3 = Customview3(frame: CGRect(x:5,y:190, width: 250,height: 155))
            break
            
            
            
            
            
        default:
            customview3 = Customview3(frame: CGRect(x:5,y:150, width: 235,height: 155))
            break
            
        }
        
        
        
        
        customview3.layer.borderWidth = 1
        
        customview3.layer.cornerRadius = 8;
        
        
        customview3.layer.borderColor = UIColor.black.cgColor
        
        customview3.closebutton.addTarget(self, action: #selector(close), for: UIControl.Event.touchUpInside)
        
        
        //customview3.backbutton.addTarget(self, action: #selector(back2(_:)), for: UIControl.Event.touchUpInside)
        
        customview3.mcselector.addTarget(self, action: #selector(sliderValueChangedsearch), for: UIControl.Event.valueChanged)
        
        
        customview3.searchkbutton.addTarget(self, action: #selector(search), for: UIControl.Event.touchUpInside)
        
        customview3.replaceokbutton.addTarget(self, action: #selector(replace), for: UIControl.Event.touchUpInside)
        
        
        self.view.addSubview(customview3)
    }
    
    @objc func sliderValueChangedsearch(_ sender:Any){
        
        csview = !csview
    }
    
    @objc func search(){
        changeaffected.removeAll()
        search_text = customview3.searchfield.text!
        if customview3.mcselector.selectedSegmentIndex == 0 {
            for i in 0..<content.count {
                if content[i] == search_text{
                    changeaffected.append(location[i])
                }
            }
        }else {
            for i in 0..<content.count {
                if content[i].contains(search_text){
                    changeaffected.append(location[i])
                }
            }
        }
        saveuserD()
        myCollectionView.reloadData()
    }
    
    @objc func replace(){
        changeaffected.removeAll()
        search_text = customview3.searchfield.text!
        //complete
        if customview3.mcselector.selectedSegmentIndex == 0 {
            for i in 0..<content.count {
                if content[i] == search_text{
                    content[i] = customview3.replacefield.text!
                    changeaffected.append(location[i])
                    //TODO update sharedstring
                }
            }
        //partly
        }else {
            for i in 0..<content.count {
                if content[i].contains(search_text){
                    content[i] = content[i].replacingOccurrences(of: search_text, with: customview3.replacefield.text!)
                    changeaffected.append(location[i])
                    //TODO update sharedstring
                }
            }
        }
        
        myCollectionView.reloadData()
    }
    
    @objc func
    excel_sum_each(fidx:Int,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        if fc[fidx].hasPrefix("=SUM("){
            return ExcelHelper().excel_sum(src: fc[fidx].uppercased(), cursor:fl[fidx],fc: fc,fl: fl,fle: fle,fr: fr,lc: lc,ll:ll,lle: lle,lr: lr)
        }
        return "calculation error"
    }
    
    @objc func excel_average_each(fidx:Int,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        if fc[fidx].hasPrefix("=AVERAGE("){
            return ExcelHelper().excel_average(src: fc[fidx].uppercased(), cursor:fl[fidx],fc: fc,fl: fl,fle: fle,fr: fr,lc: lc,ll:ll,lle: lle,lr: lr)
        }
        return "calculation error"
    }
    
    @objc func excel_min_each(fidx:Int,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        if fc[fidx].hasPrefix("=MIN("){
            return ExcelHelper().excel_min(src: fc[fidx].uppercased(), cursor:fl[fidx],fc: fc,fl: fl,fle: fle,fr: fr,lc: lc,ll:ll,lle: lle,lr: lr)
        }
        return "calculation error"
    }
    
    @objc func excel_max_each(fidx:Int,fc:[String],fl:[String],fle:[String],fr:[String],lc:[String],ll:[String],lle:[String],lr:[String])->String{
        if fc[fidx].hasPrefix("=MAX("){
            return ExcelHelper().excel_max(src: fc[fidx].uppercased(), cursor:fl[fidx],fc: fc,fl: fl,fle: fle,fr: fr,lc: lc,ll:ll,lle: lle,lr: lr)
        }
        return "calculation error"
    }
    
    func applyValue(formula: String, ref: String, value: String) -> String {
        let pattern = "\\b\(ref)(?!\\d)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return formula
        }
        
        let range = NSRange(location: 0, length: formula.utf16.count)
        return regex.stringByReplacingMatches(in: formula, options: [], range: range, withTemplate: value)
    }
    
    func isReadyToCalculate(expression:String) -> Bool{
        let charset: Set<Character> = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        if expression.contains(where: { charset.contains($0) }) {
            return false
        }
        return true
    }

    // Removes posKey's entry from f_location/f_location_alphabet/f_calculated,
    // if it has one -- used when a cell that used to hold a formula gets
    // overwritten with plain content or cleared entirely.
    private func removeFormulaEntry(posKey: String) {
        if let k = fLocationIndex(for: posKey) {
            f_calculated.remove(at: k)
            f_location_alphabet.remove(at: k)
            f_location.remove(at: k)
            invalidateFLocationIndexCache()
        }
    }

    // Reads AppDelegate.fullFormulaRecalcEnabled (user setting, see
    // SettingsViewController) to decide whether an edit triggers a full
    // whole-sheet recalc or just recalculates the cell that was touched.
    private func recalculateAfterEdit(index: Int, posKey: String) {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if appd.fullFormulaRecalcEnabled {
            calculatormode_update_main()
        } else {
            recalculateSingleCell(index: index, posKey: posKey)
        }
    }

    // Scoped counterpart to calculatormode_update_main() -- recalculates just
    // the one cell that was actually edited (via storeInput's "edit" or "first
    // entry" cases) instead of rebuilding f_location/f_calculated for every
    // formula cell in the sheet. On a 100k-row file, calculatormode_update_main's
    // substitution loop is O(formulas * literals) and its own comment already
    // documents this as a crash risk at scale -- confirmed live via a PERF log
    // showing storeInput's own initExcelLocation() alone costing 4.68s per
    // keystroke, with calculatormode_update_main immediately after it and no
    // completion log, i.e. the app was killed mid-calculation. Used when
    // AppDelegate.fullFormulaRecalcEnabled is off (see recalculateAfterEdit).
    //
    // Tradeoff (accepted): this only updates the cell you just edited. Any OTHER
    // formula cell elsewhere that references this one will keep showing its
    // previously-computed value until it is itself re-entered -- formulas are no
    // longer "live" across the whole sheet on every edit. SUM/AVERAGE/MIN/MAX
    // still fall back to the full calculatormode_update_main() pass below, since
    // ExcelHelper's excel_sum/average/min/max already scan every literal cell
    // internally to resolve a range regardless of how they're called, so scoping
    // just this call site wouldn't avoid that cost anyway -- only direct
    // reference/arithmetic formulas (e.g. "=O2*2") get the fast path, which is
    // also exactly the case that was observed crashing.
    private func recalculateSingleCell(index: Int, posKey: String) {
        guard index >= 0, index < content.count else { return }
        let raw = content[index]

        guard raw.hasPrefix("=") else {
            removeFormulaEntry(posKey: posKey)
            return
        }

        guard index < locationInExcel.count else { return }
        let excelLoc = locationInExcel[index]
        let formulaText = raw.replacingOccurrences(of: " ", with: "")

        let upper = formulaText.uppercased()
        if upper.hasPrefix("=SUM(") || upper.hasPrefix("=AVERAGE(") || upper.hasPrefix("=MIN(") || upper.hasPrefix("=MAX(") {
            calculatormode_update_main()
            return
        }

        var currentFormula = formulaText.replacingOccurrences(of: "=", with: "")
        for ref in extractCellIndices(from: currentFormula) {
            guard let refIdx = excelLocationIndex(for: ref), refIdx < content.count else { continue }
            var val: String? = nil
            let refContent = content[refIdx]
            if refContent.hasPrefix("="), refIdx < location.count, let k = fLocationIndex(for: location[refIdx]) {
                val = f_calculated[k]
            } else {
                let trimmed = refContent.trimmingCharacters(in: .whitespacesAndNewlines)
                if Double(trimmed) != nil { val = trimmed }
            }
            if let v = val {
                currentFormula = applyValue(formula: currentFormula, ref: ref, value: v)
            }
        }

        var resultStr = "error"
        if let numericValue = Double(currentFormula) {
            resultStr = String(numericValue)
        } else if isReadyToCalculate(expression: currentFormula) {
            let service = ASTCalculationService()
            if service.parseExpression(currentFormula) != nil, let result = try? service.evaluate(currentFormula) {
                resultStr = String(result)
            }
        }

        if let k = fLocationIndex(for: posKey) {
            f_calculated[k] = resultStr
        } else {
            f_location.append(posKey)
            f_location_alphabet.append(excelLoc)
            f_calculated.append(resultStr)
            invalidateFLocationIndexCache()
        }
    }

    @objc func calculatormode_update_main(isFullupdate: Bool = true){
//        if isFullupdate {
            f_calculated.removeAll()
            f_location.removeAll()
            f_location_alphabet.removeAll()
//        } TODO is this needed?
      
        // these are all made of formula records
        var filteredContent: [String] = []
        var filteredLocation: [String] = []
        var filteredLocationInExcel: [String] = []
        var filteredResult: [String] = []
        //oter
        var literalContent: [String] = []
        var literalLocation: [String] = []
        var literalLocationInExcel: [String] = []
        var literalResult: [String] = []

        // Loop through the content array and extract items with "=" prefix
        for (index, item) in content.enumerated() {
            //=100-AQ11
            if item.hasPrefix("=") {
                filteredContent.append(item.replacingOccurrences(of: " ", with: ""))
                filteredLocation.append(location[index])
                filteredLocationInExcel.append(locationInExcel[index])
                filteredResult.append("")
            }
            //42
            if !item.hasPrefix("=") {
                // Trimmed once here so every downstream use of literalContent
                // (including the formula-substitution loop further down)
                // sees the same value -- a stray leading/trailing whitespace
                // character makes Double(item) return nil, which silently
                // skips substituting this cell into any formula that
                // references it, leaving that formula's result stuck at
                // "error" even though the value looks perfectly numeric when
                // displayed. See the matching fix in ViewController.swift.
                let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
                literalContent.append(trimmedItem)
                literalLocation.append(location[index])
                literalLocationInExcel.append(locationInExcel[index])
                if Double(trimmedItem) != nil{
                    literalResult.append(trimmedItem)
                }else{
                    literalResult.append("")
                }
            }
        }
        
        //Delete excel format PI()->pi EXP->e^
        //bug_check
        
        //topology sorting
        //content = ["=B1","10","=SUM(A1:B2)","Jack","=C3"],location["1,1","2,1","3,3","3,1",""]
    
        //Formatting log->LOG
//        content = elsvFormulaExpression(src:content)
        
        
        var tempStr = "sin(PI/4)^2"//"3*(3^-1)"//"sin(PI/3+PI/6)"//"((sin3)^2+(cos3)^2)"//"1/((1-0)/(2-0))"//"((30+3)*23-3)/5-1"//30 3 + 23 3 - *  count the number of
        
        //prevent index corruption. start with long ones. B111,B11,B1...
        let combined = zip(literalLocationInExcel, literalContent).sorted { $0.0.count > $1.0.count }
        
        let sortedCombined = combined.sorted { (a, b) -> Bool in
            if a.0.count != b.0.count {
                return a.0.count > b.0.count
            }
            return a.0 > b.0
        }
        
        //replaceing excelIndex with value if the value alredy exists
        for i in 0..<filteredContent.count {
            //Non Excel Function Expressions
            if !filteredContent[i].hasPrefix("=SUM(") && !filteredContent[i].hasPrefix("=AVERAGE(") && !filteredContent[i].hasPrefix("=MIN(") && !filteredContent[i].hasPrefix("=MAX("){
                for (location, content) in sortedCombined {
                    // Cheap substring pre-check before building/running the regex --
                    // if `location` doesn't appear anywhere in the formula text at
                    // all, "\blocation\b" can't match either, so this only skips
                    // guaranteed no-ops. Without this guard, every formula cell
                    // constructs and runs a full NSRegularExpression against every
                    // literal cell in the sheet (O(formulas * literals) -- 16M+
                    // regex ops on a formula-heavy sheet), which grows memory
                    // unboundedly and can crash on a large sheet.
                    guard filteredContent[i].contains(location) else { continue }
                    let pattern = "\\b\(location)\\b"
                    //replace only perfect match C11 not C1
                    filteredContent[i] = filteredContent[i].replacingOccurrences(
                        of: pattern,
                        with: content,
                        options: .regularExpression
                    )
                }
            }
        }

        let cs = CalculationService()


        // Build dependency graph: which formulas does each formula depend on?
        // Index lookup instead of filteredLocationInExcel.firstIndex(of:) -- that
        // was an O(n) linear scan per cell-ref, making this whole loop O(formulas
        // * refs * n).
        var locationIndexMap: [String: Int] = [:]
        for (idx, loc) in filteredLocationInExcel.enumerated() {
            locationIndexMap[loc] = idx
        }
        var dependencies: [Int: Set<Int>] = [:]
        for i in 0..<filteredContent.count {
            dependencies[i] = Set()
            let cellRefs = extractCellIndices(from: filteredContent[i].replacingOccurrences(of: "=", with: ""))
            for ref in cellRefs {
                if let refIdx = locationIndexMap[ref] {
                    dependencies[i]?.insert(refIdx)
                }
            }
        }
        
        // Calculate in dependency order (topological sort)
        var calculated = Set<Int>()
        var maxIterations = filteredContent.count
        var iteration = 0
        
        while calculated.count < filteredContent.count && iteration < maxIterations {
            iteration += 1
            var madeProgress = false
            
            for i in 0..<filteredContent.count {
                if calculated.contains(i) { continue }
                
                // Check if all dependencies are calculated
                var canCalculate = true
                if let deps = dependencies[i] {
                    for dep in deps {
                        if !calculated.contains(dep) {
                            canCalculate = false
                            break
                        }
                    }
                }
                
                if !canCalculate { continue }
                
                madeProgress = true
                filteredResult[i] = "error"
                
                var currentFormula = filteredContent[i].replacingOccurrences(of: "=", with: "")

                // Same guard as the substitution loop above: applyValue() builds
                // and runs a full NSRegularExpression per call, so calling it
                // unconditionally for every literal/calculated cell against every
                // formula cell is the same O(n*m) regex-per-pair cost -- skip refs
                // that can't possibly match.
                for j in 0..<literalLocationInExcel.count {
                    let val = literalContent[j]
                    if Double(val) != nil, currentFormula.contains(literalLocationInExcel[j]) {
                        currentFormula = applyValue(formula: currentFormula, ref: literalLocationInExcel[j], value: val)
                    }
                }

                for j in 0..<filteredResult.count {
                    if calculated.contains(j), currentFormula.contains(filteredLocationInExcel[j]), let val = Double(filteredResult[j]) {
                        currentFormula = applyValue(formula: currentFormula, ref: filteredLocationInExcel[j], value: String(val))
                    }
                }
                
                // Check if formula has already been fully resolved to a numeric value (e.g., "=B1" -> "1")
                if let numericValue = Double(currentFormula) {
                    filteredResult[i] = String(numericValue)
                } else if currentFormula.contains("SUM(") || currentFormula.contains("AVERAGE(") || currentFormula.contains("MAX(") || currentFormula.contains("MIN(") {
                    let rltstr: String
                    switch currentFormula {
                    case _ where currentFormula.contains("SUM("):
                        rltstr = excel_sum_each(fidx: i, fc: filteredContent, fl: filteredLocation, fle: filteredLocationInExcel, fr: filteredResult, lc: literalContent, ll: literalLocation, lle: literalLocationInExcel, lr: literalResult)
                    case _ where currentFormula.contains("AVERAGE("):
                        rltstr = excel_average_each(fidx: i, fc: filteredContent, fl: filteredLocation, fle: filteredLocationInExcel, fr: filteredResult, lc: literalContent, ll: literalLocation, lle: literalLocationInExcel, lr: literalResult)
                    case _ where currentFormula.contains("MIN("):
                        rltstr = excel_min_each(fidx: i, fc: filteredContent, fl: filteredLocation, fle: filteredLocationInExcel, fr: filteredResult, lc: literalContent, ll: literalLocation, lle: literalLocationInExcel, lr: literalResult)
                    case _ where currentFormula.contains("MAX("):
                        rltstr = excel_max_each(fidx: i, fc: filteredContent, fl: filteredLocation, fle: filteredLocationInExcel, fr: filteredResult, lc: literalContent, ll: literalLocation, lle: literalLocationInExcel, lr: literalResult)
                    default:
                        rltstr = "error"
                    }
                    if Double(rltstr) != nil {
                        filteredResult[i] = rltstr
                    }
                } else if isReadyToCalculate(expression: currentFormula) {
                    let service = ASTCalculationService()

                    do {
                        if let ast = service.parseExpression(currentFormula) {
                            print("Parsed successfully!")
                            let result = try service.evaluate(currentFormula)
                            filteredResult[i] = String(result)
                        }
                    } catch {
                        print("Error evaluating formula:", error)
                        filteredResult[i] = "Error"
                    }
                }
                
                calculated.insert(i)
            }
            
            if !madeProgress { break }
        }

        //update
        f_calculated = filteredResult
        f_location = filteredLocation
        f_location_alphabet = filteredLocationInExcel

        // fLocationIndex(for:)'s cache only rebuilds when f_location.count
        // changes -- editing an existing formula cell (replace one formula
        // with another, same total formula-cell count) reassigns f_location
        // to an array of the same length, so that count check silently
        // passes and cellForItemAt keeps using stale key->index mappings,
        // falling back to displaying the raw "=..." text instead of
        // f_calculated's value. Same bug class as the already-fixed
        // locationIndex staleness -- force a hard invalidation here instead
        // of relying on the count heuristic for this specific array, since
        // this function is the only place f_location gets reassigned.
        invalidateFLocationIndexCache()
    }
    
    
    func extractCellIndices(from formula: String) -> [String] {
        // Define the regular expression pattern for cell references
        let pattern = "[A-Z]+[0-9]+"
        
        // Create a regular expression object
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        // Find matches in the input formula
        let matches = regex.matches(in: formula, options: [], range: NSRange(location: 0, length: formula.count))
        
        // Extract the matched strings
        let cellIndices = matches.map { match in
            (formula as NSString).substring(with: match.range)
        }
        
        return cellIndices
    }

    
    func GetExcelColumnName(columnNumber: Int) -> String
    {
        var dividend = columnNumber
        var columnName = ""
        var modulo = 0
        
        while (dividend > 0)
        {
            modulo = (dividend - 1) % 26;
            columnName = String(65 + modulo) + "," + columnName
            dividend = Int((dividend - modulo) / 26)
        }
        
        var alphabetsAry = [String]()
        alphabetsAry = columnName.components(separatedBy: ",")
        
        var fstring = ""
        for i in 0..<alphabetsAry.count {
            let a:Int! = Int(alphabetsAry[i])
            if a != nil{
                let b:UInt8 = UInt8(a)
                fstring.append(String(UnicodeScalar(b)))
            }
            
            
        }
        
        return fstring
    }
    
    func fonteditmode(){
        
        //let IP = IndexPath(row: currentindex.section, section: currentindex.section)
        let IP :String = cursor
        
        if location.index(of: IP) != nil{
            
        }else{
            
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                content.append("")
                location.append(IP)
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
                break
                
            default:
                content.append("")
                location.append(IP)
                textsize.append(String(selectingSize))
                bgcolor.append(selectingBgColor)
                tcolor.append(selectingColor)
                break
            }
            
        }
        
        let i = location.index(of: IP)
        
        if FONTEDIT.hasPrefix("bg="){
            
            let value = FONTEDIT.replacingOccurrences(of: "bg=", with: "").replacingOccurrences(of: " ", with: "")
            //            bgcolor.append(value.replacingOccurrences(of: " ", with: ""))
            
            bgcolor[i!] = value
            //print("bg",bgcolor[i!])
            
            
        }else if FONTEDIT.hasPrefix("color="){
            
            
            let value2 = FONTEDIT.replacingOccurrences(of: "color=", with: "").replacingOccurrences(of: " ", with: "")
            //            tcolor.append(value2.replacingOccurrences(of: " ", with: ""))
            tcolor[i!] = value2
            //print("font",tcolor[i!])
        }
        
        
        myCollectionView.reloadData()
        
        
    }
    
    
    func deleteall(){
        
        datainputview.stringbox.text=""
    }
    
    
    
    
    
    //https://stackoverflow.com/questions/38894031/swift-how-to-detect-orientation-changes
    
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape {
            
            orientaion = "L"
            SCREENSIZE = size.height
            SCREENSIZE_w = size.width
        } else {
            
            orientaion = "P"
            SCREENSIZE = size.height
            SCREENSIZE_w = size.width
        }
    }
    
    
    
    //https://stackoverflow.com/questions/44160111/what-is-the-equivalent-of-string-encoding-utf8-rawvalue-in-objective-c
    func swiftDataToString(someData:Data) -> String? {
        return String(data: someData, encoding: .utf8)
    }
    
    func swiftStringToData(someStr:String) ->Data? {
        return someStr.data(using: .utf8)
    }
    
    
    
    
    
    
    func getNumbers(array : [Double]) -> String {
        let stringArray = array.map{ String($0) }
        return stringArray.joined(separator: " ")
        
    }
    
    
    func cleanArray(InputArray:[String]) -> [String]{
        
        
        
        for i in 0..<InputArray.count {
            
            let tempStr = InputArray[i]
            
            if tempStr.count == 0{

                location[i] = "null"
                invalidateLocationIndexCache()
                content[i] = "null"

            }
            
            
            
        }
        
        
        
        return InputArray
    }
    
    func cleanArray2(InputArray:[String]) -> [String]{
        
        for i in 0..<InputArray.count {
            
            let tempStr = InputArray[i]
            
            
        }
        
        return InputArray
    }
    
    func getIndexlabel() -> String{

        let column = getExcelColumnName(columnNumber: currentindex.item)
        let row = realRow(forDisplaySection: currentindex.section)
        
        label.text = String(column)+String(row)
        
        if currentindex.item == 0{
            label.text = String(row)
        }
        
        if currentindex.section == 0{
            label.text = column
        }
        
        return String(column)+String(row)
    }
    
    func getIndexlabelForExcel(mode:Int=0) -> String{
        let column = getExcelColumnName(columnNumber: currentindex.item)
        let row = realRow(forDisplaySection: currentindex.section)
        switch mode {
        case 0:
            return String(column)+String(row)
        case 1:
            return String(column)
        case 2:
            return String(row)
        default:
            return String(column)+String(row)
        }
    }
    
    
    
    //removeSpecialCharsFrom FinalProduct
    @objc func removeSpecialCharsFromFpString(_ text: String) -> String {
        let okayChars : Set<Character> =
            Set("1234567890-,.")
        return String(text.filter {okayChars.contains($0) })
    }
    
    
    //TextFormatting currency
    
    //FBAction
    func up2dateAction(){
        
        //Font location
        tcolor.removeAll()
        //        tlocation.removeAll()
        textsize.removeAll()
        //        sizelocation.removeAll()
        bgcolor.removeAll()
        //        bglocation.removeAll()
        
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            UIView.animate(withDuration: 0.9) {
                if self.KEYBOARDLOCATION < 1.0{
                    self.KEYBOARDLOCATION = keyboardHeight
                }
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if datainputview != nil{
            if pastemode == false && getRefmode == false{
                terminate()
            }

        }
        settingCellSelected = false
    }

    @objc func appDidBecomeActive() {
        let appd = UIApplication.shared.delegate as! AppDelegate
        if let matchIndex = appd.sheetNameIds.firstIndex(of: String(appd.wsSheetIndex)),
           matchIndex != currentFileNameCollectionViewIdx.item {
            currentFileNameCollectionViewIdx = IndexPath(item: matchIndex, section: 0)
            FileCollectionView.reloadData()
        }
    }

    @objc func moveDown(){
        down_bool = !down_bool
        up_bool = false
        right_bool = false
        left_bool = false
        datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        if down_bool {
            datainputview.downArrow.setImage(UIImage(named: "downArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
            var str = ""
            str = datainputview.stringbox.text.replacingOccurrences(of: ";", with: ":")
            datainputview.stringbox.text = str.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "←", with: "").replacingOccurrences(of: "↑", with: "") + "↓"
        }else if !down_bool{
            datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "↓", with: "")
        }
        
    }
    @objc func imoveDown(){
        down_bool = !down_bool
        up_bool = false
        right_bool = false
        left_bool = false
        datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        if down_bool {
            datainputview.downArrow.setImage(UIImage(named: "downArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
            var str = ""
            str = datainputview.stringbox.text.replacingOccurrences(of: ";", with: ":")
            datainputview.stringbox.text = str.replacingOccurrences(of: "→", with: "").replacingOccurrences(of: "←", with: "").replacingOccurrences(of: "↑", with: "") + "↓"
        }else if !down_bool{
            datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "↓", with: "")
        }
        
    }
    @objc func moveRight(){
        right_bool = !right_bool
        down_bool = false
        up_bool = false
        left_bool = false
        datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        if right_bool {
            datainputview.rightArrow.setImage(UIImage(named: "rightArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
            var str = ""
            str = datainputview.stringbox.text.replacingOccurrences(of: ";", with: ":")
            datainputview.stringbox.text = str.replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "←", with: "").replacingOccurrences(of: "↑", with: "") + "→"
        }else if !right_bool{
            datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "→", with: "")
        }
        
    }
    @objc func imoveRight(){
        right_bool = !right_bool
        down_bool = false
        up_bool = false
        left_bool = false
        datainputview.downArrow.setImage(UIImage(named: "downArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        if right_bool {
            datainputview.rightArrow.setImage(UIImage(named: "rightArwRed")?.withRenderingMode(.alwaysOriginal), for: .normal)
            var str = ""
            str = datainputview.stringbox.text.replacingOccurrences(of: ";", with: ":")
            datainputview.stringbox.text = str.replacingOccurrences(of: "↓", with: "").replacingOccurrences(of: "←", with: "").replacingOccurrences(of: "↑", with: "") + "→"
        }else if !right_bool{
            datainputview.rightArrow.setImage(UIImage(named: "rightArwWhite")?.withRenderingMode(.alwaysOriginal), for: .normal)
            let str = datainputview.stringbox.text
            datainputview.stringbox.text = str!.replacingOccurrences(of: "→", with: "")
        }
        
    }
    func isExcelSheetData(sheetIdx:Int)->Bool{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate

        // location/content/etc. below get fully replaced with a different sheet's
        // data -- the render-index caches key on these by count, which can't tell
        // that apart from "unchanged" when the new sheet has the same cell count.
        invalidateAllRenderIndexCaches()

        //localFileNames = ["sheet1"]
        
        //excel senario
        if isExcel && sheetIdx != -1{
            let sheet1Json = ReadWriteJSON()
            localFileNames = appd.sheetNameIds.map { "sheet\($0)" }
            print("sheetIdx",sheetIdx)
            if localFileNames.count > 0 {
                sheet1Json.readJsonFile(title:"sheet" + String(sheetIdx) + ".xml" )
                content = sheet1Json.content
                location = sheet1Json.location
                textsize = sheet1Json.fontsize
                bgcolor = sheet1Json.bgcolor
                tcolor = sheet1Json.fontcolor
                cellStyleId = sheet1Json.styleId
                COLUMNSIZE = sheet1Json.columnsize
                ROWSIZE = sheet1Json.rowsize
                appd.customSizedWidth = sheet1Json.customcellWidth
                appd.customSizedHeight = sheet1Json.customcellHeight
                appd.cswLocation = sheet1Json.ccwLocation
                appd.cshLocation = sheet1Json.cchLocation
                return true
            }
            
            //the workbook is corrupted?
//            if localFileNames.count > 0 && sheet1Json.readJsonFile(title: "sheet" + String(appd.wsIndex)){
//                content = sheet1Json.content
//                location = sheet1Json.location
//                textsize = sheet1Json.fontsize
//                bgcolor = sheet1Json.bgcolor
//                tcolor = sheet1Json.fontcolor
//                COLUMNSIZE = sheet1Json.columnsize
//                ROWSIZE = sheet1Json.rowsize
//                appd.customSizedWidth = sheet1Json.customcellWidth
//                appd.customSizedHeight = sheet1Json.customcellHeight
//                appd.cswLocation = sheet1Json.ccwLocation
//                appd.cshLocation = sheet1Json.cchLocation
//                return true
//            }
//            
//            //
//            if localFileNames.count > 0 && !sheet1Json.readJsonFile(title: "sheet" + String(appd.wsIndex)){
//                print("something went wrong. maybe corrupt file.")
//            }
        }else{
            isExcel = false
            let sheet1Json = ReadWriteJSON()
            if sheet1Json.readJsonFile(title: "csv_sheet1"){
                content = sheet1Json.content
                location = sheet1Json.location
                textsize = sheet1Json.fontsize
                bgcolor = sheet1Json.bgcolor
                tcolor = sheet1Json.fontcolor
                COLUMNSIZE = sheet1Json.columnsize
                ROWSIZE = sheet1Json.rowsize
                // CustomCollectionViewLayout.prepare() derives its render grid's
                // row/column count from appd.numberofRow/numberofColumn (and
                // NEWRsize/NEWCsize in UserDefaults) as a floor over its own
                // 1001/201 defaults -- every xlsx import path sets these two
                // appd properties at load time, but nothing in the CSV path did,
                // so a CSV's real (large) ROWSIZE/COLUMNSIZE never reached the
                // layout and every CSV silently rendered capped at the default
                // 1001-row grid regardless of the file's actual size.
                appd.numberofRow = ROWSIZE
                appd.numberofColumn = COLUMNSIZE
                // appd.diff_start_index/diff_end_index (CustomCollectionViewLayout's
                // merge-cell ranges) are only ever reset inside ExcelHelper.readExcel2,
                // which is xlsx-only and never runs for CSV -- so opening a CSV right
                // after an xlsx with merged cells left those merge ranges in appd and
                // CustomCollectionViewLayout kept drawing the previous file's merges on
                // top of the CSV grid. CSV has no concept of merged cells at all, so
                // always clear both on CSV load. Confirmed via PERF
                // CustomCollectionViewLayout.prepare's merged=41 persisting straight
                // through a CSV load right after a 41-merge xlsx file.
                appd.diff_start_index.removeAll()
                appd.diff_end_index.removeAll()
                // Same stale-state shape as the merge-cell fix above: f_location/
                // f_calculated/f_location_alphabet are only ever populated OR
                // cleared inside calculatormode_update_main(), which is skipped
                // entirely for CSV (if !isCSV). So switching from an xlsx with
                // formulas straight to a CSV left these full of the xlsx's
                // formula results -- cellForItemAt's fLocationIndex(for:) lookup
                // would still match against that stale data for any CSV cell
                // whose key happens to coincide with a leftover formula location,
                // silently showing the old file's calculated value instead of the
                // CSV's real content. CSV has no formula engine at all, so these
                // must always be empty for CSV.
                f_location.removeAll()
                f_location_alphabet.removeAll()
                f_calculated.removeAll()
                // (invalidateAllRenderIndexCaches() already ran at the top of this
                // function, so fLocationIndexCache is already invalidated here too.)
                perfLog("PERF isExcelSheetData.csvBranch ROWSIZE=\(ROWSIZE) COLUMNSIZE=\(COLUMNSIZE) content=\(content.count) location=\(location.count)")
                appd.customSizedWidth = sheet1Json.customcellWidth
                appd.customSizedHeight = sheet1Json.customcellHeight
                appd.cswLocation = sheet1Json.ccwLocation
                appd.cshLocation = sheet1Json.cchLocation
                return false
            }
        }
        return false
    }
    
    // skipRescan: true for the post-edit fast path (patchJsonCacheAndRefresh).
    // A single storeInput() call already keeps content/location clean and
    // formula-syntax-transformed incrementally for the one cell that changed
    // (see transformFormulaSyntax's call sites in storeInput, and storeInput's
    // "clear" branch which removes an emptied cell directly) -- so re-running
    // excel_fomula_transformation/filterEmptyContent's whole-array O(n) scans
    // here finds nothing to do on a real edit, just costs ~3.5s at 1.4M cells
    // doing it. Left false (i.e. still runs) for loadExcelSheet's call, which
    // is the genuine full-load path: content there just came straight from a
    // raw XML/JSON read that storeInput never touched, and still needs both
    // passes once.
    func initSheetData(skipRescan: Bool = false){
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //EXCEL FORMULA TRANSFORMATION STARTS
        //PI(),EXP(1)
        // CSV mode never runs the formula engine (calculatormode_update_main is
        // already skipped for isCSV), so rewriting Excel function syntax here is
        // pure wasted work scanning every cell for CSV specifically.
        let __formulaTransformStart = CFAbsoluteTimeGetCurrent()
        if !isCSV && !skipRescan {
            content = excel_fomula_transformation(src:content)
        }
        perfLog(String(format: "PERF initSheetData.formulaTransform: %.3fs isCSV=%@ skipRescan=%@", CFAbsoluteTimeGetCurrent() - __formulaTransformStart, isCSV ? "true" : "false", skipRescan ? "true" : "false"))

        //Taking out Empty Cells
        // storeInput() already removes a cell from content/location directly the
        // moment it's cleared to empty, and parseCSVFile never adds an empty
        // entry in the first place (skips blank fields when parsing) -- so for
        // CSV mode, content/location are already guaranteed clean by
        // construction, and this full O(n) re-scan finds nothing to remove.
        // Confirmed via instrumentation: ~3.5s at 1.4M cells, running redundantly
        // on every single edit. xlsx mode doesn't have that guarantee at load
        // time (content can come from a raw JSON/xlsx read), so it still
        // filters normally there -- just not on the skipRescan fast path.
        let __filterEmptyStart = CFAbsoluteTimeGetCurrent()
        if !isCSV && !skipRescan {
            filterEmptyContent()
        }
        perfLog(String(format: "PERF initSheetData.filterEmptyContent: %.3fs isCSV=%@ skipRescan=%@ content=%d", CFAbsoluteTimeGetCurrent() - __filterEmptyStart, isCSV ? "true" : "false", skipRescan ? "true" : "false", content.count))

        //SOME THING WENT WRONG RESET PROCESS STARTS
        if location.count != content.count {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            location.removeAll()
            content.removeAll()
            
            bgcolor.removeAll()
            cursor = String()
            tcolor.removeAll()
            textsize.removeAll()
            
            initString()
        }
        
        if location.count != bgcolor.count || location.count != tcolor.count || location.count != textsize.count{
            bgcolor.removeAll()
            textsize.removeAll()
            tcolor.removeAll()
            
            
            
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                for _ in 0..<location.count{
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                }
                break
                
            default:
                for _ in 0..<location.count{
                    textsize.append(String(selectingSize))
                    bgcolor.append(selectingBgColor)
                    tcolor.append(selectingColor)
                }
                break
            }
        }
        
        //FOR COLLECTIONVIEW
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") != nil) {
            appd.customSizedWidth = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") != nil) {
            appd.customSizedHeight = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") != nil) {
            appd.cswLocation = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") != nil) {
            appd.cshLocation = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") as! Array
        }
        
        // NEWCsize/NEWRsize hold whatever COLUMNSIZE/ROWSIZE happened to be at
        // the time of some earlier edit (saveuserD() persists them on every
        // edit, for any file), not a real per-file preference -- for CSV mode,
        // isExcelSheetData() just correctly computed COLUMNSIZE/ROWSIZE from
        // *this* file's actual parsed extent, and blindly overwriting that with
        // a stale value left over from a previous, unrelated (often much
        // smaller) file silently made most of a large CSV's rows/columns
        // unreachable in the grid. Confirmed via instrumentation: gridCells
        // stuck at exactly DEFAULT_ROW_NUMBER * DEFAULT_COLUMN_NUMBER (201201)
        // regardless of the CSV's real ~1.4M-cell extent. xlsx mode's existing
        // behavior here is left unchanged.
        if !isCSV {
            if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
                COLUMNSIZE = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
            }

            if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
                ROWSIZE = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
            }
        }




        // saveAsLocalJson() itself starts with another filterEmptyContent() call
        // -- if localFileNames is empty (as it very likely is for CSV mode,
        // since it's built from appd.sheetNames, an xlsx-workbook concept),
        // filterEmptyContent's full O(n) scan runs a second time here, on top
        // of the one a few lines up in this same function, on every edit.
        perfLog(String(format: "PERF initSheetData.localFileNamesCheck localFileNames.count=%d", localFileNames.count))
        if localFileNames.count == 0 {
            let __redundantSaveStart = CFAbsoluteTimeGetCurrent()
            let newfile = "csv_sheet1"
            saveAsLocalJson(filename: newfile)
            perfLog(String(format: "PERF initSheetData.redundantSaveAsLocalJson: %.3fs", CFAbsoluteTimeGetCurrent() - __redundantSaveStart))
        }

    }
    
    // Single-cell core of excel_fomula_transformation below -- also called
    // directly from storeInput so a freshly-typed cell is transformed
    // immediately, instead of relying on initSheetData's whole-array pass to
    // catch it on the next refresh (see initSheetData's skipRescan parameter).
    private func transformFormulaSyntax(_ s: String) -> String {
        var result = s
        if result.contains("EXP") {
            result = result.replacingOccurrences(of: "EXP", with: "e^")
        }
        if result.contains("PI()") {
            result = result.replacingOccurrences(of: "PI()", with: "pi")
        }
        return result
    }

    //=EXP(A1) -> e^(A1), COMPLEX(x,y)
    //https://stackoverflow.com/questions/43012632/how-to-succinctly-get-the-first-5-characters-of-a-string-in-swift
    func excel_fomula_transformation(src:[String])->[String]{
        var ary = src
        for i in 0..<ary.count {
            ary[i] = transformFormulaSyntax(ary[i])
        }

        return ary
    }
    
    func getExcelColumnName(columnNumber: Int) -> String
    {
        // Same math as before (repeated base-26 division), but appends the
        // character directly instead of building a comma-joined ASCII-code
        // string and then re-splitting/re-parsing it back into characters --
        // called once per cell (1.4M+ times on a large sheet), so the round
        // trip's extra allocations added up.
        var dividend = columnNumber
        var columnName = ""

        while (dividend > 0)
        {
            let modulo = (dividend - 1) % 26
            columnName = String(UnicodeScalar(UInt8(65 + modulo))) + columnName
            dividend = (dividend - modulo) / 26
        }

        return columnName
    }

    @objc func close(){
        changeaffected.removeAll()
//        if selectedSheet >= 0{
        if selectedSheet >= localFileNames.startIndex && selectedSheet < localFileNames.endIndex{
            saveAsLocalJson(filename: "csv_sheet1")//localFileNames[selectedSheet])
        }
        self.customview3.removeFromSuperview()
    }
    
    //sendEmail
    @objc func excelEmail() {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let alert = UIAlertController(title: "File Export via Email", message: "Name the xlsx file", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = appd.excelfilename.isEmpty ? "XLSV Backup File" :appd.excelfilename
            textField.text = appd.excelfilename.isEmpty ? "XLSV_Backup_File" :appd.excelfilename

            textField.clearButtonMode = .whileEditing
        }
    
        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak self, weak alert] _ in
            guard let fileName = alert?.textFields?.first?.text, !fileName.isEmpty else {
                return
            }
            
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.excelfilename = fileName
            self?.proceedToEmail()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }

    func proceedToEmail() {
        isMail = true

        // flushPendingXlsxChangesIfNeeded/writeXlsxEmail/csvexport below can
        // take real time on a large file -- showLoading()/hideLoading() give
        // the user feedback (doesn't make the export itself faster); the
        // DispatchQueue.main.async hop gives the spinner one runloop turn to
        // actually paint before the synchronous work blocks the main thread
        // (same pattern as applyRowFilters()/HomeController's overlay).
        showLoading()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Explicit export/share action reading straight off disk below --
            // must see any not-yet-flushed edits first (see PendingXlsxChangeSet.swift).
            self.flushPendingXlsxChangesIfNeeded()

            let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            //excel file creation
            let url = serviceInstance.writeXlsxEmail(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path)

            //save temp content
            var result = self.content
            for idx in 0..<self.f_calculated.count{
                if let l_idx = self.location.index(of: self.f_location[idx]){
                    result[l_idx] = self.f_calculated[idx]
                }
            }
            self.csvexport(result: result)

            self.hideLoading()

            if MFMailComposeViewController.canSendMail() {
                let today: Date = Date()
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy HH-mm-ss"
                var date = dateFormatter.string(from: today)

                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self

                mail.setSubject("from ios")

                //creating backup file name

                var fileName = date + "_XLSV_"
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                if appd.excelfilename != ""{
                    fileName = fileName + appd.excelfilename
                    fileName = fileName.removingPercentEncoding!
                    if !fileName.hasSuffix(".xlsx"){
                        fileName += ".xlsx"
                    }
                }


                //print("ViewController" ,filePath)
                if self.isExcel, let url2 = url, let fileData = NSData(contentsOfFile: url2.path) {
                    mail.addAttachmentData(fileData as Data, mimeType: " application/vnd.openxmlformats-officedocument.spreadsheet", fileName: fileName)
                }else{
                    print("noContent")
                }

                //csv
                mail.addAttachmentData(self.data!, mimeType: "text/csv", fileName: date + ".csv")

                self.present(mail, animated: true, completion: nil)

                self.isMail = false
            } else {
                // show failure alert
            }
        }
    }


    @objc func filesave() {
        let alert = UIAlertController(
            title: "Save Backup",
            message: "Enter a file name",
            preferredStyle: .alert
        )
        
        // Add text field
        alert.addTextField { textField in
            textField.placeholder = "e.g. backup.xlsx"
        }
        
        // Save action
        // [weak self, weak alert] -- capturing `alert` itself (to read its own text
        // field) inside a closure that `alert` also owns (via addAction) is a
        // self-contained retain cycle: alert -> saveAction -> this closure -> alert.
        // That cycle needs no external reference to persist, so it never breaks on
        // its own even after the alert is dismissed -- and since this closure also
        // captures self, self stays trapped in it forever too.
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let fileName = alert?.textFields?.first?.text ?? ""

            if fileName.isEmpty {
                self.showResultAlert(title: "Invalid Name", message: "Please enter a file name.")
                return
            }

            // The disk write below (CSV or xlsx) can take real time on a
            // large file -- showLoading()/hideLoading() give the user
            // feedback (doesn't make the write itself faster); the
            // DispatchQueue.main.async hop gives the spinner one runloop
            // turn to actually paint before the synchronous work blocks the
            // main thread (same pattern as applyRowFilters()/proceedToEmail()).
            self.showLoading()
            DispatchQueue.main.async {
                // A CSV-mode sheet has no source .xlsx to hand off to
                // writeXlsxBackup -- write a .csv backup directly from content/
                // location instead, into the same Backups/FileFill directory.
                if self.isCSV {
                    let url = self.writeCsvBackup(filename: fileName)
                    self.hideLoading()
                    if url == nil {
                        self.showResultAlert(title: "Save Failed", message: "Something went wrong while making a backup.")
                    } else {
                        self.showResultAlert(title: "Backup Saved", message: "Your file has been saved successfully.")
                    }
                    return
                }

                // Explicit save action reading straight off disk below -- must see
                // any not-yet-flushed edits first (see PendingXlsxChangeSet.swift).
                self.flushPendingXlsxChangesIfNeeded()

                let serviceInstance = Service(
                    imp_sheetNumber: 0,
                    imp_stringContents: [String](),
                    imp_locations: [String](),
                    imp_idx: [Int](),
                    imp_fileName: "",
                    imp_formula: [String]()
                )

                let appd = UIApplication.shared.delegate as! AppDelegate

                let url = serviceInstance.writeXlsxBackup(
                    fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path,
                    filename: fileName,
                    filenameSuffix: "_ff"
                )

                self.hideLoading()

                if url == nil {
                    self.showResultAlert(title: "Save Failed", message: "Something went wrong while making a backup.")
                } else {
                    self.showResultAlert(title: "Backup Saved", message: "Your file has been saved successfully.")
                }
            }
        }
        
        // Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(saveAction)
        
        self.present(alert, animated: true)
    }

    // Builds a CSV string from content/location (same row/column-walking shape
    // csvexport already uses for the email-attachment path, minus the
    // f_calculated formula-result substitution -- CSV mode never has formulas,
    // see loadExcelSheet's isCSV guard around calculatormode_update_main) and
    // writes it into the same Backups/FileFill directory writeXlsxBackup uses.
    // Manual "Save Backup" only -- takeDailyBackup() is untouched and does not
    // call this.
    private func writeCsvBackup(filename: String) -> URL? {
        var locationIndex: [String: Int] = [:]
        locationIndex.reserveCapacity(location.count)
        for (idx, loc) in location.enumerated() {
            if locationIndex[loc] == nil {
                locationIndex[loc] = idx
            }
        }

        let csvString = NSMutableString()
        for i in (1..<ROWSIZE) {
            for j in (1..<COLUMNSIZE) {
                let path = String(j) + "," + String(i)
                if let k = locationIndex[path] {
                    if content[k].contains(",") {
                        csvString.append(content[k].replacingOccurrences(of: ",", with: "#comma#"))
                    } else if content[k].contains("\n") {
                        // dropped, matching csvexport's own handling
                    } else {
                        csvString.append(content[k])
                    }
                } else {
                    csvString.append("")
                }
                if j != COLUMNSIZE - 1 {
                    csvString.append(",")
                }
            }
            csvString.append("\n")
        }

        guard let data = (csvString as String).data(using: .utf8) else { return nil }
        guard let backupDirURL = ExcelHelper().getBackupDirectory(forFileFill: true) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        let timestamp = formatter.string(from: Date())
        let safeName = filename.replacingOccurrences(of: " ", with: "") == "" ? "backup" : filename
        let backupURL = backupDirURL.appendingPathComponent("\(safeName)_\(timestamp)_ff.csv")

        do {
            if FileManager.default.fileExists(atPath: backupURL.path) {
                try FileManager.default.removeItem(at: backupURL)
            }
            try data.write(to: backupURL, options: .atomic)
            return backupURL
        } catch {
            print("Failed to write CSV backup: \(error.localizedDescription)")
            return nil
        }
    }

    // Helper function to reduce duplication
    func showResultAlert(title: String, message: String) {
        let resultAlert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        resultAlert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(resultAlert, animated: true)
    }
    
    
    @objc func takeDailyBackup(msg:String = "") {
        //make a backup
        let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //excel backups
        let url = serviceInstance.writeXlsxBackup(fp: appd.imported_xlsx_file_path.isEmpty ? "" : appd.imported_xlsx_file_path,isAutoSave: true,msg: msg,filenameSuffix: "_ff")
        
        
    }
    
    func uploadFileToICloud(url: URL,filename: String) {
        // Explicit export/share action copying straight off disk below -- must
        // see any not-yet-flushed edits first (see PendingXlsxChangeSet.swift).
        flushPendingXlsxChangesIfNeeded()

        let fileManager = FileManager.default

        if let containerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            if !FileManager.default.fileExists(atPath: containerUrl.path, isDirectory: nil) {
                do {
                    //create directory
                    try FileManager.default.createDirectory(at: containerUrl, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print(error.localizedDescription)
                }
            }
            
            let fileUrl = containerUrl.appendingPathComponent(filename.replacingOccurrences(of: ".xlsx", with: "") + ".xlsx")
            do {
                // Check if the file already exists in iCloud and remove it if it does
                if fileManager.fileExists(atPath: fileUrl.path) {
                    try fileManager.removeItem(at: fileUrl)
                }
                
                // Copy the file to iCloud Drive
                try fileManager.copyItem(at: url, to: fileUrl)
                
                // Verify the file was successfully copied
                if fileManager.fileExists(atPath: fileUrl.path) {
                    print("File verified to exist in iCloud Drive at: \(fileUrl.path)")
                } else {
                    print("File could not be verified in iCloud Drive")
                }
            } catch {
                print("Error uploading file to iCloud Drive: \(error.localizedDescription)")
            }
           
        }
    }
    
    func uploadFileToICloudCSV(filename: String) {
        let fileManager = FileManager.default
        
        // Get the path to the local file
        let pathDirectory = getRootDocumentsDirectory()
        let filePath = pathDirectory.appendingPathComponent("importedCSV").appendingPathComponent("tempCSV.csv")
        
        guard fileManager.fileExists(atPath: filePath.path) else {
            print("Local file does not exist at: \(filePath.path)")
            return
        }
        
        guard let containerUrl = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            print("iCloud container URL is not available.")
            return
        }
        
        let fileUrl = containerUrl.appendingPathComponent(filename.replacingOccurrences(of: ".csv", with: "") + ".csv")
        
        do {
            // Remove the file in iCloud if it already exists
            if fileManager.fileExists(atPath: fileUrl.path) {
                try fileManager.removeItem(at: fileUrl)
                print("Existing file in iCloud removed at: \(fileUrl.path)")
            }
            
            // Copy the file to iCloud Drive
            try fileManager.copyItem(at: filePath, to: fileUrl)
            print("File successfully uploaded to iCloud Drive at: \(fileUrl.path)")
            
        } catch {
            print("Error during file upload to iCloud: \(error.localizedDescription)")
        }
    }
    
    
    @IBAction func elsxExportAction(_ sender: Any) {
        readAllJsonFiles()
        createxlsxSheet()
        sleep(4)
        excelEmail()
        
    }
    
    func readAllJsonFiles(){
        
        for i in 0..<localFileNames.count {
            
            //FileNameCollectionview Change Page
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appd.collectionViewCellSizeChanged = 1
            appd.cswLocation.removeAll()
            appd.customSizedWidth.removeAll()
            appd.cshLocation.removeAll()
            appd.customSizedHeight.removeAll()
            
            
            f_calculated.removeAll()
            f_content.removeAll()
            content.removeAll()
            location.removeAll()
            f_location_alphabet.removeAll()
            
            //print("sheet changed",indexPath.item)
            selectedSheet = i
            stringboxText = ""
            
            
            initSheetData()
            //
            FileCollectionView.reloadData()
            //
            
            calcPrep()
            if !isCSV {
                calculatormode_update_main()
            }

            DispatchQueue.main.async() {
                appd.collectionViewCellSizeChanged = 1
                self.myCollectionView.collectionViewLayout.invalidateLayout()
                self.myCollectionView.reloadData()
            }
        }
    }
    
    
    func rejectCapitalLetters(chaos:String) -> String{
        let capitalLetterRegEx = "[A-Z]"
        let exist = NSPredicate(format: "SELF MATCHES %@", capitalLetterRegEx).evaluate(with: chaos)
        if exist {
            return ""
        }else{
            return chaos
        }
    }
    
    func calcPrep(){
        
        
        for idx in 0..<content.count {
            let checkit = content[idx].replacingOccurrences(of: "¥", with: "").replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "€", with: "")
            if Double(checkit) != nil{
                
                
                let number = location[idx].components(separatedBy: ",")[0]
                let number2 = location[idx].components(separatedBy: ",")[1]
                let intnumber = Int(number)
                let alphabets = getExcelColumnName(columnNumber: intnumber!)
                let each = String(alphabets + number2)//no need ","
                
            }
        }
    }
    
    func numberOnlyString(text: String) -> String {
        let okayChars = Set("1234567890")
        return text.filter {okayChars.contains($0) }
    }
    
    
    func excelFormulaExpression(src:String)->String{
        var formatted = src
        formatted = formatted.replacingOccurrences(of: "sqrt", with: "SQRT")
        formatted = formatted.replacingOccurrences(of: "logd", with: "LOG10")
        formatted = formatted.replacingOccurrences(of: "log", with: "LOG")
        formatted = formatted.replacingOccurrences(of: "pi", with: "PI()")
        formatted = formatted.replacingOccurrences(of: "e^", with: "EXP")
        return formatted
    }
    
    func elsvFormulaExpression(src:[String])->[String]{
        var formatted = src
        for i in 0..<formatted.count{
            formatted[i] = formatted[i].replacingOccurrences(of: "SQRT", with: "sqrt")
            formatted[i] = formatted[i].replacingOccurrences(of: "LOG10", with: "log10")
            formatted[i] = formatted[i].replacingOccurrences(of: "LOG", with: "log")
            formatted[i] = formatted[i].replacingOccurrences(of: "PI()", with: "pi")
            formatted[i] = formatted[i].replacingOccurrences(of: "EXP", with: "exp^")
        }
        
        return formatted
    }
    
    @objc func sinAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=sin("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "sin("
        }
    }
    
    @objc func asinAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=asin("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "asin("
        }
    }
    
    @objc func cosAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=cos("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "cos("
        }
    }
    
    @objc func acosAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=acos("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "acos("
        }
    }
    
    @objc func tanAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=tan("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "tan("
        }
    }
    
    @objc func atanAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=atan("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "atan("
        }
    }
    
    @objc func logdAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=log10("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "log10("
        }
    }
    
    @objc func lnAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=log("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "log("
        }
    }
    
    @objc func expAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=e"
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "e"
        }
    }
    
    @objc func powAction(){
        
        datainputview.stringbox.text = datainputview.stringbox.text + "^"
        
    }
    
    @objc func piAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=pi"
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "pi"
        }
    }
    
    @objc func plusmarkAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "+"
        }
    }
    
    @objc func crossAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "*"
        }
    }
    
    @objc func openBraceAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "=("
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + "("
        }
    }
    
    @objc func closeBraceAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + ")"
        }
    }
    
    @objc func commaAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + ","
        }
    }
    
    @objc func colonAction(){
        let check = datainputview.stringbox.text.replacingOccurrences(of: " ", with: "")
        if check.count == 0  {
            datainputview.stringbox.text = "="
        }else{
            datainputview.stringbox.text = datainputview.stringbox.text + ":"
        }
    }
    
    
    
    @objc func hwAction(){
        let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "HandwritingView")

        targetViewController.modalPresentationStyle = .overCurrentContext
        targetViewController.view.backgroundColor = UIColor.clear

        self.present(targetViewController, animated: true, completion: nil)

    }

    @objc func speechAction(){
        speechInputHelper.toggle(onResult: { [weak self] text in
            self?.datainputview?.stringbox.text = text
        }, onStateChange: { [weak self] isRecording in
            self?.datainputview?.speechButton.tintColor = isRecording ? .systemRed : nil
        })
    }

    @objc func barcodeAction(){
        #if !targetEnvironment(macCatalyst)
            let targetViewController = self.storyboard!.instantiateViewController(withIdentifier: "BarcodeView")

            targetViewController.modalPresentationStyle = .overCurrentContext
            targetViewController.view.backgroundColor = UIColor.clear

            self.present(targetViewController, animated: true, completion: nil)
        #endif

    }
    
    func isNumeric(_ str: String) -> Bool {
        // Check if the string is empty
        guard !str.isEmpty else {
            return false
        }
        
        // Define a character set containing decimal digits and the decimal point
        var decimalDigits = CharacterSet.decimalDigits
        decimalDigits.insert(".")
        
        // Check if the string contains only characters from the decimalDigits set
        return str.rangeOfCharacter(from: decimalDigits.inverted) == nil
    }

}
