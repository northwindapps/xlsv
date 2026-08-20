//
//  StyleReadFile.swift
//  read_write_file
//
//  Created by yujin on 2020/03/20.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class StyleReadFile {
    var myData: Data!
    var textColor = [String]()
    var bgColor = [String]()
    var textSize = [String]()
    var cellStyle = [String]()
    
    var fontSortingList = [String]()
    var fillcolorSortingList = [String]()
    
    var each_font_style = "<font><sz val=\"text_size\"/><color rgb=\"color_index\"/><name val=\"Arial\"/></font>"
    var each_fill_style = "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"fill_color\"/><bgColor indexed=\"64\"/></patternFill></fill>"
    var each_xf_font_fill = "<xf numFmtId=\"0\" fontId=\"font_id\" fillId=\"fill_id\" borderId=\"1\" xfId=\"0\" applyFont=\"1\" applyFill=\"1\"/>"

    
    
    
    let HEADER = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:mc=\"http://schemas.openxmlformats.org/markup-compatibility/2006\" mc:Ignorable=\"x14ac x16r2 xr\" xmlns:x14ac=\"http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac\" xmlns:x16r2=\"http://schemas.microsoft.com/office/spreadsheetml/2015/02/main\" xmlns:xr=\"http://schemas.microsoft.com/office/spreadsheetml/2014/revision\">"
    
    
    let BORDER = "<borders count=\"2\"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style=\"thin\"><color rgb=\"FFD9D9D9\"/></left><right style=\"thin\"><color rgb=\"FFD9D9D9\"/></right><top style=\"thin\"><color rgb=\"FFD9D9D9\"/></top><bottom style=\"thin\"><color rgb=\"FFD9D9D9\"/></bottom><diagonal/></border></borders>"
    let CELLSTYLE = "<cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>"
    

    

