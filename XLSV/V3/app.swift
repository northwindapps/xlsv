//
//  app.swift
//  xmlProject
//
//  Created by yujin on 2020/10/14.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class App{
    
    let properties:String
    let application:String
    let manager:String
    let company:String
    let hyperlink:String
    let appversion:String
    
    init(){
        properties="<Properties xmlns=\"http://schemas.openxmlformats.org/officeDocument/2006/extended-properties\" xmlns:vt=\"http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes\">"
        
        application="<Application>Microsoft Excel Online</Application>"
        manager="<Manager></Manager>"
        company="<Company></Company>"
        hyperlink="<HyperlinkBase></HyperlinkBase>"
        appversion="<AppVersion>16.0300</AppVersion>"
    }
    
    //ok static
    func export(){
        var xml = ""
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>")
        xml.append(properties)
        xml.append(application)
        xml.append(manager)
        xml.append(company)
        xml.append(hyperlink)
        xml.append(appversion)
        xml.append("</Properties>")
        
        FileManager.default.writeXmlsandBox(folder: "docProps/", filename: "app.xml", content: xml)
    }
}


//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
//    <Application>Microsoft Excel Online</Application>
//    <Manager></Manager>
//    <Company></Company>
//    <HyperlinkBase></HyperlinkBase>
//    <AppVersion>16.0300</AppVersion>
//</Properties>
