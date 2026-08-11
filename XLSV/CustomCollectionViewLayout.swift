import UIKit

class CustomCollectionViewLayout: UICollectionViewLayout {

    // Used for calculating each cells CGRect on screen.
    // CGRect will define the Origin and Size of the cell.
    var CELL_HEIGHT = 30.0
    var CELL_WIDTH = 120.0
    var INDEX_WIDTH = 50.0
    var INDEX_HEIGHT = 30.0

    let STATUS_BAR = UIApplication.shared.statusBarFrame.height
    var each_width = [Double]()
    var each_height = [Double]()
    var contenssizeX = 0.0
    var contenssizeY = 0.0
    var xPOS = [Double]()
    var yPOS = [Double]()
    var xPos = 0.0
    var yPos = 0.0


    //
    var presentIndex = [String]()
    // Dictionary to hold the UICollectionViewLayoutAttributes for
    // each cell. The layout attribtues will define the cell's size
    // and position (x, y, and z index). I have found this process
    // to be one of the heavier parts of the layout. I recommend
    // holding onto this data after it has been calculated in either
    // a dictionary or data store of some kind for a smooth performance.
    //
    // Only ever holds header cells (row 0 and column 0) PLUS, for grids at or
    // below lazyInteriorCellsThreshold, every interior cell too -- see prepare().
    // For larger grids, interior cells are intentionally left out of this
    // dictionary and computed on demand instead (interiorCellAttributes(row:col:)),
    // since materializing one UICollectionViewLayoutAttributes object per cell for
    // the full rows*columns grid (a 100,000-row x 201-column load-test file is
    // ~20.1M cells) is what caused the app to hang/balloon in memory on large
    // files -- see /Users/yano/.claude/plans/wise-prancing-firefly.md and this
    // session's follow-up discussion for the investigation.
    var cellAttrsDictionary = Dictionary<IndexPath, UICollectionViewLayoutAttributes>()

    // Defines the size of the area the user can move around in
    // within the collection view.
    var contentSize = CGSize.zero

    // Used to determine if a data source update has occured.
    // Note: The data source would be responsible for updating
    // this value if an update was performed.
    var dataSourceDidUpdate = true

    var goodByeArray = [String]()
    var merged = [String]()
    var c = Int()
    var r = Int()

    // Above this many total cells (rows*columns), prepare() stops eagerly
    // materializing interior (non-header) cell attributes and switches
    // layoutAttributesForItem(at:)/layoutAttributesForElements(in:) over to
    // computing them on demand instead -- see interiorCellAttributes(row:col:)
    // and the lazy branch in layoutAttributesForElements. Comfortably above
    // the default empty grid (DEFAULT_ROW_NUMBER=1001 * DEFAULT_COLUMN_NUMBER=201
    // = 201,201) and any ordinary user file, so normal usage stays on the
    // original, already-verified eager path with zero behavior change.
    private let lazyInteriorCellsThreshold = 1_000_000
    private var lazyInteriorCells = false

    private struct MergeSpan {
        let endCol: Int
        let endRow: Int
    }
    // Anchor-cell lookup used ONLY by the lazy (large-grid) path -- kept
    // entirely separate from the eager path's own merge-patch loop below so a
    // bug in this newer, less-tested code can't affect the eager path's
    // already-verified behavior. Keyed by IndexPath(item: col, section: row)
    // of the merge's anchor cell.
    private var mergedAnchors: [IndexPath: MergeSpan] = [:]

    override var collectionViewContentSize : CGSize {


        return self.contentSize
    }

