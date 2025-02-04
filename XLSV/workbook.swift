//
//  workbook.swift
//  xmlProject
//
//  Created by yujin on 2020/10/13.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class Workbook {
    
    let workbook:String
    var xmlns:[String]
    let fileVersion:String
    let workbookPr:String
    var xr:String
    let bookViews:String
    let workbookView:String
    var sheet:[String]//TODO
    var xcalcf:[String]
    let calcPr:String
    let extLst:String
    let ext:String
    
    
    
    
    init() {
        workbook = "<workbook "
        
        xmlns=[String]()
        
        fileVersion = "<fileVersion appName=\"xl\" lastEdited=\"7\" lowestEdited=\"4\" rupBuild=\"23405\"/>"
        
        workbookPr = "<workbookPr defaultThemeVersion=\"166925\"/>"
        
        xr = "<xr:revisionPtr revIDLastSave=\"0\" documentId=\"8_{53DB9D8F-F26C-42F6-A43D-4D2C625C1BFC}\" xr6:coauthVersionLast=\"45\" xr6:coauthVersionMax=\"45\" xr10:uidLastSave=\"{00000000-0000-0000-0000-000000000000}\"/>"
        
        bookViews = "<bookViews>"
        
        workbookView = "<workbookView xWindow=\"240\" yWindow=\"105\" windowWidth=\"14805\" windowHeight=\"8010\" xr2:uid=\"{00000000-000D-0000-FFFF-FFFF00000000}\"/>"
        
        
        sheet=[String]()
        
        calcPr = "<calcPr calcId=\"191028\" calcCompleted=\"0\"/>"
        
        extLst = "<extLst>"
        
        ext = "<ext uri=\"{B58B0392-4F1F-4190-BB64-5DF3571DCE5F}\" xmlns:xcalcf=\"http://schemas.microsoft.com/office/spreadsheetml/2018/calcfeatures\">"
        
        xcalcf=[String]()
        
  
    }
    
    func xmlnsInit(){
        xmlns.append("xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" ")
        xmlns.append("xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" ")
        xmlns.append("xmlns:mc=\"http://schemas.openxmlformats.org/markup-compatibility/2006\" ")
        xmlns.append("mc:Ignorable=\"x15 xr xr6 xr10 xr2\" ")
        xmlns.append("xmlns:x15=\"http://schemas.microsoft.com/office/spreadsheetml/2010/11/main\" ")
        xmlns.append("xmlns:xr=\"http://schemas.microsoft.com/office/spreadsheetml/2014/revision\" ")
        xmlns.append("xmlns:xr6=\"http://schemas.microsoft.com/office/spreadsheetml/2016/revision6\" ")
        xmlns.append("xmlns:xr10=\"http://schemas.microsoft.com/office/spreadsheetml/2016/revision10\" ")
        xmlns.append("xmlns:xr2=\"http://schemas.microsoft.com/office/spreadsheetml/2015/revision2\"")
    }
    
    //TODO
    func sheetGenerator(id:Int){
        sheet.append("<sheet name=\"Sheet" + String(id) + "\" sheetId=\"" + String(id) + "\" r:id=\"rId" + String(id) + "\"/>")
    }
    
    func xcalcfInit(){
        xcalcf.append("<xcalcf:calcFeatures>")
        xcalcf.append("<xcalcf:feature name=\"microsoft.com:RD\"/>")
        xcalcf.append("<xcalcf:feature name=\"microsoft.com:Single\"/>")
        xcalcf.append("<xcalcf:feature name=\"microsoft.com:FV\"/>")
        xcalcf.append("<xcalcf:feature name=\"microsoft.com:CNMTM\"/>")
        xcalcf.append("<xcalcf:feature name=\"microsoft.com:LET_WF\"/>")
        xcalcf.append("</xcalcf:calcFeatures>")
    }
    
    //TODO
    func export(sheetSize:Int){
        
        xmlnsInit()
        xcalcfInit()
        for i in 1..<sheetSize+1 {
                   sheetGenerator(id: i)
               }
        
        var xml = ""
            xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>")
        xml.append(workbook)
        
        for i in 0..<xmlns.count {
            xml.append(xmlns[i])
        }
        
        xml.append(">")
        xml.append(fileVersion)
        xml.append(workbookPr)
        xml.append(xr)
        xml.append(bookViews)
        xml.append(workbookView)
        xml.append("</bookViews>")
        xml.append("<sheets>")
       for i in 0..<sheet.count {
           xml.append(sheet[i])
       }
        
        xml.append("</sheets>")
        xml.append(calcPr)
        xml.append(extLst)
        xml.append(ext)
        for i in 0..<xcalcf.count {
            xml.append(xcalcf[i])
        }
        xml.append("</ext>")
        xml.append("</extLst>")
        xml.append("</workbook>")
        
            
            FileManager.default.writeXmlsandBox(folder: "xl/", filename: "workbook.xml", content: xml)
        }
}


//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<workbook
//    xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
//    mc:Ignorable="x15 xr xr6 xr10 xr2"
//    xmlns:x15="http://schemas.microsoft.com/office/spreadsheetml/2010/11/main" xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision" xmlns:xr6="http://schemas.microsoft.com/office/spreadsheetml/2016/revision6" xmlns:xr10="http://schemas.microsoft.com/office/spreadsheetml/2016/revision10" xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2">
//
//    <fileVersion appName="xl" lastEdited="7" lowestEdited="4" rupBuild="23405"/>
//    <workbookPr defaultThemeVersion="166925"/>
//    <xr:revisionPtr revIDLastSave="0" documentId="8_{53DB9D8F-F26C-42F6-A43D-4D2C625C1BFC}" xr6:coauthVersionLast="45" xr6:coauthVersionMax="45" xr10:uidLastSave="{00000000-0000-0000-0000-000000000000}"/>
//    <bookViews>
//        <workbookView xWindow="240" yWindow="105" windowWidth="14805" windowHeight="8010" xr2:uid="{00000000-000D-0000-FFFF-FFFF00000000}"/>
//    </bookViews>
//    <sheets>
//        <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
//        <sheet name="Sheet2" sheetId="2" r:id="rId2"/>
//        <sheet name="Sheet3" sheetId="3" r:id="rId3"/>
//    </sheets>
//    <calcPr calcId="191028" calcCompleted="0"/>
//    <extLst>
//        <ext uri="{B58B0392-4F1F-4190-BB64-5DF3571DCE5F}" xmlns:xcalcf="http://schemas.microsoft.com/office/spreadsheetml/2018/calcfeatures">
//            <xcalcf:calcFeatures>
//            <xcalcf:feature name="microsoft.com:RD"/>
//            <xcalcf:feature name="microsoft.com:Single"/>
//            <xcalcf:feature name="microsoft.com:FV"/>
//            <xcalcf:feature name="microsoft.com:CNMTM"/>
//            <xcalcf:feature name="microsoft.com:LET_WF"/>
//        </xcalcf:calcFeatures>
//    </ext>
//    </extLst>
//</workbook>
