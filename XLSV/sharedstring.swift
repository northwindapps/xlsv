//
//  sharedstring.swift
//  xmlProject
//
//  Created by yujin on 2020/10/16.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class Sharedstring{
    let sharedstring:String
    
    init(imp_sharedString:String) {
        //TODO
        sharedstring=imp_sharedString
    }
    
    func export(sheetSize:Int){
        var xml = ""
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>")
        xml.append(sharedstring)
        FileManager.default.writeXmlsandBox(folder: "xl/", filename: "sharedStrings.xml", content: xml)
    }
}

//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="3" uniqueCount="3">
//    <si>
//        <t>sheet1 empty</t>
//    </si>
//    <si>
//        <t>sheet2 empty</t>
//    </si>
//    <si>
//        <t>sheet3 empty</t>
//    </si>
//</sst>

