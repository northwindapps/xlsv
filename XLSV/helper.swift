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
    // Accumulates every <t> element's text within the current <si> -- an <si>
    // can hold multiple <r><t>...</t></r> runs (rich text: e.g. a bold header
    // followed by plain body text in the same cell), and XMLParser can also
    // split one <t>'s own text across several foundCharacters calls for a
    // long string. currentSiText used to be overwritten ("=") on every call
    // instead of appended, so both cases -- multi-run rich text and any
    // sufficiently long single-run string -- silently kept only whichever
    // fragment was delivered last, truncating (or fully replacing) the text
    // this delegate reports for that <si>. That's exactly what
    // testRangeOperationsBox's "does this cell's content already match an
    // existing shared-string entry" lookup (testStringUniqueAry) uses -- a
    // failed match there silently drops the cell instead of writing it (see
    // the "something went wrong, no index" fallback), which is what was
    // actually happening to a merge-anchor cell holding a multi-paragraph
    // note during a column delete: an empty <row r="8"></row> in the written
    // xlsx confirmed the cell was dropped at write time, not lost on import.
    private var currentSiText: String = ""
    // <rPh> holds a furigana/phonetic-reading hint (e.g. "ヤノ" as the
    // pronunciation guide for "矢野") and carries its own nested <t> --
    // that text is not part of the cell's actual displayed/stored string,
    // so it must be excluded from currentSiText even though it's still a
    // <t> element inside the same <si>.
    private var insideRPh = false
    var texts: [String] = []
    var sis: [String] = []

    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        super.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        if elementName == "si" {
            currentSiText = ""
        } else if elementName == "rPh" {
            insideRPh = true
        }
    }

    override func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "t" && !insideRPh {
            currentSiText += string
        }
    }

    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "rPh" {
            insideRPh = false
        }
        if elementName == "t" && !insideRPh {
            texts.append(currentSiText)
        }
        if elementName == "si" {
            sis.append(currentSiText)
        }
    }
}
