//
//  rels.swift
//  xmlProject
//
//  Created by yujin on 2020/10/13.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class Rels {
    let relationships:String

    var eachRel:[String]
    
    init() {
        relationships = "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
        eachRel=[String]()
    }
    
    func writeRelation(id:Int) -> String {
        switch id {
        case 1:
            return "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>"
            
        case 2:
            
            return  "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties\" Target=\"docProps/core.xml\"/>"
            
        case 3:
            return "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties\" Target=\"docProps/app.xml\"/>"
            
        default:
            return ""
        }
    }
    
    //TODO ok static
    func export(){
        var xml = ""
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>")
        xml.append(relationships)
        xml.append(writeRelation(id: 3))
        xml.append(writeRelation(id: 2))
        xml.append(writeRelation(id: 1))
        xml.append("</Relationships>")
        
        FileManager.default.writeXmlsandBox(folder: "_rels/", filename: ".rels", content: xml)
    
    }
    
}

//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
//    <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
//    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
//    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
//</Relationships>
