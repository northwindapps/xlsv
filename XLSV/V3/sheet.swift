//
//  sheet.swift
//  xmlProject
//
//  Created by yujin on 2020/10/18.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class Sheet{

    let randamChar:[String]
    var randamCode:[String]
    let sheetContents:[String]
    
    init(imp_sheetContents:[String]) {
        randamChar = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
        randamCode = [String]()
        sheetContents = imp_sheetContents
    }
    
    func sheetGenerator(id:Int)->String{
        
        var code = ""
        while true {
            for _ in 0..<8 {
                let idx = Int.random(in: 0..<16)
                code.append(randamChar[idx])
            }
            
            if ((randamCode.firstIndex(of: code)) == nil) {
                randamCode.append(code)
                break
            }else{
                code = ""
            }
        }
        print(code)
        //TODO
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:mc=\"http://schemas.openxmlformats.org/markup-compatibility/2006\" mc:Ignorable=\"x14ac xr xr2 xr3\" xmlns:x14ac=\"http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac\" xmlns:xr=\"http://schemas.microsoft.com/office/spreadsheetml/2014/revision\" xmlns:xr2=\"http://schemas.microsoft.com/office/spreadsheetml/2015/revision2\" xmlns:xr3=\"http://schemas.microsoft.com/office/spreadsheetml/2016/revision3\" xr:uid=\"{" + code + "-0000-0000-0000-000000000000}\"><dimension ref=\"A1\"/><sheetViews><sheetView tabSelected=\"1\" workbookViewId=\"0\"><selection activeCell=\"A2\" sqref=\"A2\"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight=\"13.5\"/>" + sheetContents[id] + "<pageMargins left=\"0.7\" right=\"0.7\" top=\"0.75\" bottom=\"0.75\" header=\"0.3\" footer=\"0.3\"/></worksheet>"
          
    }
    
    func export(sheetSize:Int){
        for i in 0..<sheetSize {
            FileManager.default.writeXmlsandBox(folder: "xl/worksheets/", filename: "sheet" + String(i+1) + ".xml", content: sheetGenerator(id: i))
        }
    }
}


//TODO uid generator
//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac xr xr2 xr3" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac" xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision" xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2" xmlns:xr3="http://schemas.microsoft.com/office/spreadsheetml/2016/revision3" xr:uid="{30EF7B06-8B73-4798-B7F5-5170866F7BE1}"><dimension ref="A1"/><sheetViews><sheetView workbookViewId="0"><selection activeCell="A2" sqref="A2"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight="13.5"/><sheetData><row r="1" spans="1:1"><c r="A1" t="s"><v>1</v></c></row></sheetData><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/></worksheet>