    override func prepare() {
        let __prepareStart = CFAbsoluteTimeGetCurrent()
        var __tookFullRebuildPath = false
        defer {
            let __elapsed = CFAbsoluteTimeGetCurrent() - __prepareStart
            print(String(format: "PERF CustomCollectionViewLayout.prepare: %.3fs (fullRebuild=%@, gridCells=%d, merged=%d, lazy=%@)", __elapsed, "\(__tookFullRebuildPath)", c*r, merged.count, "\(lazyInteriorCells)"))
        }

        var excel_cell_width_margin = 30

        if (UserDefaults.standard.object(forKey: "cellSize") != nil) {
            let size = UserDefaults.standard.object(forKey: "cellSize") as! Int
            switch size {
            case 0:
            CELL_HEIGHT = 20.0
            CELL_WIDTH = 30.0
            INDEX_WIDTH = 20.0
            INDEX_HEIGHT = 20.0
            excel_cell_width_margin = 10
                break
                    case 1:
                        CELL_HEIGHT = 20.0
                        CELL_WIDTH = 40.0
                        INDEX_WIDTH = 30.0
                        INDEX_HEIGHT = 30.0
                        excel_cell_width_margin = 20
                break
                case 2:
                CELL_HEIGHT = 30.0
                CELL_WIDTH = 70.0
                INDEX_WIDTH = 30.0
                INDEX_HEIGHT = 30.0
                excel_cell_width_margin = 30
            break
            case 3:
                CELL_HEIGHT = 30.0
                CELL_WIDTH = 120.0
                INDEX_WIDTH = 30.0
                INDEX_HEIGHT = 30.0
                excel_cell_width_margin = 30
            break
            case 4:
                CELL_HEIGHT = 40.0
                CELL_WIDTH = 180.0
                INDEX_WIDTH = 40.0
                INDEX_HEIGHT = 40.0
                excel_cell_width_margin = 40
            break
                    default:
                        break
                    }

        }

        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        merged = appd.diff_start_index //["1,1","5,5"]

        if appd.CELL_WIDTH_EXCEL_GSHEET > 100{
            CELL_WIDTH = appd.CELL_WIDTH_EXCEL_GSHEET
        }

        if (UserDefaults.standard.object(forKey: "GLOBAL_CELL_WIDTH") != nil) {
            CELL_WIDTH = UserDefaults.standard.double(forKey: "GLOBAL_CELL_WIDTH")
            CELL_HEIGHT = UserDefaults.standard.double(forKey: "GLOBAL_CELL_HEIGHT")
            let indexSize = UserDefaults.standard.double(forKey: "GLOBAL_INDEX_SIZE")
            INDEX_WIDTH = indexSize
            INDEX_HEIGHT = indexSize
            excel_cell_width_margin = Int(indexSize)
        }


        if appd.collectionViewCellSizeChanged == 1{
            dataSourceDidUpdate = true
            appd.collectionViewCellSizeChanged = 0
            xPOS.removeAll()
            yPOS.removeAll()
            each_width.removeAll()
            each_height.removeAll()
            xPos = 0.0
            yPos = 0.0
        }

        if dataSourceDidUpdate == true{
        __tookFullRebuildPath = true

        //let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        c = appd.DEFAULT_COLUMN_NUMBER//30
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            let v = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
            if v > c{
                c = v
            }
        }

        r = appd.DEFAULT_ROW_NUMBER
        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
            let v = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
            if v > r{
                r = v
            }
        }

            if appd.numberofColumn > c {
                c = appd.numberofColumn
            }

            if appd.numberofRow > r{
                r = appd.numberofRow
            }


            for _ in 0..<r {
                each_height.append(CELL_HEIGHT)
            }


            for _ in 0..<c {
                each_width.append(CELL_WIDTH)
            }


        each_height[0] = INDEX_HEIGHT
        each_width[0] = INDEX_WIDTH

        yPOS.append(0.0)
        xPOS.append(0.0)

        //read temp when it's count was not 0
        for i in 0..<each_height.count{
            switch appd.cshLocation_temp.count {
            case 0:
                if appd.cshLocation.contains(i){
                    let l = appd.cshLocation.index(of: i)
                    let doubled = Double(appd.customSizedHeight[l!])
                    each_height[i] = doubled
                }
            default:
                if appd.cshLocation_temp.contains(i){
                    let l = appd.cshLocation_temp.index(of: i)
                    let doubled = Double(appd.customSizedHeight_temp[l!])
                    each_height[i] = doubled
                }
            }

            yPos += each_height[i]
            yPOS.append(yPos)
        }

        for j in 0..<each_width.count{
            switch appd.cswLocation_temp.count {
            case 0:
                if appd.cswLocation.contains(j){
                    let l = appd.cswLocation.index(of: j)
                    let doubled = Double(appd.customSizedWidth[l!])
                    each_width[j] = doubled
                }
            default:
                if appd.cswLocation_temp.contains(j){
                    let l = appd.cswLocation_temp.index(of: j)
                    let doubled = Double(appd.customSizedWidth_temp[l!])
                    each_width[j] = doubled
                }
            }

            xPos += each_width[j]
            xPOS.append(xPos)

        }

