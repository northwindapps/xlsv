//
//  magic_rels.swift
//  xmlProject
//
//  Created by yujin on 2020/10/13.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class XlRels {
    let open:String
    let close:String
    
    init() {
        open = "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
        
        close = "</Relationships>"
    }
    
    func writeSheetRelation(id:Int) -> String {
        let header = "<Relationship Id=\"" + "rId" + String(id) + "\" "
       return header + "Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet" + String(id) + ".xml\"/>"
    }
    
    func writeThemeRelation(id:Int) -> String {
         let header = "<Relationship Id=\"" + "rId" + String(id) + "\" "
              return header + "Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme\" Target=\"theme/theme1.xml\"/>"
    }
    
    func writeStyleRelation(id:Int) -> String {
         let header = "<Relationship Id=\"" + "rId" + String(id) + "\" "
              return header + "Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>"
    }
    
    func writeSharedStringRelation(id:Int) -> String{
         let header = "<Relationship Id=\"" + "rId" + String(id) + "\" "
              return header + "Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings\" Target=\"sharedStrings.xml\"/>"
    }
    
    //TODO if calc arry is > 0
    func writeCalcChainRelation(id:Int) -> String{
         let header = "<Relationship Id=\"" + "rId" + String(id) + "\" "
              return header + "Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/calcChain\" Target=\"calcChain.xml\"/>"
    }
    

    func export(sheetSize:Int){
        var xml = ""
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>")
        xml.append(open)
        for i in 1..<sheetSize+1 {
            xml.append(writeSheetRelation(id: i))
        }
    
        //TODO
//        xml.append(writeCalcChainRelation(id:sheetSize+4))
        xml.append(writeSharedStringRelation(id: sheetSize+3))
        xml.append(writeStyleRelation(id: sheetSize+2))
        xml.append(writeThemeRelation(id: sheetSize+1))
        xml.append(close)
        
        FileManager.default.writeXmlsandBox(folder: "xl/_rels/", filename: "workbook.xml.rels", content: xml)
    }
    
    
}

//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
//    <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/>
//    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
//    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
//    <Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
//    <Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
//    <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
//</Relationships>
