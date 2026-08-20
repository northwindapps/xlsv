//
//  contenttype.swift
//  xmlProject
//
//  Created by yujin on 2020/10/14.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class V2ContentType{
    
    let types:String
    
    var Default:[String]
    var Override:[String]
    
    init() {
        types="<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
        Default=[String]()
        Override=[String]()
    }
    
    func DefaultInit(){
        Default.append("<Default Extension=\"rels\" V2ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>")
        
        Default.append("<Default Extension=\"xml\" V2ContentType=\"application/xml\"/>")
    }
    
    //TODO sheet
    func OverrideInit(){
        Override.append("<Override PartName=\"/xl/workbook.xml\" V2ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>")
        
        Override.append("<Override PartName=\"/docProps/core.xml\" V2ContentType=\"application/vnd.openxmlformats-package.core-properties+xml\"/>")
        Override.append("<Override PartName=\"/docProps/app.xml\" V2ContentType=\"application/vnd.openxmlformats-officedocument.extended-properties+xml\"/>")
        Override.append("<Override PartName=\"/xl/theme/theme1.xml\" V2ContentType=\"application/vnd.openxmlformats-officedocument.theme+xml\"/>")
        Override.append("<Override PartName=\"/xl/styles.xml\" V2ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>")
        Override.append("<Override PartName=\"/xl/sharedStrings.xml\" V2ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml\"/>")
        
        //TODO if calc arry is > 0
//        Override.append("<Override PartName=\"/xl/calcChain.xml\" V2ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.calcChain+xml\"/>")
    }
    
    func OverrideSheet(id:Int){
        Override.append("<Override PartName=\"/xl/worksheets/sheet" + String(id) + ".xml\" V2ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>")
    }
    
    
    
    func export(sheetSize:Int){
        DefaultInit()
        OverrideInit()
        
        for i in 1..<sheetSize+1 {
            OverrideSheet(id: i)
        }
        
        var xml = ""
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>")
        xml.append(types)
        
        for i in 0..<Default.count {
            xml.append(Default[i])
        }
        
        for i in 0..<Override.count {
            xml.append(Override[i])
        }
        
        xml.append("</Types>")
        
        FileManager.default.v2WriteXmlsandBox(folder: "", filename: "[Content_Types].xml", content: xml)
    }
}


//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
//    <Default Extension="rels" V2ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
//    <Default Extension="xml" V2ContentType="application/xml"/>
//    <Override PartName="/xl/workbook.xml" V2ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
//    <Override PartName="/docProps/core.xml" V2ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
//    <Override PartName="/docProps/app.xml" V2ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
//    <Override PartName="/xl/worksheets/sheet1.xml" V2ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
//    <Override PartName="/xl/worksheets/sheet2.xml" V2ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
//    <Override PartName="/xl/worksheets/sheet3.xml" V2ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
//    <Override PartName="/xl/theme/theme1.xml" V2ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
//    <Override PartName="/xl/styles.xml" V2ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
//    <Override PartName="/xl/sharedStrings.xml" V2ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
//</Types>
//