        // Snap the accumulated positions to the physical pixel grid, then derive
        // each cell's rendered width/height from the difference between two
        // already-snapped positions. Rounding origin and size independently (the
        // previous behavior) could round two adjacent cells' shared edge to two
        // different physical pixels, opening a hairline gap that let the
        // collection view's own background color show through as a thin line
        // between every cell.
        let pixelScale = UIScreen.main.scale
        for i in 0..<yPOS.count {
            yPOS[i] = (yPOS[i] * pixelScale).rounded() / pixelScale
        }
        for i in 0..<each_height.count {
            each_height[i] = yPOS[i + 1] - yPOS[i]
        }
        for j in 0..<xPOS.count {
            xPOS[j] = (xPOS[j] * pixelScale).rounded() / pixelScale
        }
        for j in 0..<each_width.count {
            each_width[j] = xPOS[j + 1] - xPOS[j]
        }

            appd.numberofRow = r
            appd.numberofColumn = c


        }


        // Only update header cells.
        if !dataSourceDidUpdate {
            // Determine current content offsets.
            let xOffset = collectionView!.contentOffset.x
            let yOffset = collectionView!.contentOffset.y

            // Reuse the already-known row/column counts (r, c) instead of querying
            // collectionView.numberOfSections / numberOfItems(inSection:) once per
            // row here. Those calls go through the data source, which re-reads
            // UserDefaults every time (see ViewController.numberOfSections /
            // numberOfItemsInSection) -- for a sheet with hundreds/thousands of
            // rows that made this "cheap" fast path cost nearly as much as a full
            // layout rebuild. r/c are only stale here if dataSourceDidUpdate is
            // true, which is the other branch of this if.
            if r > 0 && c > 0 {

                // Update all items in the first row.
                for item in 0...c-1 {

                    // Build indexPath to get attributes from dictionary.
                    let indexPath = IndexPath(item: item, section: 0)

                    // Update y-position to follow user.
                    if let attrs = cellAttrsDictionary[indexPath] {
                        var frame = attrs.frame

                        // Also update x-position for corner cell.
                        if item == 0 {
                            frame.origin.x = xOffset
                        }

                        frame.origin.y = yOffset
                        attrs.frame = frame
                    }
                }

                // For all other sections, we only need to update
                // the x-position for the first item.
                if r > 1 {
                    if lazyInteriorCells {
                        // r can be 100k+ for large grids -- repositioning every row
                        // header's x on every scroll tick (this fast path runs on
                        // every prepare() call while scrolling) was an O(r)
                        // dictionary-lookup-and-mutate loop per frame regardless of
                        // how many rows are actually visible, and was the dominant
                        // per-frame scroll cost on large files. Bound it to rows near
                        // the current vertical viewport instead, same binary-search
                        // technique already used for interior cells below.
                        let viewHeight = Double(collectionView?.bounds.height ?? 0)
                        let visibleRows = overlappingIndices(yPOS, sizes: each_height, count: r, range: (yOffset, yOffset + viewHeight), pad: 5)
                        for section in visibleRows where section >= 1 {
                            let indexPath = IndexPath(item: 0, section: section)
                            if let attrs = cellAttrsDictionary[indexPath] {
                                var frame = attrs.frame
                                frame.origin.x = xOffset
                                attrs.frame = frame
                            }
                        }
                    } else {
                        for section in 1...r-1 {

                            // Build indexPath to get attributes from dictionary.
                            let indexPath = IndexPath(item: 0, section: section)

                            // Update y-position to follow user.
                            if let attrs = cellAttrsDictionary[indexPath] {
                                var frame = attrs.frame
                                frame.origin.x = xOffset
                                attrs.frame = frame
                            }
                        }
                    }
                }
            }

            // Do not run attribute generation code
            // unless data source has been updated.
            return
        }

        // Acknowledge data source change, and disable for next time.
        dataSourceDidUpdate = false

        lazyInteriorCells = (c > 0 && r > 0) && (c * r) > lazyInteriorCellsThreshold

        cellAttrsDictionary.removeAll(keepingCapacity: true)

        // Header cells (row 0 and column 0) vary along only one dimension each,
        // so lay them out with two O(r)+O(c) loops instead of reaching them
        // inside the O(r*c) nested loop the original single-pass version used --
        // that loop ran r*c times just to touch the ~r+c header cells along the
        // way. Frame/zIndex values here are unchanged from the original: row 0
        // (incl. the (0,0) corner) gets zIndex 5 at the corner / 3 elsewhere;
        // column 0 (row>0) gets zIndex 4.
        if c > 0 {
            for col in 0..<c {
                let cellIndex = IndexPath(item: col, section: 0)
                let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: cellIndex)
                cellAttributes.frame = CGRect(x: xPOS[col], y: yPOS[0], width: each_width[col], height: each_height[0])
                cellAttributes.zIndex = (col == 0) ? 5 : 3
                cellAttrsDictionary[cellIndex] = cellAttributes
            }
        }
        if r > 1 {
            for row in 1..<r {
                let cellIndex = IndexPath(item: 0, section: row)
                let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: cellIndex)
                cellAttributes.frame = CGRect(x: xPOS[0], y: yPOS[row], width: each_width[0], height: each_height[row])
                cellAttributes.zIndex = 4
                cellAttrsDictionary[cellIndex] = cellAttributes
            }
        }

        if lazyInteriorCells {
            // Large grid: don't materialize the O(r*c) interior cells at all --
            // interiorCellAttributes(row:col:) computes them on demand from
            // xPOS/yPOS/each_width/each_height (already O(r+c), computed above)
            // plus mergedAnchors (computed below, O(merge count)).
            mergedAnchors.removeAll(keepingCapacity: true)
            if appd.diff_start_index.count == appd.diff_end_index.count {
                for (idx, start) in appd.diff_start_index.enumerated() {
                    let startCol = getExcelColumnNumber(columnName: alphabetOnlyString(text: start))
                    guard let startRow = Int(numberOnlyString(text: start)),
                          startCol > 0, startCol < c, startRow > 0, startRow < r else { continue }
                    let endColAlpha = alphabetOnlyString(text: appd.diff_end_index[idx])
                    guard let endRow = Int(numberOnlyString(text: appd.diff_end_index[idx])) else { continue }
                    let endCol = getExcelColumnNumber(columnName: endColAlpha)
                    guard endCol >= startCol, endRow >= startRow, endCol < c, endRow < r else { continue }
                    let cellIndex = IndexPath(item: startCol, section: startRow)
                    if mergedAnchors[cellIndex] == nil {
                        mergedAnchors[cellIndex] = MergeSpan(endCol: endCol, endRow: endRow)
                    }
                }
            }
        } else {
            // Original eager path, unchanged: materialize every interior cell,
            // then patch merge-anchor cells over the ordinary frames just written.
            let mergedRangesValid = appd.diff_start_index.count == appd.diff_end_index.count
            var mergedStartIndex: [String: Int] = [:]
            if mergedRangesValid {
                mergedStartIndex.reserveCapacity(appd.diff_start_index.count)
                for (idx, start) in appd.diff_start_index.enumerated() where mergedStartIndex[start] == nil {
                    mergedStartIndex[start] = idx
                }
            }

            if c > 1 && r > 1 {
                for col in 1..<c {
                    for row in 1..<r {
                        let cellIndex = IndexPath(item: col, section: row)
                        let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: cellIndex)
                        cellAttributes.frame = CGRect(x: xPOS[col], y: yPOS[row], width: each_width[col], height: each_height[row])
                        cellAttributes.zIndex = 1
                        cellAttrsDictionary[cellIndex] = cellAttributes
                    }
                }
            }

            // Patch in merge-anchor cells over the ordinary frames the main loop
            // just wrote. mergedStartIndex has one entry per actual merge
            // (appd.diff_start_index.count, typically tiny) regardless of grid
            // size, so this pass is cheap even when the loop above isn't.
            for (start, id) in mergedStartIndex {
                let section = getExcelColumnNumber(columnName: alphabetOnlyString(text: start))
                guard let item = Int(numberOnlyString(text: start)) else { continue }
                // Header row/column cells were already laid out above and must
                // not be overwritten here, matching the original per-cell check
                // order where item == 0 / section == 0 took priority over merges.
                guard section > 0 && section < c, item > 0 && item < r else { continue }

                let cellIndex = IndexPath(item: section, section: item)
                let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: cellIndex)

                let end_column_aphabet_int = alphabetOnlyString(text: appd.diff_end_index[id])
                let end_row_int = Int(numberOnlyString(text: appd.diff_end_index[id]))
                let end_column_int = getExcelColumnNumber(columnName: end_column_aphabet_int)

                if section > end_column_int || item > end_row_int! {
                    print("out of index")
                    cellAttributes.frame = CGRect(x: xPOS[section], y: yPOS[item], width: each_width[section], height: each_height[item])
                    cellAttributes.zIndex = 1
                    cellAttrsDictionary[cellIndex] = cellAttributes
                } else {
                    // Calculate the sum of each_width from section to col_end
                    let sumWidth = (section...end_column_int).reduce(0) { result, i in
                        return result + each_width[i]
                    }

                    // Calculate the sum of each_height from item to row_end
                    let sumHeight = (item...end_row_int!).reduce(0) { result, j in
                        return result + each_height[j]
                    }

                    cellAttributes.frame = CGRect(x: xPOS[section], y: yPOS[item], width: sumWidth, height: sumHeight)

                    //lay it at top of ordinary cells
                    cellAttributes.zIndex = 2

                    cellAttrsDictionary[cellIndex] = cellAttributes
                }
            }
        }

        // Update content size.
        self.contentSize = CGSize(width: xPos, height: yPos)


    }

    // On-demand equivalent of the eager path's interior-cell branch above
    // (ordinary frame, or the merge-anchor's expanded frame) -- only used when
    // lazyInteriorCells is true. row/col are the data row/column (1-based
    // interior, i.e. never the header row/column 0).
    private func interiorCellAttributes(row: Int, col: Int) -> UICollectionViewLayoutAttributes {
        let cellIndex = IndexPath(item: col, section: row)
        let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: cellIndex)
        if let span = mergedAnchors[cellIndex] {
            let sumWidth = (col...span.endCol).reduce(0.0) { $0 + each_width[$1] }
            let sumHeight = (row...span.endRow).reduce(0.0) { $0 + each_height[$1] }
            cellAttributes.frame = CGRect(x: xPOS[col], y: yPOS[row], width: sumWidth, height: sumHeight)
            cellAttributes.zIndex = 2
        } else {
            cellAttributes.frame = CGRect(x: xPOS[col], y: yPOS[row], width: each_width[col], height: each_height[row])
            cellAttributes.zIndex = 1
        }
        return cellAttributes
    }

    // First index i in [lowerBound, positions.count) with positions[i] >= value
    // (a standard partition-point / lower-bound binary search; positions must be
    // non-decreasing, which xPOS/yPOS are by construction). Used to find an
    // approximate starting row/column near a rect's edge in O(log n) instead of
    // scanning from 0.
    private func partitionPoint(_ positions: [Double], from lowerBound: Int, value: Double) -> Int {
        var lo = lowerBound, hi = positions.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if positions[mid] < value {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }

    // Interior (row>=1 or col>=1) indices whose cell span could overlap `range`,
    // found via binary search + a bounded forward walk instead of an O(count)
    // scan. `pad` extra indices are included on both ends so a merge anchor
    // starting just outside the naive visible span (merges are always small,
    // per the eager path's own comments) isn't missed, and the walk stops after
    // `pad` indices past the visible edge regardless -- bounded by
    // (visible span + 2*pad), never by `count`, with a hard cap as a safety
    // valve in case this estimate is ever off for an unforeseen case: a bounded
    // rendering gap beats an unbounded hang.
    private func overlappingIndices(_ positions: [Double], sizes: [Double], count: Int, range: (Double, Double), pad: Int) -> [Int] {
        guard count > 1 else { return [] }
        let hardCap = 4000
        let start = max(1, partitionPoint(positions, from: 1, value: range.0) - 1 - pad)
        var result: [Int] = []
        var i = start
        var overshoot = 0
        while i < count && result.count < hardCap {
            result.append(i)
            if positions[i] >= range.1 {
                overshoot += 1
                if overshoot > pad { break }
            }
            i += 1
        }
        return result
    }

//    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
//
//        // Create an array to hold all elements found in our current view.
//        var attributesInRect = [UICollectionViewLayoutAttributes]()
//
//        // Check each element to see if it should be returned.
//        for cellAttributes in cellAttrsDictionary.values {
//            if rect.intersects(cellAttributes.frame) {
//                attributesInRect.append(cellAttributes)
//            }
//        }
//
//        // Return list of elements.
//        return attributesInRect
//    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesInRect = [UICollectionViewLayoutAttributes]()

        if lazyInteriorCells {
            // cellAttrsDictionary only holds headers here (r+c entries -- see
            // prepare()), but the eager-path loop below force-includes every
            // header regardless of visibility, which for r=100k+ meant
            // returning up to r attributes on every single call -- the
            // dominant per-frame scroll cost on large files. Column headers
            // (row 0) are always cheap (c is never large for real sheets) and
            // stay unconditional, matching prior behavior. Row headers
            // (column 0) are bounded to the visible vertical range, reusing
            // the same binary-search range computed for interior cells below.
            let pad = 5
            let rows = r > 1 ? overlappingIndices(yPOS, sizes: each_height, count: r, range: (Double(rect.minY), Double(rect.maxY)), pad: pad) : []
            let cols = c > 1 ? overlappingIndices(xPOS, sizes: each_width, count: c, range: (Double(rect.minX), Double(rect.maxX)), pad: pad) : []

            if c > 0 {
                for item in 0..<c {
                    if let attrs = cellAttrsDictionary[IndexPath(item: item, section: 0)] {
                        attributesInRect.append(attrs)
                    }
                }
            }
            for row in rows where row >= 1 {
                if let attrs = cellAttrsDictionary[IndexPath(item: 0, section: row)] {
                    attributesInRect.append(attrs)
                }
            }

            // Large grids don't put interior cells in cellAttrsDictionary at all
            // (see prepare()) -- generate the ones actually overlapping `rect`
            // on demand, reusing the same visible rows/cols computed above.
            if r > 1 && c > 1 {
                for row in rows where row >= 1 && row < r {
                    for col in cols where col >= 1 && col < c {
                        let attrs = interiorCellAttributes(row: row, col: col)
                        if rect.intersects(attrs.frame) {
                            attributesInRect.append(attrs)
                        }
                    }
                }
            }
        } else {
            for cellAttributes in cellAttrsDictionary.values {
                // 1. 通常のセルは画面内にあるか判定
                if rect.intersects(cellAttributes.frame) {
                    attributesInRect.append(cellAttributes)
                }
                // 2. 固定ヘッダー（セクション0や1列目など）は強制的に追加するロジックが必要
                else if cellAttributes.indexPath.section == 0 || cellAttributes.indexPath.item == 0 {
                    attributesInRect.append(cellAttributes)
                }
            }
        }

        return attributesInRect
    }


    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attrs = cellAttrsDictionary[indexPath] {
            return attrs
        }
        guard lazyInteriorCells,
              indexPath.section > 0, indexPath.section < r,
              indexPath.item > 0, indexPath.item < c else { return nil }
        return interiorCellAttributes(row: indexPath.section, col: indexPath.item)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {

        return true
    }


    func resetCellAttrsDictionaryItemZindex(){
        for (key, cellAttributes) in cellAttrsDictionary {
            cellAttributes.zIndex = 0
            cellAttrsDictionary[key] = cellAttributes
        }

    }

    func getExcelColumnName(columnNumber: Int) -> String
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

    func getExcelColumnNumber(columnName: String) -> Int {
        var columnNumber = 0

        for character in columnName.uppercased().unicodeScalars {
            columnNumber *= 26
            columnNumber += Int(character.value) - Int(UnicodeScalar("A").value) + 1
        }

        return columnNumber
    }

    func alphabetOnlyString(text: String) -> String {
        let okayChars = Set("ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
        return text.filter {okayChars.contains($0) }
    }

    func numberOnlyString(text: String) -> String {
        let okayChars = Set("1234567890")
        return text.filter {okayChars.contains($0) }
    }

}
