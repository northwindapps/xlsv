import UIKit

class _CustomCollectionViewLayout2: UICollectionViewLayout {
    
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
    var diffColumn = [[Int]]()
    var diffRow = [[Int]]()
    var presentIndex = [String]()
    var goodBye = [[Int]]()
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
    
    var merged = [String]()
    
    override var collectionViewContentSize : CGSize {
        return self.contentSize
    }
    
    override func prepare() {
        if (UserDefaults.standard.object(forKey: "cellSize") != nil) {
            let size = UserDefaults.standard.object(forKey: "cellSize") as! Int
            switch size {
            case 0:
                CELL_HEIGHT = 30.0
                CELL_WIDTH = 40.0
                INDEX_WIDTH = 30.0
                INDEX_HEIGHT = 30.0
                break
            case 1:
                CELL_HEIGHT = 30.0
                CELL_WIDTH = 80.0
                INDEX_WIDTH = 30.0
                INDEX_HEIGHT = 30.0
                break
            case 2:
                CELL_HEIGHT = 30.0
                CELL_WIDTH = 120.0
                INDEX_WIDTH = 30.0
                INDEX_HEIGHT = 30.0
                break
            case 3:
                CELL_HEIGHT = 30.0
                CELL_WIDTH = 150.0
                INDEX_WIDTH = 30.0
                INDEX_HEIGHT = 30.0
                break
            default:
                break
            }
        }
        
        
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
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

        //let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        var c = appd.DEFAULT_COLUMN_NUMBER//30
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            let v = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
            if v > c{
                c = v
            }
        }
        
        var r = appd.DEFAULT_ROW_NUMBER
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
            
        merged.append("1,1")
        appd.cshLocation.append(1)
        appd.cswLocation.append(1)
        appd.customSizedHeight.appomSizedHeight.append(CELL_HEIGHT * 0)
        appd.customSizedWidth.append(CELL_WIDTH * 0)
        appd.customSizedHeight.append(CELL_HEIGHT * 2)
        appd.customSizedWidth.append(CELL_WIDTH * 2)
        appd.customSizedHeight.append(CELL_HEIGHT * 0)
        appd.customSizedWidth.append(CELL_WIDTH * 0)
        //custom cell height
        for i in 0..<each_height.count{
            if appd.cshLocation.contains(i){
                let l = appd.cshLocation.index(of: i)
                let doubled = Double(appd.customSizedHeight[l!])
                each_height[i] = doubled
            }
            
            yPos += each_height[i]
            yPOS.append(yPos)
        }
        
        //custom cell width
        for j in 0..<each_width.count{
            if appd.cswLocation.contains(j){
                let l = appd.cswLocation.index(of: j)
                let doubled = Double(appd.customSizedWidth[l!])
                each_width[j] = doubled
            }
            
            xPos += each_width[j]
            xPOS.append(xPos)
            
        }
            
            
        
        appd.numberofRow = r
        appd.numberofColumn = c
        
        
       