//
//    let LONG_FOOTERX = "</cellXfs><cellStyles count=\"1\"><cellStyle name=\"Normal\" xfId=\"0\" builtinId=\"0\"/></cellStyles><dxfs count=\"0\"/><tableStyles count=\"0\"/><colors><indexedColors><rgbColor rgb=\"ff000000\"/><rgbColor rgb=\"ffffffff\"/><rgbColor rgb=\"ffff0000\"/><rgbColor rgb=\"ff00ff00\"/><rgbColor rgb=\"ff6600ff\"/><rgbColor rgb=\"ffffff00\"/><rgbColor rgb=\"ffff00ff\"/><rgbColor rgb=\"ff00ffff\"/><rgbColor rgb=\"ff000000\"/><rgbColor rgb=\"ffa5a5a5\"/><rgbColor rgb=\"ff0081cc\"/><rgbColor rgb=\"ff00ffff\"/><rgbColor rgb=\"ff006600\"/><rgbColor rgb=\"ff663300\"/><rgbColor rgb=\"ffff6600\"/></indexedColors></colors></styleSheet>"
    
    let LONG_FOOTER = "<cellStyles count=\"1\"><cellStyle name=\"標準\" xfId=\"0\" builtinId=\"0\"/></cellStyles><dxfs count=\"0\"/><tableStyles count=\"0\" defaultTableStyle=\"TableStyleMedium2\" defaultPivotStyle=\"PivotStyleMedium9\"/><extLst><ext uri=\"{EB79DEF2-80B8-43e5-95BD-54CBDDF9020C}\" xmlns:x14=\"http://schemas.microsoft.com/office/spreadsheetml/2009/9/main\"><x14:slicerStyles defaultSlicerStyle=\"SlicerStyleLight1\"/></ext><ext uri=\"{9260A510-F301-46a8-8635-F512D64BE5F5}\" xmlns:x15=\"http://schemas.microsoft.com/office/spreadsheetml/2010/11/main\"><x15:timelineStyles defaultTimelineStyle=\"TimeSlicerStyleLight1\"/></ext></extLst></styleSheet>"
 
    //A2,W2...
    var xml_content_location: [String]
    
    init(xml_content_location:[String]) {
        self.xml_content_location = xml_content_location
    }
    
    
    
    ///
    
    
    func checking() {
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("unziped/xl/styles.xml")
            
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
            var intermidiate = [String]()
            var fruit = ""
            (fruit, intermidiate) = setupFileContent()
            myData = fruit.data(using: String.Encoding.utf8)
            try myData.write(to: fileURL)
            
//            print("fruit: " + fruit)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func setupFileContent()-> (String, [String]){
        
        // these array count should be the same as content_array or it will collapse
        // when you input a text, if these style attributes also be attatched with, the problem is solved.
        if (UserDefaults.standard.object(forKey: "NEWTMBGCOLOR") != nil) {
            
            bgColor = UserDefaults.standard.object(forKey: "NEWTMBGCOLOR") as! Array
        }
        
        //It stuck here
        if (UserDefaults.standard.object(forKey: "NEWTMSIZE") != nil) {
            
            textSize = UserDefaults.standard.object(forKey: "NEWTMSIZE") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEWTMTCOLOR") != nil) {
            
            textColor = UserDefaults.standard.object(forKey: "NEWTMTCOLOR") as! Array
        }
        
        

        // Pre process these three properties are imported through nsuserdefault
        if textColor.count == 0 || bgColor.count == 0 || textSize.count == 0{
            textColor.removeAll()
            bgColor.removeAll()
            textSize.removeAll()
            
            for _ in 0..<xml_content_location.count{
                textColor.append("black")
                bgColor.append("white")
                textSize.append("10")
            }
            
        }
        
        // init for making
        var content = ""
        content.append(HEADER)
        content.append(font_style_part(textsize: textSize, fontcolor: textColor))
        content.append(fill_color_part(fillcolor: bgColor))
        content.append(BORDER)
        content.append(CELLSTYLE)
        content.append(cellxf_part())
        
        
        content.append(LONG_FOOTER)
      
        //it's reffered as A4 s= "0" s = "3", s = "5" in sheet
        let xml_cell_syle = cellStyle
        
        return (content, xml_cell_syle)
    }
    

    
    func hex_switching(rgb:String) -> String{
        switch rgb {
        case "black":
            return "FF000000"
        case "white":
            return "FFFFFFFF"
        case "red":
            return "FFFF0000"
        case "lightGreen":
            return "FF00FF00"
        case "purple":
            return "FF7030A0"
        case "yellow":
            return "FFFFFF00"
        case "magenta":
            return "FFFF00FF"
        case "aqua":
            return "FF00FFFF"
        case "gray":
            return "FF808080"
        case "lightGray":
            return "FFD9D9D9"
        case "blue":
            return "FF00B0F0"
        case "water":
            return "FF00FFFF"
        case "green":
            return "FF006600"
        case "brown":
            return "FF833C0C"
        case "orange":
            return "FFFFC000"
        default:
            return "FF000000"
        }
    }
    

    
    func font_style_part(textsize:[String],fontcolor:[String]) -> String{
        fontSortingList = []
        var duplicate = [String]()
        var outputStr = ""
        let initialOne = "<font><sz val=\"11\"/><color theme=\"1\"/><name val=\"Arial\"/></font>"
        for idx in 0..<xml_content_location.count{
            let checking = textsize[idx] + "," + fontcolor[idx]
            
            if duplicate.contains(checking){
                
            }else{
                duplicate.append(checking)
                let hex_value = hex_switching(rgb: fontcolor[idx])
                let temp = each_font_style.replacingOccurrences(of: "text_size", with: textsize[idx]).replacingOccurrences(of: "color_index", with: hex_value)
                outputStr.append(temp)
            }
            
            let here = duplicate.firstIndex(of: checking)
            fontSortingList.append(String(here!+1))
        }
        
        let header = "<fonts count=\"" + String(duplicate.count+1) + "\">"
        
        
//            var each_font_style = "<font><sz val=\"text_size\"/><color rgb=\"color_index\"/><name val=\"Arial\"/></font>"
        return header + initialOne + outputStr + "</fonts>"
    }
    
    func fill_color_part(fillcolor:[String]) -> String{
        fillcolorSortingList = []
        var duplicate = [String]()
//        duplicate.append("none")
//        duplicate.append("gray125")
//        var outputStr = "<fill><patternFill patternType=\"none\"/></fill><fill><patternFill patternType=\"gray125\"/></fill>"
        let initialTwoItems = "<fill><patternFill patternType=\"none\"/></fill><fill><patternFill patternType=\"gray125\"/></fill>"
        var outputStr = ""
        for idx in 0..<xml_content_location.count{
            let checking = fillcolor[idx]
            
            if duplicate.contains(checking){
                
            }else{
                duplicate.append(checking)
                let hex_value = hex_switching(rgb: fillcolor[idx])
                let temp = each_fill_style.replacingOccurrences(of: "fill_color", with: hex_value)
                outputStr.append(temp)
            }
            
            let here = duplicate.firstIndex(of: checking)
            fillcolorSortingList.append(String(here!+2))
            
        }

        let header = "<fills count=\"" + String(duplicate.count+2) + "\">"//two items
        
  
        
        //            <fill><patternFill patternType="solid"><fgColor rgb="FF8EA9DB"/><bgColor indexed="64"/></patternFill></fill>
        return header + initialTwoItems +  outputStr + "</fills>"
    }
    
    func cellxf_part() -> String{
        cellStyle = []
        var duplicate = [String]()
        var outputStr = ""
        let initialOne = "<xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/>"
        for idx in 0..<xml_content_location.count{
            let fontIdx = fontSortingList[idx]
            let fillIdx = fillcolorSortingList[idx]
            let checking = String(fontIdx) + "," + String(fillIdx)

            if duplicate.contains(checking){
                
            }else{
                duplicate.append(checking)
                let cell = each_xf_font_fill.replacingOccurrences(of: "font_id", with: String(fontIdx)).replacingOccurrences(of: "fill_id", with: String(fillIdx))
                outputStr.append(cell)
            }
            
            let here = duplicate.firstIndex(of: checking)
            cellStyle.append(String(here!+1))

        }
        
        let header = "<cellXfs count=\"" + String(duplicate.count+1) + "\">"
 
        
        //            <fill><patternFill patternType="solid"><fgColor rgb="FF8EA9DB"/><bgColor indexed="64"/></patternFill></fill>
        return header + initialOne + outputStr + "</cellXfs>"
    }
}
