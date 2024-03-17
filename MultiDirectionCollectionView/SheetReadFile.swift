//
//  sheetX.swift
//  read_write_file
//
//  Created by yujin on 2020/03/04.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation
import Zip

class SheetReadFile {
    //this is still in development definately 20200321
    //it needs data from stylereadfile.swift
    //https://stackoverflow.com/questions/3154646/what-does-the-s-attribute-signify-in-a-cell-tag-in-xlsx
    
    var myData: Data!
    var LAST_COLUMN = 7
    var LAST_ROW = 22 // from 1 to
    let FILE_PATH = Bundle.main.url(forResource: "original/xl/worksheets/sheet1", withExtension: "xml")
    let HEADER = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:mc=\"http://schemas.openxmlformats.org/markup-compatibility/2006\" mc:Ignorable=\"x14ac xr xr2 xr3\" xmlns:x14ac=\"http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac\" xmlns:xr=\"http://schemas.microsoft.com/office/spreadsheetml/2014/revision\" xmlns:xr2=\"http://schemas.microsoft.com/office/spreadsheetml/2015/revision2\" xmlns:xr3=\"http://schemas.microsoft.com/office/spreadsheetml/2016/revision3\" xr:uid=\"{00000000-0001-0000-0000-000000000000}\">"
    let dimension = "<dimension ref=\"A1:LAST_CELL_ADDRESS\"/>" //"<dimension ref=\"A1:LAST_CELL_ADDRESS\"/>" Yes as you can see, these are variables
    var header3 = "<sheetViews><sheetView tabSelected=\"1\" topLeftCell=\"A1\" workbookViewId=\"0\"><selection activeCell=\"B3\" sqref=\"B3\"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight=\"13.5\"/><cols><col min=\"1\" max=\"16384\" width=\"9\" style=\"1\"/></cols><sheetData>"
    
//    var header4 = "<sheetViews><sheetView workbookViewId=\"0\" showGridLines=\"0\" defaultGridColor=\"1\"/></sheetViews><sheetFormatPr defaultColWidth=\"16.3333\" defaultRowHeight=\"19.9\" customHeight=\"1\" outlineLevelRow=\"0\" outlineLevelCol=\"0\"/><cols><col min=\"1\" max=\"LAST_COLUMN\" width=\"16.3516\" style=\"1\" customWidth=\"1\"/><col min=\"LAST_COLUMN_PLUS_ONE\" max=\"256\" width=\"16.3516\" style=\"1\" customWidth=\"1\"/></cols><sheetData>"
    


    let FOOTER = "</sheetData><pageMargins left=\"0.7\" right=\"0.7\" top=\"0.75\" bottom=\"0.75\" header=\"0.3\" footer=\"0.3\"/></worksheet>"
    
    //This is insane. Switch codes by if statement. if cell has a value or,
    // main content comes in the following section
    let ROW_PART = "<row r=\"ROWINDEX\" spans=\"2:3\" ht=\"14.25\">COLUMNS_STR_COMES_HERE</row>"
    
    let COLUMN_VALUES = "<c r=\"CELL_REFERENCE\" s=\"STYLE_INDEX\" t=\"s\"><v>VALUE_INDEX</v></c>"
    
    let COLUMN = "<c r=\"CELL_REFERENCE\" s=\"STYLE_INDEX\"/>"
    
    var import_xml_location:[String]
    var import_xml_reference:[String]
    var styleListforCells:[String]
   
    
    init(import_xml_location:[String], import_xml_reference:[String], styleListforCells:[String] ){
        self.import_xml_location = import_xml_location
        self.import_xml_reference = import_xml_reference
        self.styleListforCells = styleListforCells
      
    }
    
//    var content_array = [String]()
    var content_array = [ String: String ]()
    
    
    

    func checking() {

        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("unziped/xl/worksheets/sheet1.xml")
            //override
            do
            {
                if FileManager.default.fileExists(atPath: fileURL.path){
                    try FileManager.default.removeItem(at: fileURL)
                    print("file removed")
                }
                
            }catch let error {
                print(error.localizedDescription)
            }
            writeFile(fileURL: fileURL)
        }
    }
    
    func writeFile(fileURL: URL) {
        do {
            myData = setupFileContent().data(using: String.Encoding.utf8)
            try myData.write(to: fileURL)
//            print(myData)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func removeArrayItem(input:[String], keyword:String) -> [String]{
        var output = [String]()
        for v in 0..<input.count {
            if input[v].contains(keyword){
                
            }else{
                output.append(input[v])
            }
        }
        return output
    }
    
    func setupFileContent()-> String{
        var content = ""
        
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            LAST_COLUMN = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
        }
        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
            LAST_ROW = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
        }
        
        let last_cell_address = SpreadSheet().getExcelColumnName(columnNumber: LAST_COLUMN) + String(LAST_ROW)
        content.append(HEADER)
        content.append(dimension.replacingOccurrences(of: "LAST_CELL_ADDRESS", with: last_cell_address))
        content.append(header3)
        
     
        //Continue the work from here. And StyleRead.swift is unouched 20200323
        //-> it's almost done 20200327 leftover is this sheetReadFile I think.
   
        
        //Let's call cells by their name A2, D4
        for r in 0..<LAST_ROW{
            var replace_column_str = ""
            for c in 0..<LAST_COLUMN{
                let columnName = SpreadSheet().getExcelColumnName(columnNumber: c+1)//or
                let rowNumber = String(r+1)// now like as D1
                let localref = columnName + rowNumber
                //value testing
                if let idx = import_xml_reference.firstIndex(of: localref ){
                    let style = styleListforCells[idx]
                    let value = import_xml_location[idx]
                    
                    replace_column_str.append(COLUMN_VALUES.replacingOccurrences(of: "CELL_REFERENCE", with: columnName + rowNumber).replacingOccurrences(of: "STYLE_INDEX", with: style).replacingOccurrences(of: "VALUE_INDEX", with: value))
                    
                    // pasted only cells needs else if
//                    COLUMN_VALUES = "<c r=\"CELL_REFERENCE\" s=\"STYLE_INDEX\" t=\"s\"><v>VALUE_INDEX</v></c>"
//                    COLUMN = "<c r=\"CELL_REFERENCE\" s=\"STYLE_INDEX\"/>"
                    
                }else{
                    //replace_column_str.append(COLUMN.replacingOccurrences(of: "CELL_REFERENCE", with: columnName + rowNumber).replacingOccurrences(of: "STYLE_INDEX", with: blankCellStyle ))
                }
                
            }//end column
            
            if replace_column_str.count>0{
                content.append(ROW_PART.replacingOccurrences(of: "ROWINDEX", with: String(r+1)).replacingOccurrences(of: "COLUMNS_STR_COMES_HERE", with: replace_column_str))
            }
        }
        
        //<c r="F4" t="s" s="3"><v>1</v></c></row>
        content.append(FOOTER)
        return content
    }
    
}
