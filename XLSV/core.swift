//
//  core.swift
//  xmlProject
//
//  Created by yujin on 2020/10/14.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation

class Core{
    
    let coreproperties:String
    let dc_title:String
    let dc_subject:String
    let dc_creator:String
    let cp_keywords:String
    let dc_description:String
    let cp_lastmodifiedby:String
    let cp_revision:String
    let dcterms_created:String
    let dcterms_modified:String
    let cp_category:String
    let cp_contentstatus:String
    
    
    init(){
        coreproperties="<cp:coreProperties xmlns:cp=\"http://schemas.openxmlformats.org/package/2006/metadata/core-properties\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:dcmitype=\"http://purl.org/dc/dcmitype/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"
        
        dc_title="<dc:title></dc:title>"
        dc_subject="<dc:subject></dc:subject>"
        dc_creator="<dc:creator></dc:creator>"
        cp_keywords="<cp:keywords></cp:keywords>"
        dc_description="<dc:description></dc:description>"
        cp_lastmodifiedby="<cp:lastModifiedBy></cp:lastModifiedBy>"
        cp_revision="<cp:revision></cp:revision>"
        dcterms_created="<dcterms:created xsi:type=\"dcterms:W3CDTF\">2020-10-12T15:29:21Z</dcterms:created>"
        dcterms_modified="<dcterms:modified xsi:type=\"dcterms:W3CDTF\">2020-10-12T15:31:41Z</dcterms:modified>"
        cp_category="<cp:category></cp:category>"
        cp_contentstatus="<cp:contentStatus></cp:contentStatus>"
        
    }
    
    //ok static
    func export(){
        var xml = ""
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>")
  
        xml.append(coreproperties)
        xml.append(dc_title)
        xml.append(dc_subject)
        xml.append(dc_creator)
        xml.append(cp_keywords)
        xml.append(dc_description)
        xml.append(cp_lastmodifiedby)
        xml.append(cp_revision)
        xml.append(dcterms_created)
        xml.append(dcterms_modified)
        xml.append(cp_category)
        xml.append(cp_contentstatus)
        xml.append("</cp:coreProperties>")
        
        FileManager.default.writeXmlsandBox(folder: "docProps/", filename: "core.xml", content: xml)
    }
}

//
//<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
//<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
//    <dc:title></dc:title>
//    <dc:subject></dc:subject>
//    <dc:creator></dc:creator>
//    <cp:keywords></cp:keywords>
//    <dc:description></dc:description>
//    <cp:lastModifiedBy></cp:lastModifiedBy>
//    <cp:revision></cp:revision>
//    <dcterms:created xsi:type="dcterms:W3CDTF">2020-10-12T15:29:21Z</dcterms:created>
//    <dcterms:modified xsi:type="dcterms:W3CDTF">2020-10-12T15:31:41Z</dcterms:modified>
//    <cp:category></cp:category>
//    <cp:contentStatus></cp:contentStatus>
//</cp:coreProperties>
