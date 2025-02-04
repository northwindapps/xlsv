//
//  helper.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2024/03/27.
//  Copyright © 2024 Credera. All rights reserved.
//

import Foundation


// Define a class to act as the delegate for the XMLParser
class XMLParserHelper: NSObject, XMLParserDelegate {
    var siElementCount: Int = -1
    var currentElement: String?
    var currentText: String?

    // Called when the parser finds the start of an element
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "si" {
            siElementCount += 1
        }
    }

    // Called when the parser finds the characters inside an element
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText = (currentText ?? "") + string
    }

    // Called when the parser finds the end of an element
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t" {
            //print("Content of <t> element:", currentText)
            currentText = ""
        }
    }
}

class CustomXMLParserDelegate: XMLParserHelper {
    var foundTargetElement = false
    var extractedPart: String?

    override func parser(_ parser: XMLParser, foundCharacters string: String) {
        if foundTargetElement {
            extractedPart = (extractedPart ?? "") + string
        }
    }

    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "c" && attributeDict["r"] == "B1" {
            foundTargetElement = true
            // Start building the extracted part string
            extractedPart = "<\(elementName)"
            for (key, value) in attributeDict {
                extractedPart! += " \(key)=\"\(value)\""
            }
            extractedPart! += ">"
        }
    }

    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if foundTargetElement && elementName == "c" {
            foundTargetElement = false
            // Close the extracted part string
            extractedPart! += "</\(elementName)>"
        }
    }
}

// Define a class to act as XMLParser delegate
class SharedStringsUniqueCountParserDelegate: XMLParserHelper {
    // Define countValue as a class variable
    var countValue: String?

    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // Extract count attribute value when encountering the start of the element
        if let count = attributeDict["count"] {
            countValue = count
        }
    }
}

//update countSize


// Create XMLParserDelegate
class SharedStringsParserDelegate: XMLParserHelper {
    // Class variables
    var currentText2: String?
    var texts: [String] = []
    var sis: [String] = []

    override func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText2 = string
    }
    
    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t", let text = currentText2 {
            texts.append(text)
        }
        //uniquecount
        if elementName == "si", let text = currentText2 {
            sis.append(text)
        }
    }
}
