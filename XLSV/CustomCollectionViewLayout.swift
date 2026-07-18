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
    
    override var collectionViewContentSize : CGSize {

       
        return self.contentSize
    }
    
    override func prepare() {
        let __prepareStart = CFAbsoluteTimeGetCurrent()
        var __tookFullRebuildPath = false
        defer {
            let __elapsed = CFAbsoluteTimeGetCurrent() - __prepareStart
            print(String(format: "PERF CustomCollectionViewLayout.prepare: %.3fs (fullRebuild=%@, gridCells=%d, merged=%d)", __elapsed, "\(__tookFullRebuildPath)", c*r, merged.count))
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

            // Do not run attribute generation code
            // unless data source has been updated.
            return
        }
        
        // Acknowledge data source change, and disable for next time.
        dataSourceDidUpdate = false

        // Merged-cell lookup, built once per layout pass instead of scanning
        // appd.diff_start_index for every one of the c*r grid cells below
        // (that made prepare() O(gridCells * mergedCellCount)).
        let mergedRangesValid = appd.diff_start_index.count == appd.diff_end_index.count
        var mergedStartIndex: [String: Int] = [:]
        if mergedRangesValid {
            mergedStartIndex.reserveCapacity(appd.diff_start_index.count)
            for (idx, start) in appd.diff_start_index.enumerated() where mergedStartIndex[start] == nil {
                mergedStartIndex[start] = idx
            }
        }

        // Cycle through each section of the data source.
        if c > 0 {
            for section in 0...c-1 {
                // Cycle through each item in the section.
                if r > 0 {
                    for item in 0...r-1 {
                        
                        // Build the UICollectionVieLayoutAttributes for the cell.
                        let cellIndex = IndexPath(item: section, section: item)// colmn/row
                        let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: cellIndex)

                        if item == 0{
                            //column 0
                            cellAttributes.frame = CGRect(x: xPOS[section], y: yPOS[item], width: each_width[section], height: each_height[item])
                            
                            // Determine zIndex based on cell type.
                            if section == 0 && item == 0 {
                                cellAttributes.zIndex = 5
                            } else if section == 0 {
                                cellAttributes.zIndex = 4
                            } else if item == 0 {
                                cellAttributes.zIndex = 3
                            } else {
                                cellAttributes.zIndex = 1
                            }
                            
                            cellAttrsDictionary[cellIndex] = cellAttributes
                        }else if section == 0{
                            //row 0
                            cellAttributes.frame = CGRect(x: xPOS[section], y: yPOS[item], width: each_width[section], height: each_height[item])
                            
                            // Determine zIndex based on cell type.
                            if section == 0 && item == 0 {
                                cellAttributes.zIndex = 5
                            } else if section == 0 {
                                cellAttributes.zIndex = 4
                            } else if item == 0 {
                                cellAttributes.zIndex = 3
                            } else {
                                cellAttributes.zIndex = 1
                            }
                            
                            cellAttrsDictionary[cellIndex] = cellAttributes
                        }else{
                            //merged cells
                            var EACH_HEIGHT = 0.0
                            var EACH_WIDTH = 0.0
                            if let id = mergedStartIndex[getExcelColumnName(columnNumber: section) + String(item)] {

                                let end_column_aphabet_int = alphabetOnlyString(text: appd.diff_end_index[id])
                                let end_row_int = Int(numberOnlyString(text: appd.diff_end_index[id]))
                                let end_column_int = getExcelColumnNumber(columnName: end_column_aphabet_int)
 
                                if(section > end_column_int || item > end_row_int!){
                                    print("out of index")
                                    cellAttributes.frame = CGRect(x: xPOS[section], y: yPOS[item], width: each_width[section], height: each_height[item])
                                    
                                    cellAttributes.zIndex = 1
                                    cellAttrsDictionary[cellIndex] = cellAttributes
                                    
                                }else{
                                    
                                    // Calculate the sum of each_width from section to col_end
                                    let sumWidth = (section...end_column_int).reduce(0) { result, i in
                                        return result + each_width[i]
                                    }
                                    
                                    // Calculate the sum of each_height from item to row_end
                                    let sumHeight = (item...end_row_int!).reduce(0) { result, j in
                                        return result + each_height[j]
                                    }
                                    
                                    EACH_WIDTH += sumWidth
                                    EACH_HEIGHT += sumHeight
                                    
                                    cellAttributes.frame = CGRect(x: xPOS[section], y: yPOS[item], width: EACH_WIDTH, height: EACH_HEIGHT)
                                    
                                    //lay it at top of ordinary cells
                                    cellAttributes.zIndex = 2
                                    
                                    cellAttrsDictionary[cellIndex] = cellAttributes
                                }
                                
                            }else{
                                //
                                cellAttributes.frame = CGRect(x: xPOS[section], y: yPOS[item], width: each_width[section], height: each_height[item])
                                
                                cellAttributes.zIndex = 1
                                
                                // Save the attributes.
                                if(cellAttrsDictionary[cellIndex] == nil){
                                    cellAttrsDictionary[cellIndex] = cellAttributes
                                }else{
                                    //print("attribute exists") //well. what should i do in this case
                                }
                            }
                            
                        }
                    }
                }
            }
        }
             
        
        
        // Update content size.
        self.contentSize = CGSize(width: xPos, height: yPos)
   
        
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
        return attributesInRect
    }

    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
   
        return cellAttrsDictionary[indexPath]!
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