        //mergedcell
        //long code to go
//        if appd.mergedCellListJSON.count>0{
//
//            let mergedCellList = appd.mergedCellListJSON[appd.index]["array"]
//            let tempClass = MergedCalc()
//
//
//
//            //            appd.nousecells = goodBye
//
//            (diffColumn,diffRow,goodBye) = tempClass.mergeCalc(mergedCells: mergedCellList as! [String])
//        }
//
        }
        
        // Only update header cells.
        if !dataSourceDidUpdate {
         
            // Determine current content offsets.
            let xOffset = collectionView!.contentOffset.x
            let yOffset = collectionView!.contentOffset.y
            
            if let sectionCount = collectionView?.numberOfSections, sectionCount > 0 {
                for section in 0...sectionCount-1 {
                    
                    // Confirm the section has items.
                    if let rowCount = collectionView?.numberOfItems(inSection: section), rowCount > 0 {
                        
                        // Update all items in the first row.
                        if section == 0 {
                            for item in 0...rowCount-1 {
                                
                                // Build indexPath to get attributes from dictionary.
                                let indexPath = IndexPath(item: item, section: section)
                                
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
                            // the x-position for the fist item.
                        } else {
                            
                            // Build indexPath to get attributes from dictionary.
                            let indexPath = IndexPath(item: 0, section: section)
                            
                            // Update y-position to follow user.
                            if let attrs = cellAttrsDictionary[indexPath] {
                                var frame = attrs.frame
                                frame.origin.x = xOffset
                                attrs.frame = frame
                            }
                            
                        } // else
                    } // num of items in section > 0
                } // sections for loop
            } // num of sections > 0
            
            
            // Do not run attribute generation code
            // unless data source has been updated.
            return
        }
        
        // Acknowledge data source change, and disable for next time.
        dataSourceDidUpdate = false
   
        // Cycle through each section of the data source.
     
        if let sectionCount = collectionView?.numberOfSections, sectionCount > 0 {
            for section in 0...sectionCount-1 {
                //                print("section",section)
                
                
                // Cycle through each item in the section.
                if let rowCount = collectionView?.numberOfItems(inSection: section), rowCount > 0 {
                    for item in 0...rowCount-1 {
                        
                        // Build the UICollectionVieLayoutAttributes for the cell.
                        let cellIndex = IndexPath(item: item, section: section)
                        let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: cellIndex)
                        
                       
                        
                      
                        
                        if item == 0{
                            //column 0
                            cellAttributes.frame = CGRect(x: xPOS[item], y: yPOS[section], width: each_width[item], height: each_height[section])
                            
                            // Determine zIndex based on cell type.
                            if section == 0 && item == 0 {
                                cellAttributes.zIndex = 4
                            } else if section == 0 {
                                cellAttributes.zIndex = 3
                            } else if item == 0 {
                                cellAttributes.zIndex = 2
                            } else {
                                cellAttributes.zIndex = 1
                            }
                            
                            cellAttrsDictionary[cellIndex] = cellAttributes
                        }else{
                            var EACH_HEIGHT = 0.0
                            var EACH_WIDTH = 0.0
                            if appd.mergedCellListJSON.count>0{
                                //merged cells
                                print("merged cell")
                                if diffRow[section][item] != 0{
                                    
                                    for j in 0..<diffRow[section][item]+1{
                                        EACH_HEIGHT += each_height[section + j]
                                    }
                                }
                                if diffColumn[section][item] != 0{
                                    EACH_WIDTH = 0
                                    for i in 0..<diffColumn[section][item]+1{//2
                                        EACH_WIDTH += each_width[item + i]
                                    }
                                }
                                
                                cellAttributes.frame = CGRect(x: xPOS[item], y: yPOS[section], width: EACH_WIDTH, height: EACH_HEIGHT)
                                
                                // Determine zIndex based on cell type.
                                if section == 0 && item == 0 {
                                    cellAttributes.zIndex = 4
                                } else if section == 0 {
                                    cellAttributes.zIndex = 3
                                } else if item == 0 {
                                    cellAttributes.zIndex = 2
                                } else {
                                    cellAttributes.zIndex = 1
                                }
                                
                                cellAttrsDictionary[cellIndex] = cellAttributes
                                if goodBye[section][item] == -1{
                                    cellAttrsDictionary.removeValue(forKey: cellIndex)
                                }
                                
                            }else{
                                cellAttributes.frame = CGRect(x: xPOS[item], y: yPOS[section], width: each_width[item], height: each_height[section])
                                
                                // Determine zIndex based on cell type.
                                if section == 0 && item == 0 {
                                    //left top
                                    cellAttributes.zIndex = 4
                                } else if section == 0 {
                                    cellAttributes.zIndex = 3
                                } else if item == 0 {
                                    cellAttributes.zIndex = 2
                                } else {
                                    cellAttributes.zIndex = 1
                                }
                                
                                // Save the attributes.
                                cellAttrsDictionary[cellIndex] = cellAttributes
                            }
                            
                        }
                    }
                }
            }
        }
        
        
        
        // Update content size.
        self.contentSize = CGSize(width: xPos, height: yPos)
   
        
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        // Create an array to hold all elements found in our current view.
        var attributesInRect = [UICollectionViewLayoutAttributes]()
        
        // Check each element to see if it should be returned.
        for cellAttributes in cellAttrsDictionary.values {
            if rect.intersects(cellAttributes.frame) {
                attributesInRect.append(cellAttributes)
            }
        }

        // Return list of elements.
        return attributesInRect
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        //here
        return cellAttrsDictionary[indexPath]!
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    
        return true
    }
    
}
