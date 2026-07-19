//
//  service.swift
//  xmlProject
//
//  Created by yujin on 2020/10/21.
//  Copyright © 2020 yujin. All rights reserved.
//

import Foundation
import Zip
import SWXMLHash
import SwiftyXMLParser

class Service {
    var sheetNumber:Int
    var stringContents:[String]
    
    var locations:[String]
    
    var sheetIdx:[Int]
    
    var customFileName:String
    
    var formulaContens:[String]
    
    var siElementCount: Int = 0

    init(imp_sheetNumber:Int,imp_stringContents:[String],imp_locations:[String],imp_idx:[Int],imp_fileName:String,imp_formula:[String]) {
        
        sheetNumber = imp_sheetNumber
        stringContents = imp_stringContents
        locations = imp_locations
        sheetIdx = imp_idx
        customFileName = imp_fileName
        formulaContens = imp_formula
        
        //MinmumSheet number check
        if sheetNumber < 3{
            sheetNumber = 3
        }
        
    }
    
    func export(){
        FileManager.default.deleteWorksheets()
              let semaphore = DispatchSemaphore(value: 1)
              DispatchQueue.global().async {
                  
                let adp = Adapter(imp_content: self.stringContents, imp_location: self.locations, imp_sheetIdx: self.sheetIdx, imp_sheetSize:self.sheetNumber,imp_formula:self.formulaContens)
              
                  var temp_ary = [String]()
                  var temp_string = ""
                  (temp_ary,temp_string) = adp.createContentArys()
                  
                  Styles().export()
              
                  Theme().export()
              
                  Rels().export()
              
                  App().export()
              
                  Core().export()
                  
                  XlRels().export(sheetSize: self.sheetNumber)
              
                  ContentType().export(sheetSize: self.sheetNumber)
              
                  Workbook().export(sheetSize: self.sheetNumber)
              
                  Sharedstring(imp_sharedString: temp_string).export(sheetSize: self.sheetNumber)
                  
                  Sheet(imp_sheetContents: temp_ary).export(sheetSize: self.sheetNumber)
                  
                  semaphore.wait()
                  sleep(5)
                  semaphore.signal()
                  print("Finished")
                  
              }
              

         //zip folder here
         DispatchQueue.global().async {
          semaphore.wait()
            sleep(5)
            self.writeXlsxSandBox(path: (FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents"))!,fileName: self.customFileName)
         }
         semaphore.signal()
        
        
    }
    
    //making now style
    func testExtractStyle(url:URL? = nil)->String?{
        if let url2 = url{
            var modifiedPartNum = 0
            do{
            let xmlData = try Data(contentsOf: url2)
            
                let parser = XMLParser(data: xmlData)
                // Set XMLParserDelegate
                let delegate = CustomXMLParserDelegate()
                parser.delegate = delegate
                
                var patternFound = false
                // Start parsing
                if parser.parse() {
                    // Retrieve the extracted part
                    let extractedPart = delegate.extractedPart
                    //print(extractedPart)
                }
                
                //regular expression
                var xmlString = try? String(contentsOf: url2)
                if (xmlString != nil){
                    let generalNumFmt = "<xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyNumberFormat=\"1\"/>"
                    
                    if !xmlString!.contains(generalNumFmt) {
                        xmlString! = xmlString!.replacingOccurrences(of: "</cellXfs>", with: generalNumFmt + "</cellXfs>")
                        modifiedPartNum += 1
                    }
                    
                    
                    //edit it first. append numFmtId 14 Date
                    let dateNumFmt = "<xf numFmtId=\"14\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyNumberFormat=\"1\"/>"
                    
                    if !xmlString!.contains(dateNumFmt) {
                        xmlString! = xmlString!.replacingOccurrences(of: "</cellXfs>", with: dateNumFmt + "</cellXfs>")
                        modifiedPartNum += 1
                    }
                    
                    let timeNumFmt = "<xf numFmtId=\"20\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyNumberFormat=\"1\"/>"
                    
                    if !xmlString!.contains(timeNumFmt) {
                        xmlString! = xmlString!.replacingOccurrences(of: "</cellXfs>", with: timeNumFmt + "</cellXfs>")
                        modifiedPartNum += 1
                    }
                    
                    
                    
                    let xml = XMLHash.parse(xmlString!)
                    let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate

                    var numFmts = [String]()
                    var formatCodes = [String]()
                    // Assuming `xml` is your XML object
                    for child in xml.children.first!.children[0].children {
                        if child.element?.name == "numFmt" {
                            // Get the attributes
                            let attributes = child.element?.allAttributes
                            // Extract numFmtId
                            if let numFmtId = attributes!["numFmtId"]?.text {
                                print("numFmtId:", numFmtId)
                                numFmts.append(numFmtId)
                            }
                            // Extract formatCode
                            if let formatCode = attributes!["formatCode"]?.text {
                                print("formatCode:", formatCode)
                                formatCodes.append(formatCode)
                            }
                        }
                    }
                    
                    var numFmtIds = [Int]()
                    // Assuming `xml` is your XML object
                    for child in xml.children.first!.children.first(where: { $0.element?.name == "cellXfs" })!.children {
                        if let id = child.element?.allAttributes["numFmtId"]?.text {
                            numFmtIds.append(Int(id) ?? -1)
                        }
                    }
                    
                    
                    var cellXfs = [Int]()
                    // Assuming `xml` is your XML object
                    for child in xml.children.first!.children.first(where: { $0.element?.name == "cellXfs" })!.children {
                        if let borderId = child.element?.allAttributes["borderId"]?.text {
                            cellXfs.append(Int(borderId) ?? -1)
                        }
                    }
                    
                    var cellStyleXfs = [Int]()
                    // Assuming `xml` is your XML object
                    for child in xml.children.first!.children.first(where: { $0.element?.name == "cellStyleXfs" })!.children {
                        if let borderId = child.element?.allAttributes["borderId"]?.text {
                            cellStyleXfs.append(Int(borderId) ?? -1)
                        }
                    }
                    
                    
                    var border_lefts = [Int]()
                    var border_rights = [Int]()
                    var border_bottoms = [Int]()
                    var border_tops = [Int]()
                    // Actual per-side border style (e.g. "thin", "medium", "dashed") and
                    // color, indexed by borderId in lockstep with border_lefts/rights/
                    // tops/bottoms above (same append pattern, so they stay aligned with
                    // that pre-existing borderId indexing already used by cellForItemAt).
                    var borderLeftStyles = [String]()
                    var borderLeftColors = [String]()
                    var borderRightStyles = [String]()
                    var borderRightColors = [String]()
                    var borderTopStyles = [String]()
                    var borderTopColors = [String]()
                    var borderBottomStyles = [String]()
                    var borderBottomColors = [String]()
                    var debugBorderColorLogCount = 0
                    func borderSideColor(_ sideElement: XMLIndexer) -> String {
                        guard let colorEl = sideElement.children.first(where: { $0.element?.name == "color" }) else {
                            if debugBorderColorLogCount < 15 {
                                print("DEBUG-BORDERCOLOR no <color> child at all -- allAttributes=\(sideElement.element?.allAttributes.mapValues { $0.text } ?? [:])")
                                debugBorderColorLogCount += 1
                            }
                            return ""
                        }
                        var result = ""
                        if let rgb = colorEl.element?.allAttributes["rgb"]?.text {
                            result = hexColorString(fromARGB: rgb) ?? ""
                            if debugBorderColorLogCount < 15 {
                                print("DEBUG-BORDERCOLOR rgb=\(rgb) -> \(result)")
                                debugBorderColorLogCount += 1
                            }
                        } else if let themeStr = colorEl.element?.allAttributes["theme"]?.text,
                                  let themeIdx = Int(themeStr),
                                  themeIdx >= 0, themeIdx < appd.themeColors.count,
                                  !appd.themeColors[themeIdx].isEmpty {
                            let tint = Double(colorEl.element?.allAttributes["tint"]?.text ?? "0") ?? 0
                            result = applyThemeTint(hex: appd.themeColors[themeIdx], tint: tint)
                            if debugBorderColorLogCount < 15 {
                                print("DEBUG-BORDERCOLOR theme=\(themeStr) tint=\(tint) themeColors[\(themeIdx)]=\(appd.themeColors[themeIdx]) -> \(result)")
                                debugBorderColorLogCount += 1
                            }
                        } else if debugBorderColorLogCount < 15 {
                            print("DEBUG-BORDERCOLOR <color> present but neither rgb nor usable theme -- attrs=\(colorEl.element?.allAttributes.mapValues { $0.text } ?? [:])")
                            debugBorderColorLogCount += 1
                        }
                        return result
                    }
                    // Assuming `xml` is your XML object
                    for child in xml.children.first!.children.first(where: { $0.element?.name == "borders" })!.children{
                        if child.children.count > 0{
                            border_lefts.append(0)
                            border_rights.append(0)
                            border_bottoms.append(0)
                            border_tops.append(0)
                            borderLeftStyles.append("")
                            borderLeftColors.append("")
                            borderRightStyles.append("")
                            borderRightColors.append("")
                            borderTopStyles.append("")
                            borderTopColors.append("")
                            borderBottomStyles.append("")
                            borderBottomColors.append("")
                            for gChild in child.children{
                                if gChild.element?.name == "left"{
                                    let leftCount = gChild.children.count
                                    border_lefts[border_lefts.count - 1] = leftCount
                                    borderLeftStyles[borderLeftStyles.count - 1] = gChild.element?.allAttributes["style"]?.text ?? ""
                                    borderLeftColors[borderLeftColors.count - 1] = borderSideColor(gChild)
                                }

                                if gChild.element?.name == "right"{
                                    let rightCount = gChild.children.count
                                    border_rights[border_rights.count - 1] = rightCount
                                    borderRightStyles[borderRightStyles.count - 1] = gChild.element?.allAttributes["style"]?.text ?? ""
                                    borderRightColors[borderRightColors.count - 1] = borderSideColor(gChild)
                                }

                                if gChild.element?.name == "top"{
                                    let topCount = gChild.children.count
                                    border_tops[border_tops.count - 1] = topCount
                                    borderTopStyles[borderTopStyles.count - 1] = gChild.element?.allAttributes["style"]?.text ?? ""
                                    borderTopColors[borderTopColors.count - 1] = borderSideColor(gChild)
                                }

                                if gChild.element?.name == "bottom"{
                                    let bottomCount = gChild.children.count
                                    border_bottoms[border_bottoms.count - 1] = bottomCount
                                    borderBottomStyles[borderBottomStyles.count - 1] = gChild.element?.allAttributes["style"]?.text ?? ""
                                    borderBottomColors[borderBottomColors.count - 1] = borderSideColor(gChild)
                                }

                            }
                        }
                    }
                    
                    // fontId/fillId/alignment per style index, parallel to cellXfs/numFmtIds
                    // above. <alignment> is inline on the <xf> itself (not a separate
                    // table like fonts/fills/borders), so it's read in the same pass.
                    var xfFontIds = [Int]()
                    var xfFillIds = [Int]()
                    var xfHorizontalAligns = [String]()
                    var xfVerticalAligns = [String]()
                    var xfWrapTexts = [Bool]()
                    for child in xml.children.first!.children.first(where: { $0.element?.name == "cellXfs" })!.children {
                        xfFontIds.append(Int(child.element?.allAttributes["fontId"]?.text ?? "") ?? -1)
                        xfFillIds.append(Int(child.element?.allAttributes["fillId"]?.text ?? "") ?? -1)
                        if let alignmentEl = child.children.first(where: { $0.element?.name == "alignment" }) {
                            xfHorizontalAligns.append(alignmentEl.element?.allAttributes["horizontal"]?.text ?? "")
                            xfVerticalAligns.append(alignmentEl.element?.allAttributes["vertical"]?.text ?? "")
                            xfWrapTexts.append((alignmentEl.element?.allAttributes["wrapText"]?.text ?? "0") != "0")
                        } else {
                            xfHorizontalAligns.append("")
                            xfVerticalAligns.append("")
                            xfWrapTexts.append(false)
                        }
                    }

                    // Font table (size/color/bold/italic/underline/strike), indexed by fontId.
                    var fontSizes = [String]()
                    var fontColors = [String]()
                    var fontBolds = [Bool]()
                    var fontItalics = [Bool]()
                    var fontUnderlines = [Bool]()
                    var fontStrikes = [Bool]()
                    if let fontsSection = xml.children.first!.children.first(where: { $0.element?.name == "fonts" }) {
                        for fontChild in fontsSection.children {
                            var size = ""
                            var color = ""
                            var bold = false
                            var italic = false
                            var underline = false
                            var strike = false
                            for prop in fontChild.children {
                                switch prop.element?.name {
                                case "sz":
                                    size = prop.element?.allAttributes["val"]?.text ?? ""
                                case "color":
                                    if let rgb = prop.element?.allAttributes["rgb"]?.text {
                                        color = hexColorString(fromARGB: rgb) ?? ""
                                    } else if let themeStr = prop.element?.allAttributes["theme"]?.text,
                                              let themeIdx = Int(themeStr),
                                              themeIdx >= 0, themeIdx < appd.themeColors.count,
                                              !appd.themeColors[themeIdx].isEmpty {
                                        let tint = Double(prop.element?.allAttributes["tint"]?.text ?? "0") ?? 0
                                        color = applyThemeTint(hex: appd.themeColors[themeIdx], tint: tint)
                                    }
                                case "b":
                                    bold = (prop.element?.allAttributes["val"]?.text ?? "1") != "0"
                                case "i":
                                    italic = (prop.element?.allAttributes["val"]?.text ?? "1") != "0"
                                case "u":
                                    underline = (prop.element?.allAttributes["val"]?.text ?? "single") != "none"
                                case "strike":
                                    strike = (prop.element?.allAttributes["val"]?.text ?? "1") != "0"
                                default:
                                    break
                                }
                            }
                            fontSizes.append(size)
                            fontColors.append(color)
                            fontBolds.append(bold)
                            fontItalics.append(italic)
                            fontUnderlines.append(underline)
                            fontStrikes.append(strike)
                        }
                    }

                    // Fill table (background color), indexed by fillId. Only solid-pattern
                    // fills have a meaningful cell background -- fgColor is the visible
                    // color for patternType="solid" (bgColor is used for other pattern
                    // types like stripes, which we don't render).
                    var fillColors = [String]()
                    if let fillsSection = xml.children.first!.children.first(where: { $0.element?.name == "fills" }) {
                        for fillChild in fillsSection.children {
                            var color = ""
                            if let patternFill = fillChild.children.first(where: { $0.element?.name == "patternFill" }) {
                                let patternType = patternFill.element?.allAttributes["patternType"]?.text ?? ""
                                if patternType == "solid",
                                   let fgColor = patternFill.children.first(where: { $0.element?.name == "fgColor" }) {
                                    if let rgb = fgColor.element?.allAttributes["rgb"]?.text {
                                        color = hexColorString(fromARGB: rgb) ?? ""
                                    } else if let themeStr = fgColor.element?.allAttributes["theme"]?.text,
                                              let themeIdx = Int(themeStr),
                                              themeIdx >= 0, themeIdx < appd.themeColors.count,
                                              !appd.themeColors[themeIdx].isEmpty {
                                        let tint = Double(fgColor.element?.allAttributes["tint"]?.text ?? "0") ?? 0
                                        color = applyThemeTint(hex: appd.themeColors[themeIdx], tint: tint)
                                    }
                                }
                            }
                            fillColors.append(color)
                        }
                    }

                    appd.cellXfs = cellXfs
                    appd.cellStyleXfs = cellStyleXfs
                    appd.border_lefts = border_lefts
                    appd.border_rights  = border_rights
                    appd.border_bottoms = border_bottoms
                    appd.border_tops = border_tops
                    appd.borderLeftStyles = borderLeftStyles
                    appd.borderLeftColors = borderLeftColors
                    appd.borderRightStyles = borderRightStyles
                    appd.borderRightColors = borderRightColors
                    appd.borderTopStyles = borderTopStyles
                    appd.borderTopColors = borderTopColors
                    appd.borderBottomStyles = borderBottomStyles
                    appd.borderBottomColors = borderBottomColors
                    appd.formatCodes = formatCodes
                    appd.numFmts = numFmts
                    appd.numFmtIds = numFmtIds
                    appd.xfFontIds = xfFontIds
                    appd.xfFillIds = xfFillIds
                    appd.xfHorizontalAligns = xfHorizontalAligns
                    appd.xfVerticalAligns = xfVerticalAligns
                    appd.xfWrapTexts = xfWrapTexts
                    appd.fontSizes = fontSizes
                    appd.fontColors = fontColors
                    appd.fontBolds = fontBolds
                    appd.fontItalics = fontItalics
                    appd.fontUnderlines = fontUnderlines
                    appd.fontStrikes = fontStrikes
                    appd.fillColors = fillColors

                    return xmlString
                }
            }catch{
                print("no style file")
                return nil
            }
        }
        return nil
    }

    // xlsx <color rgb="..."/> is an 8-digit ARGB hex string (e.g. "FFFF0000"), or
    // occasionally 6-digit RGB. Returns a "#RRGGBB" string the renderer can use, or
    // nil if the value isn't a well-formed hex color.
    func hexColorString(fromARGB rgb: String) -> String? {
        let hex = rgb.count == 8 ? String(rgb.suffix(6)) : rgb
        guard hex.count == 6, UInt32(hex, radix: 16) != nil else { return nil }
        return "#" + hex.uppercased()
    }

    // Resolves xl/theme/theme1.xml's <a:clrScheme> into appd.themeColors, a 12-slot
    // "#RRGGBB" table indexed the way <color theme="N"/> actually refers to slots.
    // Note this is NOT the literal <a:clrScheme> child order (dk1, lt1, dk2, lt2, ...) --
    // Excel swaps the first two pairs when resolving a theme index, so index 0 is lt1
    // (Background 1), 1 is dk1 (Text 1), 2 is lt2, 3 is dk2; this is a well-documented
    // OOXML quirk, not a bug here.
    func testExtractTheme(url: URL? = nil) {
        guard let url2 = url, let xmlString = try? String(contentsOf: url2) else { return }
        let xml = XMLHash.parse(xmlString)
        guard let root = xml.children.first,
              let clrScheme = findElement(root, named: "clrScheme") else { return }

        let slotNames: Set<String> = ["dk1", "lt1", "dk2", "lt2", "accent1", "accent2",
                                       "accent3", "accent4", "accent5", "accent6",
                                       "hlink", "folHlink"]
        var schemeColors = [String: String]()
        for child in clrScheme.children {
            let slot = localName(child.element?.name)
            guard slotNames.contains(slot), let colorChild = child.children.first else { continue }
            let colorName = localName(colorChild.element?.name)
            var hex = ""
            if colorName == "srgbClr" {
                hex = colorChild.element?.allAttributes["val"]?.text ?? ""
            } else if colorName == "sysClr" {
                hex = colorChild.element?.allAttributes["lastClr"]?.text ?? ""
            }
            if let resolved = hexColorString(fromARGB: hex) {
                schemeColors[slot] = resolved
            }
        }

        let indexOrder = ["lt1", "dk1", "lt2", "dk2", "accent1", "accent2", "accent3",
                           "accent4", "accent5", "accent6", "hlink", "folHlink"]
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appd.themeColors = indexOrder.map { schemeColors[$0] ?? "" }
        print("DEBUG-THEME schemeColors=\(schemeColors) resolvedThemeColors(index0..11)=\(appd.themeColors)")
    }

    // Strips a namespace prefix ("a:dk1" -> "dk1") since XMLHash's element name may or
    // may not retain it depending on how the parser handles theme1.xml's "a:" prefix.
    private func localName(_ name: String?) -> String {
        guard let name = name else { return "" }
        if let colonIdx = name.firstIndex(of: ":") {
            return String(name[name.index(after: colonIdx)...])
        }
        return name
    }

    // theme1.xml nests clrScheme a couple of levels down (theme > themeElements >
    // clrScheme); search rather than hardcode the depth so minor structural
    // differences between Excel versions don't break this.
    private func findElement(_ indexer: XMLIndexer, named target: String) -> XMLIndexer? {
        for child in indexer.children {
            if localName(child.element?.name) == target {
                return child
            }
            if let found = findElement(child, named: target) {
                return found
            }
        }
        return nil
    }

    // Excel's <color theme="N" tint="..."/> tint/shade is a luminance (HSL) adjustment --
    // not the HSB adjustment UIKit's own hue/brightness APIs use -- so this is done by
    // hand to match what Excel actually renders. tint is in [-1, 1]; negative darkens,
    // positive lightens, both by scaling toward black/white in HSL lightness space.
    func applyThemeTint(hex: String, tint: Double) -> String {
        guard tint != 0, hex.hasPrefix("#"), hex.count == 7,
              let rgbValue = UInt32(hex.dropFirst(), radix: 16) else { return hex }

        let r = Double((rgbValue >> 16) & 0xFF) / 255.0
        let g = Double((rgbValue >> 8) & 0xFF) / 255.0
        let b = Double(rgbValue & 0xFF) / 255.0

        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        var h = 0.0
        var s = 0.0
        let l = (maxC + minC) / 2.0
        if maxC != minC {
            let d = maxC - minC
            s = l > 0.5 ? d / (2.0 - maxC - minC) : d / (maxC + minC)
            if maxC == r {
                h = (g - b) / d + (g < b ? 6.0 : 0.0)
            } else if maxC == g {
                h = (b - r) / d + 2.0
            } else {
                h = (r - g) / d + 4.0
            }
            h /= 6.0
        }

        let newL = tint < 0 ? l * (1.0 + tint) : l * (1.0 - tint) + tint
        let clampedL = min(max(newL, 0.0), 1.0)

        func hue2rgb(_ p: Double, _ q: Double, _ t0: Double) -> Double {
            var t = t0
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1.0 / 6.0 { return p + (q - p) * 6.0 * t }
            if t < 1.0 / 2.0 { return q }
            if t < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - t) * 6.0 }
            return p
        }

        let outR: Double
        let outG: Double
        let outB: Double
        if s == 0 {
            outR = clampedL
            outG = clampedL
            outB = clampedL
        } else {
            let q = clampedL < 0.5 ? clampedL * (1.0 + s) : clampedL + s - clampedL * s
            let p = 2.0 * clampedL - q
            outR = hue2rgb(p, q, h + 1.0 / 3.0)
            outG = hue2rgb(p, q, h)
            outB = hue2rgb(p, q, h - 1.0 / 3.0)
        }

        let ri = Int((outR * 255.0).rounded())
        let gi = Int((outG * 255.0).rounded())
        let bi = Int((outB * 255.0).rounded())
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    //making now
    func testDeleteString(url:URL? = nil, index:String?) -> String?{
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            var xmlString = try? String(contentsOf: url2)
            let xml = XMLHash.parse(xmlString!)
            
            // Define the regular expression pattern D3
            let pattern = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
            
            // Create the regular expression object
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches = regex.matches(in: xmlString!, range: range)
            // Extract matching substrings
            if let match = matches.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    let matchingSubstring = xmlString![matchRange].description
                    return xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
                }
            }
            
            // Define the regular expression pattern D3
            let pattern2 = "<c[^>]*r=\"\(String(index!))\"[^>]*>.*?</c>"
            //#"<c\s+r="B1".*?</c>"#
            
            // Create the regular expression object
            guard let regex = try? NSRegularExpression(pattern: pattern2, options: []) else {
                fatalError("Failed to create regular expression")
            }
            
            // Find matches in the XML string
            let range2 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
            let matches2 = regex.matches(in: xmlString!, range: range2)
            // Extract matching substrings
            if let match = matches2.first{
                if let matchRange = Range(match.range, in: xmlString!) {
                    let matchingSubstring = xmlString![matchRange].description
                    //<c>...</c> check if the ms has this structure.
                    return xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
                }
            }
        }
        return nil
    }
    
    func testDeleteStringBulk(url: URL? = nil, index: [String]? = nil) -> String? {
        guard let url2 = url, let indices = index else { return nil }
        
        do {
            // Read the XML data
            let xmlData = try Data(contentsOf: url2)
            var xmlString = String(data: xmlData, encoding: .utf8)
            
            for singleIndex in indices {
                // Define the regular expression pattern for the current index
                //let pattern = "<c[^>]*r=\"\(singleIndex)\"[^>]*>(.*?)</c>"
                let pattern = "<c[^>]*r=\"\(singleIndex)(?!\\d)\"[^>]*>(.*?)</c>"
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                    fatalError("Failed to create regular expression")
                }
                
                // Find matches in the XML string
                let range = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
                if let match = regex.firstMatch(in: xmlString!, range: range) {
                    if let matchRange = Range(match.range, in: xmlString!) {
                        let matchingSubstring = xmlString![matchRange].description
                        
                        //matchingSubstring="<c s=\"1\" r=\"B10\"/><c r=\"C10\" t=\"s\"><v>9</v></c>"
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
                        continue
                    }
                }
                
                // Define the second pattern
                let pattern2 = "<c[^>]*r=\"\(singleIndex)(?!\\d)\"[^>]*>.*?</c>"
                guard let regex2 = try? NSRegularExpression(pattern: pattern2, options: []) else {
                    fatalError("Failed to create regular expression")
                }
                
                // Find matches in the XML string for the second pattern
                let range2 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
                if let match2 = regex2.firstMatch(in: xmlString!, range: range2) {
                    if let matchRange2 = Range(match2.range, in: xmlString!) {
                        let matchingSubstring = xmlString![matchRange2].description
                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: "")
                        continue
                    }
                }
            }
            
            return xmlString
        } catch {
            print("Error reading or processing file: \(error.localizedDescription)")
            return nil
        }
    }

    
    // Builds the <c r="..."> fragment for one cell, given its raw content and (if any)
    // preserved style index. All insertion/replacement paths in testUpdateString below
    // funnel through this so the formula/numeric/shared-string branching lives in one
    // place instead of being duplicated at every call site (as the old version did).
    // content is stored WITH its leading "=" for formula cells (e.g. "=A1+B2") -- xlsx's
    // own <f> element never includes that marker, so it's dropped here via dropFirst().
    private func buildCellElement(ref: String, styleIdx: Int, content: String, calculated: [String], calculatedLocation: [String], sharedStringIndex: Int?) -> String {
        let styleAttr = styleIdx > 0 ? " s=\"\(styleIdx)\"" : ""
        let trimmed = content.replacingOccurrences(of: " ", with: "")

        if trimmed.hasPrefix("=") {
            let formula = String(trimmed.dropFirst())
            if let fIdx = calculatedLocation.firstIndex(of: ref), fIdx < calculated.count {
                let cachedValue = calculated[fIdx]
                let typeAttr = Double(cachedValue) == nil ? " t=\"str\"" : ""
                return "<c r=\"\(ref)\"\(styleAttr)\(typeAttr)><f>\(formula)</f><v>\(cachedValue)</v></c>"
            }
            return "<c r=\"\(ref)\"\(styleAttr)><f>\(formula)</f></c>"
        } else if Double(trimmed) != nil {
            return "<c r=\"\(ref)\"\(styleAttr)><v>\(trimmed)</v></c>"
        } else if let ssIdx = sharedStringIndex {
            return "<c r=\"\(ref)\"\(styleAttr) t=\"s\"><v>\(ssIdx)</v></c>"
        } else {
            return "<c r=\"\(ref)\"\(styleAttr) t=\"s\"><v>\(content)</v></c>"
        }
    }

    // Read-only SWXMLHash lookups for testUpdateString below -- these only ever answer
    // "does this row/cell already exist", never build replacement text. XMLElement's own
    // .description re-serializes attributes from an unordered Dictionary and always
    // normalizes self-closing tags away (see SWXMLHash's XMLElement.swift), so it isn't
    // guaranteed to reproduce the original bytes an exact-match splice into xmlString needs
    // -- that's what originalElementRange below is for.
    private func sheetDataRows(in xmlString: String) -> [XMLIndexer] {
        let xml = XMLHash.parse(xmlString)
        return xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children ?? []
    }

    private func rowExists(_ rowNumber: String, in rows: [XMLIndexer]) -> Bool {
        rows.contains { $0.element?.attribute(by: "r")?.text == rowNumber }
    }

    private func cellExists(_ ref: String, inRow rowNumber: String, rows: [XMLIndexer]) -> Bool {
        rows.first(where: { $0.element?.attribute(by: "r")?.text == rowNumber })?
            .children.contains { $0.element?.attribute(by: "r")?.text == ref } ?? false
    }

    // Carves the exact original text of a <tag ... r="attributeValue" ...> element
    // (self-closing or with a separate close tag) out of xmlString. Anchored on the
    // *quoted* attribute value ("r=\"B1\"") instead of a regex -- the closing quote makes
    // the match exact, so "B1" can never accidentally match inside "B10"/"B11" the way a
    // bare substring search would, without needing a regex lookahead to guard it. The
    // forward/backward scans below assume the well-formed, non-nested OOXML sheetData
    // shape this app writes (a <row> only ever contains <c> children, a <c> never
    // contains another <c> or <row>), which is what makes a plain scan for the first
    // ">"/matching close tag exact without a general-purpose XML parser.
    private func originalElementRange(tag: String, attributeValue: String, in xmlString: String) -> Range<String.Index>? {
        guard let quoteRange = xmlString.range(of: "r=\"\(attributeValue)\"") else { return nil }
        guard let tagOpenRange = xmlString.range(of: "<\(tag) ", options: .backwards, range: xmlString.startIndex..<quoteRange.upperBound) else {
            return nil
        }
        guard let firstCloseAngle = xmlString.range(of: ">", range: quoteRange.upperBound..<xmlString.endIndex) else {
            return nil
        }

        if xmlString[xmlString.index(before: firstCloseAngle.lowerBound)] == "/" {
            // Self-closing: <tag .../>
            return tagOpenRange.lowerBound..<firstCloseAngle.upperBound
        }

        guard let closeTagRange = xmlString.range(of: "</\(tag)>", range: firstCloseAngle.upperBound..<xmlString.endIndex) else {
            return nil
        }
        return tagOpenRange.lowerBound..<closeTagRange.upperBound
    }

    // Patches a single cell into sheetN.xml's <sheetData>, leaving every other byte
    // (row ht=/spans=/customFormat=/thickBot=, sibling cells' s= style, shared-formula
    // compression, style-only placeholder cells) untouched -- as opposed to
    // testUpdateStringBox's old behavior of rebuilding the whole <sheetData> from the
    // whole-sheet content/locationInExcel arrays on every single edit.
    func testUpdateString(url: URL? = nil, content: String, index: String?, sharedStringIndex: Int? = nil, calculated: [String] = [], calculatedLocation: [String] = []) -> String? {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let url2 = url, let index = index else { return nil }

        // Preserve the cell's original style index across the rewrite -- same
        // parallel-array lookup already used live by testDeleteRows/testAddRows/testDeleteCols.
        var styleIdx = -1
        if let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: index) {
            styleIdx = appd.excelStyleIdx[slocatinIdx]
        }

        guard var xmlString = try? String(contentsOf: url2) else { return nil }
        let backUpXmlString = xmlString

        let newElement = buildCellElement(ref: index, styleIdx: styleIdx, content: content, calculated: calculated, calculatedLocation: calculatedLocation, sharedStringIndex: sharedStringIndex)

        let rowNumber = index.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let rows = sheetDataRows(in: xmlString)

        // Case 1: the cell already exists (self-closing <c r="X"/> or open <c r="X">...</c>)
        // -- splice in just that one element.
        if cellExists(index, inRow: rowNumber, rows: rows),
           let cellRange = originalElementRange(tag: "c", attributeValue: index, in: xmlString) {
            xmlString.replaceSubrange(cellRange, with: newElement)
            let validator = XMLValidator()
            return validator.validateXML(xmlString: xmlString) ? xmlString : backUpXmlString
        }

        // Case 2/3: the cell doesn't exist yet -- find its row, then either insert the
        // cell in sorted column order within that row, or create the row itself (in
        // sorted row order) if the row is entirely new.
        if rowExists(rowNumber, in: rows), let rowRange = originalElementRange(tag: "row", attributeValue: rowNumber, in: xmlString) {
            // Row exists but this cell doesn't -- append it, then re-sort just this
            // row's cells by column so the insertion lands in the right place.
            let targetRowTag = String(xmlString[rowRange])
            var rowPart = targetRowTag
            if rowPart.hasSuffix("/>") {
                rowPart = String(rowPart.dropLast(2)) + ">"
            }
            if !rowPart.hasSuffix(">") {
                rowPart += ">"
            }
            let opened = rowPart.replacingOccurrences(of: "</row>", with: "") + newElement + "</row>"
            let candidate = xmlString.replacingOccurrences(of: targetRowTag, with: opened)

            let validator0 = XMLValidator()
            guard validator0.validateXML(xmlString: candidate) else { return backUpXmlString }

            var rebuiltRowPart = ""
            let xml = XMLHash.parse(candidate)
            if let rows2 = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children {
                for row in rows2 {
                    guard row.element?.attribute(by: "r")?.text == rowNumber else { continue }
                    let sortedCells = row.children.sorted { c1, c2 -> Bool in
                        guard let n1 = c1.element?.attribute(by: "r")?.text, let i1 = extractIndices(from: n1),
                              let n2 = c2.element?.attribute(by: "r")?.text, let i2 = extractIndices(from: n2) else { return false }
                        return i1.column < i2.column
                    }
                    for cell in sortedCells {
                        rebuiltRowPart += cell.description
                    }
                }
            }

            guard !rebuiltRowPart.isEmpty else { return validator0.validateXML(xmlString: candidate) ? candidate : backUpXmlString }
            let final = candidate.replacingOccurrences(of: opened, with: "<row r=\"\(rowNumber)\">" + rebuiltRowPart + "</row>")
            let validator = XMLValidator()
            return validator.validateXML(xmlString: final) ? final : backUpXmlString
        }

        // Row doesn't exist at all -- insert a brand-new <row> right after the
        // <sheetData> open tag, then re-sort all rows by their r= attribute via
        // XMLHash so it lands in numeric row order.
        var replaced = xmlString
        if replaced.contains("<sheetData/>") {
            replaced = replaced.replacingOccurrences(of: "<sheetData/>", with: "<sheetData></sheetData>")
        }
        replaced = replaced.replacingOccurrences(of: "<sheetData>", with: "<sheetData><row r=\"\(rowNumber)\">\(newElement)</row>")

        guard let sheetDataSubstring = extractSheetDataSubstring(from: replaced) else { return backUpXmlString }
        let xml = XMLHash.parse(replaced)
        guard let rows3 = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children else {
            return backUpXmlString
        }
        let sortedRows = rows3.sorted { r1, r2 -> Bool in
            guard let t1 = r1.element?.attribute(by: "r")?.text, let n1 = Int(t1),
                  let t2 = r2.element?.attribute(by: "r")?.text, let n2 = Int(t2) else { return false }
            return n1 < n2
        }
        let rebuiltSheetData = "<sheetData>" + sortedRows.map { $0.description }.joined() + "</sheetData>"
        let final = replaced.replacingOccurrences(of: sheetDataSubstring, with: rebuiltSheetData)
        let validator = XMLValidator()
        return validator.validateXML(xmlString: final) ? final : backUpXmlString
    }
    
    //making row
    func testUpdateRow(url:URL? = nil, index:String?, overWrittenIndice:[String],overWritingIndice:[String]) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
          
            //regular expression
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            
            for (i,each) in overWritingIndice.enumerated(){
                xmlString = xmlString?.replacingOccurrences(of: overWrittenIndice[i], with: each)
            }
            
            xmlString = xmlString?.replacingOccurrences(of: "!____!", with: "")
                    
            var xml = XMLHash.parse(xmlString!)
            //TODO Row Delete?
            let validator = XMLValidator()
            if validator.validateXML(xmlString: xmlString!) {
                print("XML is valid.")
                return xmlString
            } else {
                print("XML is not valid.")
                //print(xmlString)
                return backUpXmlString
            }
        
        }
            
        return nil
    }
    
 
    
    func alphabetOnlyString(text: String) -> String {
       let okayChars = Set("ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
       return text.filter {okayChars.contains($0) }
    }

    func numberOnlyString(text: String) -> String {
       let okayChars = Set("1234567890")
       return text.filter {okayChars.contains($0) }
    }
    
    func testDeleteRows(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "", rowRange:[Int] = [], locationInExcel:[String] = []) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if rowRange.count == 0{
            return nil
        }
        //get style id
        var styleIdx = -1
        let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: String(index!))
        var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
        if (slocatinIdx != nil){
            styleIdx = appd.excelStyleIdx[slocatinIdx!]
        }
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            if xmlData == nil{
                return nil
            }
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            let rowNumber = appd.DEFAULT_ROW_NUMBER
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
                    
            //TODO DELETE ROW
            for(i,each) in rowRange.enumerated(){
                // Retrieve all row tags
                let patternRow = "<row r=\"\(each)\".*?>(.*?)</row>"
                guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                    fatalError("Failed to create regular expression")
                }
                
                // Find all matches in the XML snippet
                let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
                
                var targetRowTag = ""
                for match in matchesRow {
                    // Extract the row number from the match
                    let nsRange = match.range(at: 1) // Use the capture group index
                    if let range = Range(nsRange, in: xmlString!) {
                        if let matchRange = Range(match.range, in: xmlString!) {
                            targetRowTag = String(xmlString![matchRange]).description
                            //assume this case targetRowTag    String    "<row r=\"9\"><c s=\"1\" r=\"B9\"><v>2</v></c></row>"
                            let bkString = xmlString
                            xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: "")
                            let validator = XMLValidator()
                            if validator.validateXML(xmlString: xmlString!) {
                                print("XML is valid.")
                            } else {
                                print("XML is not valid.")
                                xmlString = bkString
                            }
                        }
                    }
                }
            }
            print("locationInExcel",locationInExcel)
            //TODO decrease other rowNums
            for i in 0..<rowNumber {
                if i-rowRange.count > 0 && i >= rowRange.min()!{
                    //
                    var rowNumAry = [Int]()
                    var lettersAry = [String]()
                    var fullAddressAry = [String]()
                    for j in 0..<locationInExcel.count {
                        if numberOnlyString(text: locationInExcel[j]) == String(i){
                            rowNumAry.append(Int(numberOnlyString(text: locationInExcel[j]))!)
                            lettersAry.append(alphabetOnlyString(text: locationInExcel[j]))
                            fullAddressAry.append(locationInExcel[j])
                        }
                    }
                    if rowNumAry.count > 0{
                        // Retrieve all row tags
                        let patternRow = "<row r=\"\(i)\".*?>(.*?)</row>"
                        guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                            fatalError("Failed to create regular expression")
                        }
                        
                        // Find all matches in the XML snippet
                        let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
                        
                        var targetRowTag = ""
                        for match in matchesRow {
                            // Extract the row number from the match
                            let nsRange = match.range(at: 1) // Use the capture group index
                            if let range = Range(nsRange, in: xmlString!) {
                                if let matchRange = Range(match.range, in: xmlString!) {
                                    targetRowTag = String(xmlString![matchRange]).description
                                    //assume this case targetRowTag    String    "<row r=\"9\"><c s=\"1\" r=\"B9\"><v>2</v></c></row>"
                                    let bkString = xmlString
                                    var newTargetRowTag = targetRowTag
                                    let presentRow = "r=\"\(i)\""
                                    let newRow = "r=\"____\(i-rowRange.count)\""
                                    newTargetRowTag = newTargetRowTag.replacingOccurrences(of: presentRow, with: newRow)
                                    
                                    for k in 0..<fullAddressAry.count{
                                        let presentRow = "r=\"\(fullAddressAry[k])\""
                                        let newRow = "r=\"____\(lettersAry[k])\(rowNumAry[k]-rowRange.count)\""
                                        newTargetRowTag = newTargetRowTag.replacingOccurrences(of: presentRow, with: newRow)
                                    }
                                    xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: newTargetRowTag)
                                    let validator = XMLValidator()
                                    if validator.validateXML(xmlString: xmlString!) {
                                        print("XML is valid.")
                                    } else {
                                        print("XML is not valid.")
                                        xmlString = bkString
                                    }
                                }
                            }
                        }
                    }
                }
            }
            xmlString = xmlString?.replacingOccurrences(of: "____", with: "")
            print("deleted\(xmlString)")
            return xmlString
        }
        return nil
    }
    
    func testAddRows(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "", rowRange:[Int] = [], locationInExcel:[String] = []) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //get style id
        var styleIdx = -1
        let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: String(index!))
        var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
        
        if (slocatinIdx != nil){
            styleIdx = appd.excelStyleIdx[slocatinIdx!]
        }
        
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            let rowNumber = appd.DEFAULT_ROW_NUMBER
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
            
            //TODO increase rowNums
            for i in 0..<rowNumber {
                if i >= rowRange.min() ?? -1 {
                    //
                    var rowNumAry = [Int]()
                    var lettersAry = [String]()
                    var fullAddressAry = [String]()
                    for j in 0..<locationInExcel.count {
                        if numberOnlyString(text: locationInExcel[j]) == String(i){
                            print("test row\(i)")
                            rowNumAry.append(Int(numberOnlyString(text: locationInExcel[j]))!)
                            lettersAry.append(alphabetOnlyString(text: locationInExcel[j]))
                            fullAddressAry.append(locationInExcel[j])
                        }
                    }
                    if rowNumAry.count > 0{
                        // Retrieve all row tags
                        let patternRow = "<row r=\"\(i)\".*?>(.*?)</row>"
                        guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                            fatalError("Failed to create regular expression")
                        }
                        
                        // Find all matches in the XML snippet
                        let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
                        
                        var targetRowTag = ""
                        for match in matchesRow {
                            // Extract the row number from the match
                            let nsRange = match.range(at: 1) // Use the capture group index
                            if let range = Range(nsRange, in: xmlString!) {
                                if let matchRange = Range(match.range, in: xmlString!) {
                                    targetRowTag = String(xmlString![matchRange]).description
                                    //assume this case targetRowTag    String    "<row r=\"9\"><c s=\"1\" r=\"B9\"><v>2</v></c></row>"
                                    let bkString = xmlString
                                    let presentRow = "r=\"\(i)\""
                                    let newRow = "r=\"____\(i+rowRange.count)\""
                                    xmlString = xmlString?.replacingOccurrences(of: presentRow, with: newRow)
                                    for k in 0..<fullAddressAry.count{
                                        let presentRow = "r=\"\(fullAddressAry[k])\""
                                        let newRow = "r=\"____\(lettersAry[k])\(rowNumAry[k]+rowRange.count)\""
                                        xmlString = xmlString?.replacingOccurrences(of: presentRow, with: newRow)
                                    }
                                    let validator = XMLValidator()
                                    if validator.validateXML(xmlString: xmlString!) {
                                        print("XML is valid.")
                                    } else {
                                        print("XML is not valid.")
                                        xmlString = bkString
                                    }
                                }
                            }
                        }
                    }
                }
            }
            xmlString = xmlString?.replacingOccurrences(of: "____", with: "")
            print("added\(xmlString)")
            return xmlString
        }
        return nil
    }
    
    func testAddCols(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "", colRange:[Int] = [], locationInExcel:[String] = []) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //appd.numberofColumn you need this
        let newColSize = appd.numberofColumn+colRange.count//DEFAULT_COLUMN_NUMBER numberofColumn
        var newExcelColList = [String]()
        for i in 0..<newColSize{
            newExcelColList.append(GetExcelColumnName(columnNumber: i))
        }
        print(newExcelColList)
        
        if colRange.count == 0{
            return nil
        }
        //
        var rowIntAry = [Int]()
        var lettersAry = [String]()
        var fullAddressAry = [String]()
        for i in 0..<locationInExcel.count {
            for j in 0..<newExcelColList.count {
                if alphabetOnlyString(text: locationInExcel[i]) == newExcelColList[j]{
                    print("test col\(i)")
                        lettersAry.append(alphabetOnlyString(text: locationInExcel[i]))
                        rowIntAry.append(Int(numberOnlyString(text:locationInExcel[i]))!)
                        fullAddressAry.append(locationInExcel[i])
                }
            }
        }
        
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
            var isOutIndex = false
            let startCol = colRange.min()!
            for (i, each) in fullAddressAry.enumerated().reversed() {
                let presentCol = "r=\"\(each)\""
                let rowInt = rowIntAry[i]
                let colIdx = newExcelColList.firstIndex(of: lettersAry[i])!
                if colIdx >= appd.DEFAULT_COLUMN_NUMBER{
                    isOutIndex = true
                }
                let newAddress = newExcelColList[colIdx+colRange.count] + String(rowInt)
                let newCol = "r=\"____\(newAddress)\""
                if colIdx >= startCol{
                    xmlString = xmlString?.replacingOccurrences(of: presentCol, with: newCol)
                }
            }
            
            xmlString = xmlString?.replacingOccurrences(of: "____", with: "")
            let validator = XMLValidator()
            if validator.validateXML(xmlString: xmlString!) {
                print("XML is valid.")
            } else {
                print("XML is not valid.")
                xmlString = backUpXmlString
            }
            if isOutIndex{
                xmlString = backUpXmlString
            }
            
            print("added\(xmlString)")
            return xmlString
        }
        return nil
    }
    
    func testDeleteCols(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "", colRange:[Int] = [], locationInExcel:[String] = []) -> String?{
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //get style id
        var styleIdx = -1
        let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: String(index!))
        var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
        if (slocatinIdx != nil){
            styleIdx = appd.excelStyleIdx[slocatinIdx!]
        }
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            let parser = XMLParser(data: xmlData!)
            // Set XMLParserDelegate
            let delegate = CustomXMLParserDelegate()
            parser.delegate = delegate
            
            //
            let newColSize = appd.numberofColumn
            var newExcelColList = [String]()
            for i in 0..<newColSize{
                newExcelColList.append(GetExcelColumnName(columnNumber: i))
            }
            print(newExcelColList)
            var rowIntAry = [Int]()
            var lettersAry = [String]()
            var fullAddressAry = [String]()
            for i in 0..<locationInExcel.count {
                for j in 1..<newExcelColList.count {
                    if alphabetOnlyString(text: locationInExcel[i]) == newExcelColList[j]{
                        print("test col\(i)")
                            lettersAry.append(alphabetOnlyString(text: locationInExcel[i]))
                            rowIntAry.append(Int(numberOnlyString(text:locationInExcel[i]))!)
                            fullAddressAry.append(locationInExcel[i])
                    }
                }
            }
            
            
            var patternFound = false
            // Start parsing
            if parser.parse() {
                // Retrieve the extracted part
                let extractedPart = delegate.extractedPart
                //print(extractedPart)
            }
            
            //regular expression
            let rowNumber = appd.DEFAULT_ROW_NUMBER
            var xmlString = try? String(contentsOf: url2)
            let backUpXmlString = xmlString
            var xml = XMLHash.parse(xmlString!)
            //TODO DELETE ROW
            for(i,each) in fullAddressAry.enumerated(){
                // Retrieve all row tags
                //<c s=\"1\" r=\"B9\"><v>2</v></c>
//                let patternRow = "<c r=\"\(each)\".*?>(.*?)</c>"
//                let patternRow = #"<c\s+([^>]*)>.*?</c>"#
                let patternRow = #"<c[^>]*>.*?</c>"#
                guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                    fatalError("Failed to create regular expression")
                }
                
                var targetRowTag = ""
                if let regex = try? NSRegularExpression(pattern: patternRow, options: []) {
                    let range = NSRange(xmlString!.startIndex..., in: xmlString!)
                    let matches = regex.matches(in: xmlString!, options: [], range: range)
                    
                    for match in matches {
                        targetRowTag = (xmlString! as NSString).substring(with: match.range)
                        //assume this case targetRowTag    String    "<c s=\"1\" r=\"B9\"><v>2</v></c>"
                        var deleteCols = [String]()
                        let bkString = xmlString
       
                        for m in 0..<colRange.count {
                                let selectedColLetter = GetExcelColumnName(columnNumber: colRange[m])
                                // r="BE1" や r="BE100" などにマッチする正規表現
                                let pattern = "<c[^>]*r=\"\(selectedColLetter)\\d+\"[^>]*>.*?</c>|<c[^>]*r=\"\(selectedColLetter)\\d+\"[^>]*/>"
                                
                                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                                    let range = NSRange(xmlString!.startIndex..., in: xmlString!)
                                    // マッチした部分（タグ全体）を空文字に置換
                                    xmlString = regex.stringByReplacingMatches(in: xmlString!, options: [], range: range, withTemplate: "")
                                }
                            }
                    }
                }
            }
            print("locationInExcel",locationInExcel)
            //TODO decrease other rowNums
            for i in 0..<rowNumber {
                //
                var rowNumAry = [Int]()
                var lettersAry = [String]()
                var fullAddressAry = [String]()
                for j in 0..<locationInExcel.count {
                    if numberOnlyString(text: locationInExcel[j]) == String(i){
                        rowNumAry.append(Int(numberOnlyString(text: locationInExcel[j]))!)
                        lettersAry.append(alphabetOnlyString(text: locationInExcel[j]))
                        fullAddressAry.append(locationInExcel[j])
                    }
                }
                //take care other cells
                for (k,each) in fullAddressAry.enumerated(){
                    // Retrieve all row tags
//                    let patternRow = "<c r=\"\(each)\".*?>(.*?)</c>"
//                    let patternRow = #"<c\s+([^>]*)>.*?</c>"#
                    let patternRow = #"<c[^>]*>.*?</c>"#
                    guard let regexRow = try? NSRegularExpression(pattern: patternRow, options: []) else{
                        fatalError("Failed to create regular expression")
                    }
                    var targetRowTag = ""
                    if let regex = try? NSRegularExpression(pattern: patternRow, options: []) {
                        let range = NSRange(xmlString!.startIndex..., in: xmlString!)
                        let matches = regex.matches(in: xmlString!, options: [], range: range)
                        for match in matches {
                            targetRowTag = (xmlString! as NSString).substring(with: match.range)
                            if !targetRowTag.hasSuffix("</c>") || !targetRowTag.hasPrefix("<c") || !targetRowTag.contains(each){
                                continue
                            }
                            //assume this case targetRowTag    String    "<c s=\"1\" r=\"B9\"><v>2</v></c>"
                            let bkString = xmlString
                            var newTargetRowTag = targetRowTag
                            let presentRow = "r=\"\(each)\""
                            let letterKIdx = newExcelColList.firstIndex(of: lettersAry[k]) ?? -1
                            let newAddress = GetExcelColumnName(columnNumber:letterKIdx-colRange.count) + String(rowNumAry[k])
                            let newRow = "r=\"____\(newAddress)\""
                            if letterKIdx > 0 && GetExcelColumnName(columnNumber:letterKIdx-colRange.count) != ""{
                                newTargetRowTag = newTargetRowTag.replacingOccurrences(of: presentRow, with: newRow)
                                xmlString = xmlString?.replacingOccurrences(of: targetRowTag, with: newTargetRowTag)
                            }
                            
                           
                        }
                    }
                }
            }
            xmlString = xmlString?.replacingOccurrences(of: "____", with: "")
            let validator = XMLValidator()
            if validator.validateXML(xmlString: xmlString!) {
                print("XML is valid.")
            } else {
                print("XML is not valid.")
                xmlString = backUpXmlString
            }
            print("deleted\(xmlString)")
            return xmlString
        }
        return nil
    }
    
    func GetExcelColumnName(columnNumber: Int) -> String
    {
        var dividend = columnNumber
        var columnName = ""
        var modulo = 0
        
        while (dividend > 0)
        {
            modulo = (dividend - 1) % 26;
            columnName = String(65 + modulo) + "," + columnName
            dividend = Int((dividend - modulo) / 26)
        }
        
        var alphabetsAry = [String]()
        alphabetsAry = columnName.components(separatedBy: ",")
        
        var fstring = ""
        for i in 0..<alphabetsAry.count {
            let a:Int! = Int(alphabetsAry[i])
            if a != nil{
                let b:UInt8 = UInt8(a)
                fstring.append(String(UnicodeScalar(b)))
            }
            
            
        }
        
        return fstring
    }
    
    func testStringOldUniqueCount(url:URL? = nil){
        if let url2 = url{
            var xmlString = try? String(contentsOf: url2)
            if (xmlString != nil){
                let pattern = "uniqueCount=\"([^\"]+)\"" //"count=\"([^\"]+)\""
                
                // Create a regular expression object
                guard let regex = try? NSRegularExpression(pattern: pattern) else {
                    fatalError("Invalid regular expression pattern")
                }
                
                // Search for matches in the XML string
                if let match = regex.firstMatch(in: xmlString!, range: NSRange(xmlString!.startIndex..., in: xmlString!)) {
                    // Extract the matched substring
                    let countPartRange = Range(match.range(at: 1), in: xmlString!)!
                    let countPart = String(xmlString![countPartRange])
                    
                    print("Extracted count part:", countPart)
                } else {
                    print("No match found")
                }
            }
        }
    }

    func checkSharedStringsIndex(url: URL? = nil, SSlist: [String] = [], word: String) -> (Int?, String?) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
            
        // Ignore formulas
        if trimmed.hasPrefix("=") {
            return (nil, nil)
        }
        
        // Ignore empty
        if trimmed.isEmpty {
            return (nil, nil)
        }
        
        // Ignore numbers (more robust)
        if Double(trimmed) != nil {
            return (nil, nil)
        }
        
        // Ensure URL exists
        guard let url2 = url else {
            return (nil, nil)
        }

        guard var xmlString = try? String(contentsOf: url2, encoding: .utf8) else {
            return (nil, nil)
        }

        if let idx = SSlist.firstIndex(of: word) {
            print("String exists at", idx)
            return (idx, xmlString)
        }

        print("String not exists. Inserting: \(word)")
        
        if let range = xmlString.range(of: "</sst>") {
            let newSIElement = "<si><t>\(word)</t></si>"
            xmlString.replaceSubrange(range, with: "\(newSIElement)</sst>")
            return (SSlist.count, xmlString)
        } else if let range = xmlString.range(of: "/>", options: .backwards) {
            let newSIElement = "><si><t>\(word)</t></si></sst>"
            xmlString.replaceSubrange(range, with: newSIElement)
            return (SSlist.count, xmlString)
        } else {
            print("Failed to find any sst tag end.")
            return (nil, nil)
        }
    }

    
    
    func testSandBox(fp: String = "", url: URL? = nil) -> URL? {
        do {
                // Get the sandbox directory for documents
                if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
                //
                if FileManager.default.fileExists(atPath: fp) {
                    // The specified path exists, continue with your code
                    print("File or directory exists at path: \(fp)")
                    let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                    let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                            
                    // Check if the subdirectory already exists
                    if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                        // Create the subdirectory
                        try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                        print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                    } else {
                        // Subdirectory already exists
                        print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                        var files = try FileManager.default.contentsOfDirectory(at:
                                                                                    subdirectoryURL, includingPropertiesForKeys: nil)
                        for fileURL in files {
                           do {
                               try FileManager.default.removeItem(at: fileURL)
                               
                               print(" testSandBox Deleted file:", fileURL)
                           } catch {
                               print("Error deleting file:", error)
                           }
                        }
                        
                        files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                        print("Subdirectory is now empty",files)
                    }
                    
                    // Construct the URL for the destination file
                    let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                   
                    // Check if the file already exists at the destination
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        print("File already exists at the destination.")
                        // Remove destination file if it already exists
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                    } else {
                        // Move the file to the subdirectory
                        try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                        print("File moved successfully to: \(destinationURL.path)")
                    }
                    
                    do {
                        //unzip
                        let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                        print("File unzipped successfully.")
                    } catch {
                        print("Error unzipping file: \(error)")
                    }
                    
                    
                    
                    do {
                        //delete imported2.zip or imported2.xlsx
                        try FileManager.default.removeItem(at: destinationURL)
                        print("Deleted zip file:", destinationURL)
                    } catch {
                        print("Error deleting file:", error)
                    }
                    
                    //shardString update test
                    let shardStringXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("sharedStrings.xml")
                    
                    //value and string update test
                    let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet1.xml")
                    
                    //extract sytles read only
                    let themeXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("theme").appendingPathComponent("theme1.xml")
                    testExtractTheme(url: themeXMLURL)
                    let styleXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("styles.xml")
                    let modifiedStylesStr = testExtractStyle(url:styleXMLURL)
                    //update to it contains date numFmt and other format
                    if (modifiedStylesStr != nil){
                        try? modifiedStylesStr!.write(to: styleXMLURL, atomically: true, encoding: .utf8)
                        
                        var xmlString = try? String(contentsOf: styleXMLURL)
                        //print(xmlString)
                    }
                    
                    
                    let oldAry = testStringUniqueAry(url: shardStringXMLURL)
                    
                    let newAry = testStringUniqueAry(url: shardStringXMLURL)
                    
                    let oldUniqueCount = testStringOldUniqueCount(url: shardStringXMLURL)
                    
                    let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                    var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                    let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                        for file in sheetFiles {
                            print("Found .xml file:", file.lastPathComponent)
                        }
                    print("sheetFiles: ", sheetXMLFiles)
                    
                    
                    //ready to zip
                    var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    let fpURL = URL(fileURLWithPath: fp)
                    let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                    //appendingPathComponent("imported2.xlsx")
                    let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                    let rlt = try FileManager.default.copyItem(at: zipFilePath, to: productURL)
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Done: ", files)
                    
                    return productURL

                    
                } else {
                    // Handle the case where the specified path doesn't exist
                    print("File or directory does not exist at path: \(fp)")
                }
                
            } else {
                print("Document directory not found.")
            }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func testReadXMLSandBox(fp: String = "", url: URL? = nil) -> URL? {
        do {
                // Get the sandbox directory for documents
                if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
                //
                if FileManager.default.fileExists(atPath: fp) {
                            // The specified path exists, continue with your code
                            print("File or directory exists at path: \(fp)")
                    let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                    let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                            
                    // Check if the subdirectory already exists
                    if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                        // Create the subdirectory
                        try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                        print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                    } else {
                        // Subdirectory already exists
                        print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                        var files = try FileManager.default.contentsOfDirectory(at:
                                                                                    subdirectoryURL, includingPropertiesForKeys: nil)
                        for fileURL in files {
                           do {
                               try FileManager.default.removeItem(at: fileURL)
                               print("Deleted file:", fileURL.lastPathComponent)
                           } catch {
                               print("Error deleting file:", error)
                           }
                        }
                        
                        files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                        print("Subdirectory is now empty",files)
                    }
                    
                    // Construct the URL for the destination file
                    let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                    //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
                   
                    // Check if the file already exists at the destination
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        print("File already exists at the destination.")
                        // Remove destination file if it already exists
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                    } else {
                        // Move the file to the subdirectory
                        try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                        print("File moved successfully to: \(destinationURL.path)")
                    }
                    
                    do {
                        //unzip
                        let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                        print("File unzipped successfully.")
                    } catch {
                        print("Error unzipping file: \(error)")
                    }
                    
                    
                    
                    do {
                        //delete imported2.zip or imported2.xlsx
                        try FileManager.default.removeItem(at: destinationURL)
                        print("Deleted zip file:", destinationURL)
                    } catch {
                        print("Error deleting file:", error)
                    }
                   
                    
                    //shardString update test
                    let shardStringXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("sharedStrings.xml")
                    
                    //value and string update test
                    let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet1.xml")
                    
                    //extract sytles
                    let themeXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("theme").appendingPathComponent("theme1.xml")
                    testExtractTheme(url: themeXMLURL)
                    let styleXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("styles.xml")
                    let modifiedStylesStr = testExtractStyle(url:styleXMLURL)
                    //update to it contains date numFmt and other format
                    
                    let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                    var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                    let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                        for file in sheetFiles {
                            print("Found .xml file:", file.lastPathComponent)
                        }
                    print("sheetFiles: ", sheetXMLFiles)
                    
                    return nil

                    
                } else {
                    // Handle the case where the specified path doesn't exist
                    print("File or directory does not exist at path: \(fp)")
                }
                
            } else {
                print("Document directory not found.")
            }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func testGetSheetDataBox(fp: String = "", url: URL? = nil) -> String? {
        var isError = false
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {

            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                           return nil
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                    return nil
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                    return nil
                }
                
                    
                //shardString update test
                let shardStringXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("sharedStrings.xml")
                
                
                
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                
                let oldAry = testStringUniqueAry(url: shardStringXMLURL)
           
                
                var oldSheetDataPart:String
                let sheetData = try? Data(contentsOf: worksheetXMLURL)
                if sheetData == nil{
                    return nil
                }
                
                let xmlString = String(data: sheetData!, encoding: .utf8) ?? ""
                let pattern = "<sheetData.*?>.*?</sheetData>|<sheetData ?/>"
                if let range = xmlString.range(of: pattern, options: .regularExpression) {
                    oldSheetDataPart = String(xmlString[range])
                } else {
                    return nil
                }
             
                    
                let newAry = testStringUniqueAry(url: shardStringXMLURL)
                let oldUniqueCount = testStringOldUniqueCount(url: shardStringXMLURL)

                
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                    for file in sheetFiles {
                        print("Found .xml file:", file.lastPathComponent)
                    }
                print("sheetFiles: ", sheetXMLFiles)
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                       return nil
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return oldSheetDataPart

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
                return nil
            }
            
        } else {
            print("Document directory not found.")
            return nil
        }
            
            
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
    
    func testRangeOperationsBox(fp: String = "", url: URL? = nil, calculated:String = "",content:[String] = [],locationInExcel:[String] = []) -> Bool? {
        var isError = false
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {

            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                           return false
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                    return false
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                    return false
                }
                
                //TODO update sytle.xml here
                let themeXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("theme").appendingPathComponent("theme1.xml")
                testExtractTheme(url: themeXMLURL)
                let styleXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("styles.xml")
                let modifiedStylesStr = testExtractStyle(url:styleXMLURL)
                //update to it contains date numFmt and other format
                if (modifiedStylesStr != nil){
                    do {
                        try modifiedStylesStr?.write(to: styleXMLURL, atomically: true, encoding: .utf8)
                    } catch {
                        print("Styles.xml write error: \(error)")
                        return false
                    }
                    do {
                        var xmlString = try String(contentsOf: styleXMLURL)
                        //                    print("xmlString: \(xmlString)")
                    }catch{
                        print("failed at writing to styleXMLURL")
                        return false
                    }
                }
                
                    
                //shardString update test
                let shardStringXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("sharedStrings.xml")
                
                //check missing files and create the missing ones
                if !FileManager.default.fileExists(atPath: shardStringXMLURL.path) {
                    let content = """
                        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="0" uniqueCount="0">
                        </sst>
                        """
                    
                    try? content.write(to: shardStringXMLURL, atomically: true, encoding: .utf8)
                }
                
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                
//                let oldAry = testStringUniqueAry(url: shardStringXMLURL)
               
                    
                    var oldSheetDataPart = ""
                    let sheetData = try? Data(contentsOf: worksheetXMLURL)
                    if sheetData == nil{
                        return false
                    }
                    
                    let xmlString = String(data: sheetData!, encoding: .utf8) ?? ""
                    let pattern = "<sheetData.*?>.*?</sheetData>|<sheetData ?/>"
                    if let range = xmlString.range(of: pattern, options: .regularExpression) {
                        oldSheetDataPart = String(xmlString[range])
                    } else {
                        return false
                    }
                    
                    var cells: [ExcelCell] = []
                    for i in 0..<locationInExcel.count {
                        cells.append(ExcelCell(excelRef: locationInExcel[i], content: content[i]))
                    }
                    
                  
                    cells.sort {
                        if $0.rowNumber != $1.rowNumber {
                            return $0.rowNumber < $1.rowNumber //ASC
                        }
                        return $0.columnName < $1.columnName // ASC(A, B, C...)
                    }
                    
                    print(cells)
                    let service = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "",imp_formula:[String]())
                    
                    let currentAry = testStringUniqueAry(url: shardStringXMLURL)
                    
                    var sheetXmlString = "<sheetData>"
                    var lastRowNumber = -1
                
                    for cell in cells {
                        
                        if cell.rowNumber != lastRowNumber {
                            if lastRowNumber != -1 {
                                sheetXmlString += "</row>"
                            }
                            sheetXmlString += "<row r=\"\(cell.rowNumber)\">"
                            lastRowNumber = cell.rowNumber
                        }
                        
                        if cell.content.hasPrefix("=") {
                            //Formula
                            // .replacingOccurrences(of: "=", with: "") strips every "=" in the
                            // string, not just the leading marker -- corrupts any formula with
                            // an internal comparison (e.g. IF(MONTH(B13)=MONTH(B13+1), ...)).
                            // Only the first character is the marker.
                            let formula = String(cell.content.dropFirst())
                            sheetXmlString += "<c r=\"\(cell.excelRef)\"><f>\(formula)</f></c>"
                        } else {
                            //Value
                            //Txt
                            let index = currentAry?.firstIndex(of: cell.content)
                            if ((index != nil)){
                            sheetXmlString += "<c r=\"\(cell.excelRef)\" t=\"s\"><v>\(index!)</v></c>"
                            }else{
                                if(Double(cell.content.replacingOccurrences(of: " ", with: "")) != nil){
                                    sheetXmlString += "<c r=\"\(cell.excelRef)\" ><v>\(cell.content.replacingOccurrences(of: " ", with: ""))</v></c>"
                                }
                                else{
                                    print("something went wrong, no index")
                                }
                            }
                            
                            
                        }
                    }
                    
                    if lastRowNumber != -1 {
                        sheetXmlString += "</row>"
                    }
                    sheetXmlString += "</sheetData>"
                
               
                if oldSheetDataPart != "" {
                    let updatedString = xmlString.replacingOccurrences(of: oldSheetDataPart, with: sheetXmlString)
                    do {
                        try updatedString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                        
                        // --- 成功時のログ ---
                        print("✅ Sheet update successful!")
                        print("📍 Path: \(worksheetXMLURL.path)")
                        print("📊 Data length: \(oldSheetDataPart.count) -> \(sheetXmlString.count) characters")
                        
                        // 念のため、書き込み後のファイルが存在するか確認
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: worksheetXMLURL.path) {
                            let fileSize = attributes[.size] as? Int64 ?? 0
                            print("💾 Final file size: \(fileSize) bytes")
                        }
                        
                    } catch {
                        // --- 失敗時のログ（詳細なエラー内容を出す） ---
                        print("❌ Failed to update sheetData: \(error.localizedDescription)")
                        print("⚠️ Error details: \(error)")
                        return false
                    }
                } else {
                    print("⚠️ Warning: oldSheetDataPart was empty, no replacement performed.")
                }

                
//                    
//                let newAry = testStringUniqueAry(url: shardStringXMLURL)
//                let oldUniqueCount = testStringOldUniqueCount(url: shardStringXMLURL)

                
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                    for file in sheetFiles {
                        print("Found .xml file:", file.lastPathComponent)
                    }
                print("sheetFiles: ", sheetXMLFiles)
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                       return false
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return true

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
                return false
            }
            
        } else {
            print("Document directory not found.")
            return false
        }
            
            
        } catch {
            print("Error: \(error)")
            return false
        }
    }
    
    func testUpdateStringBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int?, fString:String? = nil, bulkAry:[String] = [], calculated:[String] = [],calculated_location:[String] = [],content:[String] = [],locationInExcel:[String] = []) -> Bool? {
        var isError = false
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {

            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                           return false
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                    return false
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                    return false
                }
                
                //TODO update sytle.xml here
                let themeXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("theme").appendingPathComponent("theme1.xml")
                testExtractTheme(url: themeXMLURL)
                let styleXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("styles.xml")
                let modifiedStylesStr = testExtractStyle(url:styleXMLURL)
                //update to it contains date numFmt and other format
                if (modifiedStylesStr != nil){
                    do {
                        try modifiedStylesStr?.write(to: styleXMLURL, atomically: true, encoding: .utf8)
                    } catch {
                        print("Styles.xml write error: \(error)")
                        return false
                    }
                    do {
                        var xmlString = try String(contentsOf: styleXMLURL)
                        //                    print("xmlString: \(xmlString)")
                    }catch{
                        print("failed at writing to styleXMLURL")
                        return false
                    }
                }
                
                    
                //shardString update test
                let shardStringXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("sharedStrings.xml")
                
                //check missing files and create the missing ones
                if !FileManager.default.fileExists(atPath: shardStringXMLURL.path) {
                    let content = """
                        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="0" uniqueCount="0">
                        </sst>
                        """
                    
                    try? content.write(to: shardStringXMLURL, atomically: true, encoding: .utf8)
                }
                
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                
                let oldAry = testStringUniqueAry(url: shardStringXMLURL)
                if input.count > 0{
                    var check = false
                    //sharedString update, if no index, it just add new element
                    let sharedStringIdAndString = checkSharedStringsIndex(url: shardStringXMLURL,SSlist:oldAry!,word: input)
                    
                    //writing updated sharedString
                    if(sharedStringIdAndString.0 != nil && sharedStringIdAndString.1 != nil){
                        do {
                            try sharedStringIdAndString.1!.write(to: shardStringXMLURL, atomically: true, encoding: .utf8)
                            print("Success: sharedString update")
                        }catch{
                           print("failed at sharedString update")
                            return false
                       }
                    }
                    
                    // Patches just the one edited cell (cellIdxString) into sheetN.xml in
                    // place -- preserves every other byte (row ht=/spans=/thickBot=,
                    // sibling cells' s= style, shared-formula compression, style-only
                    // placeholder cells) instead of rebuilding the whole <sheetData> from
                    // the whole-sheet content/locationInExcel arrays on every edit.
                    guard let patchedXML = testUpdateString(url: worksheetXMLURL, content: input, index: cellIdxString, sharedStringIndex: sharedStringIdAndString.0, calculated: calculated, calculatedLocation: calculated_location) else {
                        return false
                    }
                    do {
                        try patchedXML.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                    } catch {
                        print("failed to update sheetdata")
                        return false
                    }
                    print("sheet data",patchedXML)
                    print("shared string",sharedStringIdAndString)
                    check = true
                }else{
                    //delete values scenario
                    var replacedWithNewString = ""
                    if bulkAry.count == 0{
                        //delete
                        replacedWithNewString = testDeleteString(url:worksheetXMLURL, index: cellIdxString) ?? ""//A3
                    }
                    
                    if bulkAry.count > 0{
                        replacedWithNewString = testDeleteStringBulk(url:worksheetXMLURL, index: bulkAry) ?? ""//A3
                    }
                    
                    // Write the modified XML data back to the file
                    if(replacedWithNewString != nil && replacedWithNewString != ""){
                        do {
                            try replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                            print("File written successfully to \(worksheetXMLURL.path)")
                        } catch {
                            print("Failed to write file: \(error.localizedDescription)")
                            return false
                        }
                    }
                }
                    
                let newAry = testStringUniqueAry(url: shardStringXMLURL)
                let oldUniqueCount = testStringOldUniqueCount(url: shardStringXMLURL)

                
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                    for file in sheetFiles {
                        print("Found .xml file:", file.lastPathComponent)
                    }
                print("sheetFiles: ", sheetXMLFiles)
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                       return false
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return true

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
                return false
            }
            
        } else {
            print("Document directory not found.")
            return false
        }
            
            
        } catch {
            print("Error: \(error)")
            return false
        }
    }
    
    func testRowsDeleteBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, bulkAry:[String] = [], calculated:String = "", rowRange:[Int] = [], locationInExcel:[String] = []) -> URL? {
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                }
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                let replacedWithNewString = testDeleteRows(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated,rowRange: rowRange, locationInExcel:locationInExcel) ?? ""//A3
                // Write the modified XML data back to the file
                if(replacedWithNewString != ""){
                    try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                }
                    
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                    for file in sheetFiles {
                        print("Found .xml file:", file.lastPathComponent)
                    }
                print("sheetFiles: ", sheetXMLFiles)
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return nil

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
            }
            
        } else {
            print("Document directory not found.")
        }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func testRowsAddBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, bulkAry:[String] = [], calculated:String = "", rowRange:[Int] = [], locationInExcel:[String] = []) -> URL? {
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                }
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                let replacedWithNewString = testAddRows(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated,rowRange: rowRange, locationInExcel:locationInExcel) ?? ""//A3
                // Write the modified XML data back to the file
                if(replacedWithNewString != ""){
                    try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                }
                    
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                    for file in sheetFiles {
                        print("Found .xml file:", file.lastPathComponent)
                    }
                print("sheetFiles: ", sheetXMLFiles)
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return nil

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
            }
            
        } else {
            print("Document directory not found.")
        }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func testColsAddBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, bulkAry:[String] = [], calculated:String = "", colRange:[Int] = [], locationInExcel:[String] = []) -> URL? {
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                }
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                let replacedWithNewString = testAddCols(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated,colRange: colRange, locationInExcel:locationInExcel) ?? ""//A3
                // Write the modified XML data back to the file
                if(replacedWithNewString != ""){
                    try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                }
                    
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                    for file in sheetFiles {
                        print("Found .xml file:", file.lastPathComponent)
                    }
                print("sheetFiles: ", sheetXMLFiles)
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return nil

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
            }
            
        } else {
            print("Document directory not found.")
        }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func testColsDeleteBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, bulkAry:[String] = [], calculated:String = "", colRange:[Int] = [], locationInExcel:[String] = []) -> URL? {
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                }
                
                //value and string update test
                let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(appd.wsSheetIndex) + ".xml")
                
                let replacedWithNewString = testDeleteCols(url:worksheetXMLURL, vIndex: String(input), index: cellIdxString,numFmtId:numFmt,fString: fString, calculated: calculated,colRange: colRange, locationInExcel:locationInExcel) ?? ""//A3
                // Write the modified XML data back to the file
                if(replacedWithNewString != ""){
                    try? replacedWithNewString.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                }
                    
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                    for file in sheetFiles {
                        print("Found .xml file:", file.lastPathComponent)
                    }
                print("sheetFiles: ", sheetXMLFiles)
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return nil

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
            }
            
        } else {
            print("Document directory not found.")
        }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func testAddSheetBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, filename: String = "",copySheetData :String = "") -> URL? {
        do {
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                }
                
                //create new sheet
                var sheetContent = """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheetData/></worksheet>
                """
                
                if copySheetData != ""{
                    sheetContent = sheetContent.replacingOccurrences(of: "<sheetData/>", with: copySheetData)
                }
                let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                var sheetFiles = try FileManager.default.contentsOfDirectory(at: sheetDirectoryURL, includingPropertiesForKeys: nil)
                let sheetXMLFiles = sheetFiles.filter { $0.pathExtension == "xml" }
                
                print("sheetFiles: ", sheetXMLFiles.count)
                
                let sortedFiles = sheetXMLFiles.sorted {
                    let num1 = Int(numberOnlyString(text: $0.lastPathComponent)) ?? 0
                    let num2 = Int(numberOnlyString(text: $1.lastPathComponent)) ?? 0
                    return num1 < num2
                }
                
                let lastNum = Int(numberOnlyString(text: sortedFiles.last!.lastPathComponent))!
                
                let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(lastNum+1) + ".xml")
                
                try? sheetContent.write(to: worksheetXMLURL, atomically: true, encoding: .utf8)
                
                //xl/_res/workbook
                let _relsDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("_rels").appendingPathComponent("workbook.xml.rels")
                
                var xmlString = try? String(contentsOf: _relsDirectoryURL)
                var rIdNums = [Int]()
                let lines = xmlString?.components(separatedBy: "rId")
                for (i,line) in lines!.enumerated(){
                    if i > 0{
                        let numberOrNot = line.components(separatedBy: " ").first!
                        let tryFilter = numberOnlyString(text: numberOrNot)
                        if Int(tryFilter) != nil{
                            rIdNums.append(Int(tryFilter)!)
                        }
                    }
                }
                
                let max = rIdNums.max()//(xmlString?.components(separatedBy: "rId").count ?? 0) - 1//lines - 1 this returns count
  
                let relContent = "<Relationship Id=\"rId" + String(max!+1) + "\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet" + String(lastNum+1) + ".xml\"/></Relationships>"
                xmlString = xmlString?.replacingOccurrences(of: "</Relationships>", with: relContent)
                try? xmlString?.write(to: _relsDirectoryURL, atomically: true, encoding: .utf8)
                
                
                //xl/book
                let wkbookDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("workbook.xml")
                
                var xmlString3 = try? String(contentsOf: wkbookDirectoryURL)
                //let count3 = (xmlString3?.components(separatedBy: "rId").count ?? 0) - 1
                let newBook = "<sheet name=\"" + filename + "\" sheetId=\"" + String(lastNum+1) + "\" r:id=\"rId" + String(max!+1) + "\"/></sheets>"
                xmlString3 = xmlString3?.replacingOccurrences(of: "</sheets>", with: newBook)
                
                //sort
                let sortedXML = helperReorderSheetsByName(xmlString: xmlString3!)
                print(sortedXML)
                do{
                    try sortedXML.write(to: wkbookDirectoryURL, atomically: true, encoding: .utf8)
                }catch{
                    print("Error occured in process xmlString3?.write")
                }
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return nil

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
            }
            
        } else {
            print("Document directory not found.")
        }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    

    func helperReorderSheetsByName(xmlString: String) -> String {
        let sheetPattern = #"<sheet\s+[^>]*name="([^"]+)"[^>]*/>"#
        let regex = try! NSRegularExpression(pattern: sheetPattern, options: [])
        let nsString = xmlString as NSString
        let matches = regex.matches(in: xmlString, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var sheets = matches.map { match -> (name: String, fullTag: String) in
            let fullTag = nsString.substring(with: match.range)
            let name = nsString.substring(with: match.range(at: 1))
            return (name: name, fullTag: fullTag)
        }
        
        sheets.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        
        let sortedSheetsString = sheets.map { $0.fullTag }.joined()
        
        let containerPattern = #"(<sheets>)(.*?)(</sheets>)"#
        let containerRegex = try! NSRegularExpression(pattern: containerPattern, options: [.dotMatchesLineSeparators])
        
        let result = containerRegex.stringByReplacingMatches(
            in: xmlString,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: "$1\(sortedSheetsString)$3"
        )
        
        return result
    }

    func testDeleteSheetBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, sheetname: String = "") -> URL? {
        do {
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                }
                
                //starts here
                //workbook
                let wkbookDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("workbook.xml")
                var xmlString3 = try? String(contentsOf: wkbookDirectoryURL)
                var rIdValue = ""
                var sheetIdValue = ""
                var snippet = ""
                //xl/workbook
                // Define regex pattern to match the sheet snippet
                let pattern = #"<sheet [^>]*name="\#(sheetname)"[^>]*>"#
                if let range = xmlString3?.range(of: pattern, options: .regularExpression) {
                    snippet = String(xmlString3![range])
                    print("snippet",snippet) // Output: <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
                    let pattern2 = #"r:id="([^"]+)""#
                    if let regex2 = try? NSRegularExpression(pattern: pattern2),
                       let match2 = regex2.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)) {
                        if let range2 = Range(match2.range(at: 1), in: snippet) {
                            rIdValue = String(snippet[range2])
                            print(rIdValue) // Output: rId1
                        }
                    } else {
                        print("r:id not found")
                    }
                    let pattern3 = #"sheetId="([^"]+)""#
                    if let regex3 = try? NSRegularExpression(pattern: pattern3),
                       let match3 = regex3.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)) {
                        if let range3 = Range(match3.range(at: 1), in: snippet) {
                            sheetIdValue = String(snippet[range3])
                            print(sheetIdValue) // Output: rId1
                        }
                    } else {
                        print("sheetId not found")
                    }
                } else {
                    print("Sheet not found")
                }
                
                
                
                if rIdValue != "" && snippet != "" && sheetIdValue != ""{
                    xmlString3 = xmlString3?.replacingOccurrences(of: snippet, with: "")
                    try? xmlString3?.write(to: wkbookDirectoryURL, atomically: true, encoding: .utf8)
                    
                    
                    let sheetDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets")
                    
                    
                    let rIdValueNumber = numberOnlyString(text: rIdValue)
                    let sheetIdValueNumber = numberOnlyString(text: sheetIdValue)
                    //print("sheetFiles: ", sheetXMLFiles.count)
                    //TODO delete the xml file
                    let worksheetXMLURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("worksheets").appendingPathComponent("sheet" + String(sheetIdValueNumber)  + ".xml")
                    try FileManager.default.removeItem(at: worksheetXMLURL)
       
                    //xl/_res/workbook
                    let _relsDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("_rels").appendingPathComponent("workbook.xml.rels")
                    
                    var xmlString = try? String(contentsOf: _relsDirectoryURL)
                    let pattern_xlres = "<Relationship Id=\"\(rIdValue)\"[^>]+/>"
                    if let range_xlres = xmlString?.range(of: pattern_xlres, options: .regularExpression) {
                        let snippet_xlres = String(xmlString![range_xlres])
                        print("snippet_xlres",snippet_xlres )
                        xmlString = xmlString?.replacingOccurrences(of: snippet_xlres, with: "")
                        try? xmlString?.write(to: _relsDirectoryURL, atomically: true, encoding: .utf8)
                    } else {
                        print("Relationship not found")
                    }
                }
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return nil

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
            }
            
        } else {
            print("Document directory not found.")
        }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    func testChangeSheetNameBox(fp: String = "", url: URL? = nil, input:String = "", cellIdxString:String = "", numFmt:Int? = 0, fString:String? = nil, sheetname: String = "", newsheetname: String = "") -> URL? {
        do {
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
            //
            if FileManager.default.fileExists(atPath: fp) {
                        // The specified path exists, continue with your code
                        print("File or directory exists at path: \(fp)")
                let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
                let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                        
                // Check if the subdirectory already exists
                if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                    // Create the subdirectory
                    try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
                } else {
                    // Subdirectory already exists
                    print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                    var files = try FileManager.default.contentsOfDirectory(at:
                                                                                subdirectoryURL, includingPropertiesForKeys: nil)
                    for fileURL in files {
                       do {
                           try FileManager.default.removeItem(at: fileURL)
                           print("Deleted file:", fileURL.lastPathComponent)
                       } catch {
                           print("Error deleting file:", error)
                       }
                    }
                    
                    files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                    print("Subdirectory is now empty",files)
                }
                
                // Construct the URL for the destination file
                let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
                //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
               
                // Check if the file already exists at the destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("File already exists at the destination.")
                    // Remove destination file if it already exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                } else {
                    // Move the file to the subdirectory
                    try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                    print("File moved successfully to: \(destinationURL.path)")
                }
                
                do {
                    //unzip
                    let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                    print("File unzipped successfully.")
                } catch {
                    print("Error unzipping file: \(error)")
                }
                
                do {
                    //delete imported2.zip or imported2.xlsx
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Deleted zip file:", destinationURL)
                } catch {
                    print("Error deleting file:", error)
                }
                
                //starts here
                //workbook
                let wkbookDirectoryURL = subdirectoryURL.appendingPathComponent("xl").appendingPathComponent("workbook.xml")
                var xmlString3 = try? String(contentsOf: wkbookDirectoryURL)
                var rIdValue = ""
                var sheetIdValue = ""
                var snippet = ""
                //xl/workbook
                // Define regex pattern to match the sheet snippet
                let pattern = #"<sheet [^>]*name="\#(sheetname)"[^>]*>"#
                if let range = xmlString3?.range(of: pattern, options: .regularExpression) {
                    snippet = String(xmlString3![range])
                    print("snippet",snippet) // Output: <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
                    let pattern2 = #"r:id="([^"]+)""#
                    if let regex2 = try? NSRegularExpression(pattern: pattern2),
                       let match2 = regex2.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)) {
                        if let range2 = Range(match2.range(at: 1), in: snippet) {
                            rIdValue = String(snippet[range2])
                            print(rIdValue) // Output: rId1
                        }
                    } else {
                        print("r:id not found")
                    }
                    let pattern3 = #"sheetId="([^"]+)""#
                    if let regex3 = try? NSRegularExpression(pattern: pattern3),
                       let match3 = regex3.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)) {
                        if let range3 = Range(match3.range(at: 1), in: snippet) {
                            sheetIdValue = String(snippet[range3])
                            print(sheetIdValue) // Output: rId1
                        }
                    } else {
                        print("sheetId not found")
                    }
                } else {
                    print("Sheet not found")
                }
                
                
                
                if rIdValue != "" && snippet != "" && sheetIdValue != ""{
                    let newone = snippet.replacingOccurrences(of: sheetname, with: newsheetname)
                    xmlString3 = xmlString3?.replacingOccurrences(of: snippet, with: newone)
                    
                    //sort
                    let sortedXML = helperReorderSheetsByName(xmlString: xmlString3!)
                    print(sortedXML)
                    do{
                        try sortedXML.write(to: wkbookDirectoryURL, atomically: true, encoding: .utf8)
                    }catch{
                        print("Error occured in process xmlString3?.write")
                    }
                }
                
                
                //ready to zip
                var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                let fpURL = URL(fileURLWithPath: fp)
                let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
                //appendingPathComponent("imported2.xlsx")
                let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                // Check if the destination file exists
                if FileManager.default.fileExists(atPath: fpURL.path) {
                    // If it exists, remove it
                    try FileManager.default.removeItem(at: fpURL)
                }
                //overwrite or update xlsx
                let rlt = try FileManager.default.copyItem(at: zipFilePath, to: fpURL)//productURL
                
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Done: ", files)
                
                return nil

                
            } else {
                // Handle the case where the specified path doesn't exist
                print("File or directory does not exist at path: \(fp)")
            }
            
        } else {
            print("Document directory not found.")
        }
            
            
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    
    func writeXlsxEmail(fp: String = "", url: URL? = nil) -> URL? {
        do {
        // Get the sandbox directory for documents
        if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
        let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
        //
        if FileManager.default.fileExists(atPath: fp) {
                    // The specified path exists, continue with your code
                    print("File or directory exists at path: \(fp)")
            let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
            let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                    
            // Check if the subdirectory already exists
            if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                // Create the subdirectory
                try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
            } else {
                // Subdirectory already exists
                print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                var files = try FileManager.default.contentsOfDirectory(at:
                                                                            subdirectoryURL, includingPropertiesForKeys: nil)
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Subdirectory is now empty",files)
            }
            
            // Construct the URL for the destination file
            let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
            //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
           
            // Check if the file already exists at the destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                print("File already exists at the destination.")
                // Remove destination file if it already exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
            } else {
                // Move the file to the subdirectory
                try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                print("File moved successfully to: \(destinationURL.path)")
            }
            
            do {
                //unzip
                let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                print("File unzipped successfully.")
            } catch {
                print("Error unzipping file: \(error)")
            }
            
            
            
            do {
                //delete imported2.zip or imported2.xlsx
                try FileManager.default.removeItem(at: destinationURL)
                print("Deleted zip file:", destinationURL)
            } catch {
                print("Error deleting file:", error)
            }
            
          
            
            //ready to zip
            var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
            //"importedExcel"
            let fpURL = URL(fileURLWithPath: fp)
            let productURL = subdirectoryURL.appendingPathComponent(fpURL.lastPathComponent)
            //appendingPathComponent("imported2.xlsx")
            let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
            let rlt = try FileManager.default.copyItem(at: zipFilePath, to: productURL)
            
            files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
            print("Done: ", files)
            
            return productURL

            
        } else {
            // Handle the case where the specified path doesn't exist
            print("File or directory does not exist at path: \(fp)")
        }
        
        } else {
            print("Document directory not found.")
        }
        
        
        } catch {
            print("Error: \(error)")
        }

            return nil
    }
    
    func removeXlsxBackup(forFileFill: Bool = false) -> Bool? {
        do {
            let backupDirURL = ExcelHelper().getBackupDirectory(forFileFill: forFileFill)
            if (backupDirURL == nil){
                print("Invalid backupDir, return nil")
                return nil
            }
       
            let fileURLs = try FileManager.default.contentsOfDirectory(at: backupDirURL!, includingPropertiesForKeys: nil)

            for fileURL in fileURLs {
                if fileURL.lastPathComponent.hasPrefix("before_") {
                    try FileManager.default.removeItem(at: fileURL)
                    print("🗑️ Deleted old prefix file: \(fileURL.lastPathComponent)")
                }
            }
            return true

            
        } catch {
            print("Error: \(error)")
        }

        return false
    }
    
    func writeXlsxBackup(fp: String = "", url: URL? = nil,isAutoSave:Bool = false,msg:String = "",filename:String="",filenameSuffix:String="") -> URL? {
        do {
        // Get the sandbox directory for documents
        if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
        let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
        //
        if FileManager.default.fileExists(atPath: fp) {
                    // The specified path exists, continue with your code
                    print("File or directory exists at path: \(fp)")
            let directoryURL =  URL.init(fileURLWithPath: fp).deletingLastPathComponent()
            let subdirectoryURL = directoryURL.appendingPathComponent("importedExcel")
                    
            // Check if the subdirectory already exists
            if !FileManager.default.fileExists(atPath: subdirectoryURL.path) {
                // Create the subdirectory
                try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Subdirectory created successfully at path: \(subdirectoryURL.path)")
            } else {
                // Subdirectory already exists
                print("Subdirectory already exists at path: \(subdirectoryURL.path)")
                var files = try FileManager.default.contentsOfDirectory(at:
                                                                            subdirectoryURL, includingPropertiesForKeys: nil)
                for fileURL in files {
                   do {
                       try FileManager.default.removeItem(at: fileURL)
                       print("Deleted file:", fileURL.lastPathComponent)
                   } catch {
                       print("Error deleting file:", error)
                   }
                }
                
                files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
                print("Subdirectory is now empty",files)
            }
            
            // Construct the URL for the destination file
            let destinationURL = subdirectoryURL.appendingPathComponent("imported2.zip")
            //let destinationURL = subdirectoryURL.appendingPathComponent(URL.init(fileURLWithPath: fp).lastPathComponent)
           
            // Check if the file already exists at the destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                print("File already exists at the destination.")
                // Remove destination file if it already exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
            } else {
                // Move the file to the subdirectory
                try FileManager.default.copyItem(at: URL.init(fileURLWithPath: fp), to: destinationURL)
                print("File moved successfully to: \(destinationURL.path)")
            }
            
            do {
                //unzip
                let rlt = try Zip.unzipFile(destinationURL, destination: subdirectoryURL, overwrite: true, password: nil)
                print("File unzipped successfully.")
            } catch {
                print("Error unzipping file: \(error)")
            }
            
            
            
            do {
                //delete imported2.zip or imported2.xlsx
                try FileManager.default.removeItem(at: destinationURL)
                print("Deleted zip file:", destinationURL)
            } catch {
                print("Error deleting file:", error)
            }
            
          
            
            //ready to zip
            var files = try FileManager.default.contentsOfDirectory(at:subdirectoryURL, includingPropertiesForKeys: nil)
            //"importedExcel"
            let fpURL = URL(fileURLWithPath: fp)
            // "_ff" is FileFillViewController's own marker (see its writeXlsxBackup call
            // sites) -- reused here to route its backups into their own directory instead
            // of introducing a second, parallel flag for the same distinction.
            let backupDirURL = ExcelHelper().getBackupDirectory(forFileFill: filenameSuffix == "_ff")
            if (backupDirURL == nil){
                print("Invalid backupDir, return nil")
                return nil
            }
       
            //creating backup file name
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmm"
            let timestamp = formatter.string(from: Date())

            var fileName = fpURL.lastPathComponent // initial.xlsx
            let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            if appd.excelfilename != ""{
                fileName = appd.excelfilename.components(separatedBy: ".").first ?? "excelfile"
            }
            
               
            var nameWithoutExtension = fpURL.deletingPathExtension().lastPathComponent // coook

            if isAutoSave == true{
                nameWithoutExtension = msg + "auto_save"
            }

            let fileExtension = fpURL.pathExtension // xlsx

            // filenameSuffix (e.g. "_ff" for FileFillViewController) tags backups by
            // which mode wrote them, without needing a separate backup directory --
            // getBackupFiles() filters on this same suffix to keep them out of
            // ViewController's backup list. Always placed immediately before the
            // extension (not before the timestamp) so both the auto-save and the
            // explicit-named-save filenames reliably end with it.
            var newFileName = "\(nameWithoutExtension)_\(timestamp)\(filenameSuffix).\(fileExtension)"

            if filename.replacingOccurrences(of: " ", with: "") != ""{
                newFileName = "\(filename)\(filenameSuffix).\(fileExtension)"
            }
            
            let backupURL = backupDirURL!.appendingPathComponent(newFileName)

            let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
            
      
            if FileManager.default.fileExists(atPath: backupURL.path) {
                try FileManager.default.removeItem(at: backupURL)
            }

            try FileManager.default.copyItem(at: zipFilePath, to: backupURL)
            
            files = try FileManager.default.contentsOfDirectory(at:backupDirURL!, includingPropertiesForKeys: nil)
            print("Bakup is made: ", files)
            
            try FileManager.default.removeItem(at: zipFilePath)
            
            return backupURL

            
        } else {
            // Handle the case where the specified path doesn't exist
            print("File or directory does not exist at path: \(fp)")
        }
        
        } else {
            print("Document directory not found.")
        }
        
        
        } catch {
            print("Error: \(error)")
        }

            return nil
    }
    
    func writeXlsxSandBox(path: URL, fileName: String) {
        do {
            // Get the sandbox directory for documents
            if let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents")
                
                // Check if the directory exists
                if FileManager.default.fileExists(atPath: driveURL.path) {
                    // Get a list of files in the directory
                    let files = try FileManager.default.contentsOfDirectory(at: driveURL, includingPropertiesForKeys: nil)
                    
                    // Zip the files (assuming you have a Zip library)
                    let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer")
                    
                    //try Zip.quickUnzipFile(zipFilePath)
                        
                    
                    if FileManager.default.fileExists(atPath: zipFilePath.path) {
                        // Copy the zip file to the specified path
                        try FileManager.default.copyItem(at: zipFilePath, to: path.appendingPathComponent(fileName))
                        print("Done: ", path.appendingPathComponent(fileName).path)
                    }
                } else {
                    print("Directory does not exist.")
                }
            } else {
                print("Document directory not found.")
            }
        } catch {
            print("Error: \(error)")
        }
    }

    
    func writeXlsx(path:URL,fileName:String){
        do{
            let files = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path.path), includingPropertiesForKeys: nil)
            let zipFilePath = try Zip.quickZipFiles(files, fileName: "outputInAppContainer") // Zip
            
            if FileManager.default.fileExists(atPath: zipFilePath.path) {
                //It's odd. It created file on the root directory.
                print("Done: ", zipFilePath.path)
                
                FileManager.default.secureCopyItem(at: URL(fileURLWithPath:zipFilePath.path), to:URL(fileURLWithPath: (path.appendingPathComponent(fileName).path)))
            }
        }
        catch
        {
            print("Something went wrong")
        }
    }
    
    // Function to extract row and column indices from the "r" attribute value
    func extractIndices(from attribute: String) -> (row: Int, column: String)? {
        guard let match = attribute.rangeOfCharacter(from: .decimalDigits) else {
            return nil
        }
        
        let rowString = attribute[match.lowerBound...]
        let columnString = attribute.prefix(upTo: match.lowerBound)
        
        if let row = Int(rowString), !columnString.isEmpty {
            return (row, String(columnString))
        } else {
            return nil
        }
    }

    func extractSheetDataSubstring(from input: String) -> String? {
        let pattern = "<sheetData>(.*?)</sheetData>"
        if let range = input.range(of: pattern, options: .regularExpression) {
            return String(input[range])
        }
        return nil
    }
    
    func extractFunctionSubstring(from input: String) -> String? {
        let pattern1 = "<f.*?/>"
        if let range = input.range(of: pattern1, options: .regularExpression) {
            return String(input[range])
        }
        
        let pattern2 = "<f>(.*?)</f>"
        if let range = input.range(of: pattern2, options: .regularExpression) {
            return String(input[range])
        }
        return ""
    }
    
    //TODO
    //b: Boolean (0 or 1)
    //d: Date (in ISO 8601 format)
    //e: Error (error message text)
    //inlineStr: Inline string (actual string value stored directly in the cell element)
    //n: Number
    //s: Shared string (an index to the shared string table)
    func extractFunctionTtagSubstring(from input: String) -> String? {
        if input.contains("t=\"str\""){
            return "t=\"str\""
        }
        if input.contains("t=\"str\""){
            return "t=\"str\""
        }
        return ""
    }
    
    func testStringUniqueAry(url:URL? = nil)->[String]?{
        if let url2 = url{
            let xmlData = try? Data(contentsOf: url2)
            if (xmlData != nil){
                let parser = XMLParser(data: xmlData!)
                // Set XMLParserDelegate
                let delegate = SharedStringsParserDelegate()
                parser.delegate = delegate

                if parser.parse() {
                    return delegate.sis
                }
            }
        }
        return []
    }


}
extension FileManager {
    open func writeXml(folder:String,filename:String,content:String) -> Bool{
        let driveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent(folder)
                
        print(driveURL?.absoluteString as Any)
                
        //        https://stackoverflow.com/questions/26931355/how-to-create-directory-using-swift-code-nsfilemanager/26931481
                
        do {
                if !FileManager.default.fileExists(atPath: driveURL!.absoluteString) {
                        try FileManager.default.createDirectory(at: driveURL!, withIntermediateDirectories: true, attributes: nil)
                }
            
            if (NSData(contentsOf: driveURL!.appendingPathComponent(filename)) != nil) {
                               
                try FileManager.default.removeItem(at: driveURL!.appendingPathComponent(filename))
                    print("overwritten",driveURL!)
                }

         
                try content.write(to: driveURL!.appendingPathComponent(filename), atomically: true, encoding: .utf8)
              
                
            return true
        
        } catch {
            print(error.localizedDescription);
            
            return false
                          
        }
    }
    
    open func writeXmlsandBox(folder:String,filename:String,content:String) -> Bool{
          let sandBox = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        let driveURL = URL(fileURLWithPath: sandBox).appendingPathComponent("Documents").appendingPathComponent(folder)
                
        print(driveURL.absoluteString as Any)
                
        //        https://stackoverflow.com/questions/26931355/how-to-create-directory-using-swift-code-nsfilemanager/26931481
                
        do {
            if !FileManager.default.fileExists(atPath: driveURL.absoluteString) {
                try FileManager.default.createDirectory(at: driveURL, withIntermediateDirectories: true, attributes: nil)
                }
            
            if (NSData(contentsOf: driveURL.appendingPathComponent(filename)) != nil) {
                               
                try FileManager.default.removeItem(at: driveURL.appendingPathComponent(filename))
                print("overwritten",driveURL)
                }

         
            try content.write(to: driveURL.appendingPathComponent(filename), atomically: true, encoding: .utf8)
              
                
            return true
        
        } catch {
            print(error.localizedDescription);
            
            return false
                          
        }
    }
    
    open func getFileURLsInFolder(folder: String) -> [URL]? {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsDirectoryURL.appendingPathComponent(folder)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print("Error accessing files in folder: \(error.localizedDescription)")
            return nil
        }
    }

    
    open func deleteWorksheets() -> Bool{
        let driveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent("xl/worksheets/")
                
        print(driveURL?.absoluteString as Any)
                
        //        https://stackoverflow.com/questions/26931355/how-to-create-directory-using-swift-code-nsfilemanager/26931481
                
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: driveURL!.path)

                for item in items {
                    try FileManager.default.removeItem(at: driveURL!.appendingPathComponent(item))
                     print(item)
                }

                   
            } catch {
                                   
                return false
                                                 
            }
    

            return true
        
       
    }
    
    func uploadFileToICloud(url: URL) {
            // Implement file upload logic to iCloud Drive using FileManager or CloudKit APIs
            // For example:
            do {
                let fileManager = FileManager.default
                let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent(url.lastPathComponent)
                try fileManager.copyItem(at: url, to: iCloudURL!)
                print("File uploaded to iCloud Drive successfully")
            } catch {
                print("Error uploading file to iCloud Drive: \(error.localizedDescription)")
            }
        }
    
    
    
}


extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
class XMLValidator: NSObject, XMLParserDelegate {
    
    var validationError: Error?
    
    func validateXML(xmlString: String) -> Bool {
        let parser = XMLParser(data: xmlString.data(using: .utf8)!)
        parser.delegate = self
        
        return parser.parse()
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        validationError = parseError
    }
}
    
    
    
    //legacy
    //todo creating
//    func testUpdateValue(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil) -> String?{
//        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        //get style id
//        var styleIdx = -1
//        let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: String(index!))
//        var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
//
//        if (slocatinIdx != nil){
//            styleIdx = appd.excelStyleIdx[slocatinIdx!]
//        }
//        if let url2 = url{
//            let xmlData = try? Data(contentsOf: url2)
//            if xmlData == nil{
//                return nil
//            }
//            let parser = XMLParser(data: xmlData!)
//            // Set XMLParserDelegate
//            let delegate = CustomXMLParserDelegate()
//            parser.delegate = delegate
//
//
//            var patternFound = false
//            // Start parsing
//            if parser.parse() {
//                // Retrieve the extracted part
//                let extractedPart = delegate.extractedPart
//                //print(extractedPart)
//            }
//
//            //regular expression
//            var xmlString = try? String(contentsOf: url2)
//            let backUpXmlString = xmlString
//            var xml = XMLHash.parse(xmlString!)
//
//            // Define the regular expression pattern D3
//            let pattern4 = "<c[^>]*r=\"\(String(index!))\"[^>]*/>"//"<c r=\"\(String(index!))\".*?/>"
//            //#"<c\s+r="B1".*?</c>"#
//
//            // Create the regular expression object
//            guard let regex4 = try? NSRegularExpression(pattern: pattern4, options: []) else {
//                fatalError("Failed to create regular expression")
//            }
//
//            // Find matches in the XML string
//            let range4 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
//            let matches4 = regex4.matches(in: xmlString!, range: range4)
//
//            // Extract matching substrings
//            //TODO switch sharedString or value here or not?
//            if let match = matches4.first{
//                if let matchRange = Range(match.range, in: xmlString!) {
//                    var matchingSubstring = xmlString![matchRange].description
//                    var functionstr = ""
//                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
//                    if (fString != nil){
//                        functionstr = "<f>\(fString!)</f>"
//                    }
//                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//
//                    if styleIdx > 0{
//                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                    }
//
//                    //"<c r=\"D14\" s=\"54\"><v>0.375</v></c><c r=\"E14\" s=\"55\"><v>0.75</v></c><c r=\"F14\" s=\"56\"><v>0.5</v></c><c r=\"G14\" s=\"57\"><v>0.54166666666666663</v></c><c r=\"H14\" s=\"56\"/>"
//                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
//                    if cCnt == 2{
//                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
//                    }
//
//                    let validator = XMLValidator()
//                    if validator.validateXML(xmlString: xmlString!) {
//                        print("XML is valid.")
//                        return xmlString
//                    } else {
//                        print("XML is not valid.")
//                        //print(xmlString)
//                        return backUpXmlString
//                    }
//                }
//            }
//
//            // Define the regular expression pattern D3
//            let pattern3 = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>"//"<c r=\"\(String(index!))\".*?/>"
//            //#"<c\s+r="B1".*?</c>"#
//
//            // Create the regular expression object
//            guard let regex3 = try? NSRegularExpression(pattern: pattern3, options: []) else {
//                fatalError("Failed to create regular expression")
//            }
//
//            // Find matches in the XML string
//            let range3 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
//            let matches3 = regex3.matches(in: xmlString!, range: range3)
//
//            // Extract matching substrings
//            //TODO switch sharedString or value here or not?
//            if let match = matches3.first{
//                if let matchRange = Range(match.range, in: xmlString!) {
//                    var matchingSubstring = xmlString![matchRange].description
//                    var functionstr = ""
//                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
//                    if (fString != nil){
//                        functionstr = "<f>\(fString!)</f>"
//                    }
//                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//
//                    if styleIdx > 0{
//                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                    }
//
//                    //"<c r=\"D14\" s=\"54\"><v>0.375</v></c><c r=\"E14\" s=\"55\"><v>0.75</v></c><c r=\"F14\" s=\"56\"><v>0.5</v></c><c r=\"G14\" s=\"57\"><v>0.54166666666666663</v></c><c r=\"H14\" s=\"56\"/>"
//
//                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
//                    if cCnt == 2{
//                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
//                    }
//
//                    let validator = XMLValidator()
//                    if validator.validateXML(xmlString: xmlString!) {
//                        print("XML is valid.")
//                        return xmlString
//                    } else {
//                        print("XML is not valid.")
//                        //print(xmlString)
//                        return backUpXmlString
//                    }
//                }
//            }
//
//
//            // Define the regular expression pattern D3
//            let pattern = "<c.*?r=\"\(String(index!))\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
//
//            // Create the regular expression object
//            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
//                fatalError("Failed to create regular expression")
//            }
//
//            // Find matches in the XML string
//            let range = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
//            let matches = regex.matches(in: xmlString!, range: range)
//
//            // Extract matching substrings
//            //TODO switch sharedString or value here or not?
//            if let match = matches.first{
//                if let matchRange = Range(match.range, in: xmlString!) {
//                    var matchingSubstring = xmlString![matchRange].description
//                    //let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
//                    //var items = modified.components(separatedBy: "!")
//                    //first is always ""
//                    if matchingSubstring.contains("<row r"){
//                        matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
//                    }
//
//                    if matchingSubstring.hasSuffix("</row>"){
//                        matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
//                    }
//
//                    var functionstr = ""
//                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
//                    if (fString != nil){
//                        functionstr = "<f>\(fString!)</f>"
//                    }
//                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//
//                    if styleIdx > 0{
//                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                    }
//
//                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
//                    if cCnt == 2{
//                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
//                    }
//
//                    let validator = XMLValidator()
//                    if validator.validateXML(xmlString: xmlString!) {
//                        print("XML is valid.")
//                        return xmlString
//                    } else {
//                        print("XML is not valid.")
//                        //print(xmlString)
//                        return backUpXmlString
//                    }
//                }
//            }
//
//            let pattern2 = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>"
//
//            // Create the regular expression object
//            guard let regex2 = try? NSRegularExpression(pattern: pattern2, options: []) else {
//                fatalError("Failed to create regular expression")
//            }
//
//            // Find matches in the XML string
//            let range2 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
//            let matches2 = regex2.matches(in: xmlString!, range: range2)
//
//            // Extract matching substrings
//            //TODO switch sharedString or value here or not?
//            for match in matches2 {
//                if let matchRange = Range(match.range, in: xmlString!) {
//                    var matchingSubstring = xmlString![matchRange].description
//
//                    if matchingSubstring.contains("<row r"){
//                        matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
//                    }
//
//                    if matchingSubstring.hasSuffix("</row>"){
//                        matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
//                    }
//
//                    var functionstr = ""
//                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
//                    if (fString != nil){
//                        functionstr = "<f>\(fString!)</f>"
//                    }
//
//                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//
//                    if styleIdx > 0{
//                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                    }
//
//                    let cCnt = matchingSubstring.components(separatedBy: "r=").count
//                    if cCnt == 2{
//                        xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
//                    }
//
//                    let validator = XMLValidator()
//                    if validator.validateXML(xmlString: xmlString!) {
//                        print("XML is valid.")
//                        return xmlString
//                    } else {
//                        print("XML is not valid.")
//                        //print(xmlString)
//                        return backUpXmlString
//                    }
//                }
//            }
//
//            //
//
//
//            //get the list of locations
//            do {
//                var functionstr = ""
//                if (fString != nil){
//                    functionstr = "<f>\(fString!)</f>"
//                }
//
//                let row = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//
//                // Retrieve all row tags
//                let patternRow = "<row r=\"\(row)\".*?>(.*?)</row>"
//                let regexRow = try NSRegularExpression(pattern: patternRow, options: [])
//
//                // Find all matches in the XML snippet
//                let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
//
//                var targetRowTag = ""
//                for match in matchesRow {
//                    // Extract the row number from the match
//                    let nsRange = match.range(at: 1) // Use the capture group index
//                    if let range = Range(nsRange, in: xmlString!) {
//                        if let matchRange = Range(match.range, in: xmlString!) {
//                            targetRowTag = String(xmlString![matchRange]).description
//                            if targetRowTag.contains("/><row"){
//                                let items = targetRowTag.components(separatedBy: "/><row")
//                                if (items.first != nil){
//                                    targetRowTag = items.first! + "/>"
//                                    print(targetRowTag)
//                                }
//                            }
//                        }
//                    }
//                }
//
//                // Create a regular expression pattern to match the r attribute C4,C44
//                let pattern = #"r=\"([A-Z]+\d+)\""#
//
//                // Create a regular expression object
//                let regex = try NSRegularExpression(pattern: pattern, options: [])
//
//                // Find all matches in the XML snippet
//                let matches = regex.matches(in: targetRowTag, options: [], range: NSRange(location: 0, length: targetRowTag.utf16.count))
//
//                // Extract the r values from the matches
//                var rValues = matches.map { match -> String in
//                    guard let range = Range(match.range(at: 1), in: xmlString!) else {
//                        return ""
//                    }
//                    return String(targetRowTag[range])
//                }
//
//                // Output the list of r values D1, G1
//                //rValues.append(String(index!))
//
//                let rValues2 = rValues.sorted { (r1, r2) -> Bool in
//                    // Extract the alphabetic part of the cell reference
//                    let alphabeticPart1 = r1.prefix(while: { $0.isLetter })
//                    let alphabeticPart2 = r2.prefix(while: { $0.isLetter })
//
//                    // If the alphabetic parts are different, compare them
//                    if alphabeticPart1 != alphabeticPart2 {
//                        return alphabeticPart1 < alphabeticPart2
//                    }
//
//                    // If the alphabetic parts are the same, compare the numeric parts
//                    let numericPart1 = Int(r1.drop(while: { !$0.isNumber })) ?? 0
//                    let numericPart2 = Int(r2.drop(while: { !$0.isNumber })) ?? 0
//
//                    return numericPart1 < numericPart2
//                }
//
//                //is it first
//                if let idx = rValues2.firstIndex(of: String(index!)) {
//                    print("rowindex",idx)
//                    if idx == rValues2.count-1{
//                        var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//
//                        if styleIdx > 0{
//                            newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                        }
//
//                        var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
//                        replacing = replacing + newElement + "</row>"
//                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
//                        print(replaced)
//                        let validator = XMLValidator()
//                        if validator.validateXML(xmlString: replaced!) {
//                            print("XML is valid.")
//                            return replaced
//                        } else {
//                            print("XML is not valid.")
//                            print(replaced)
//                            return backUpXmlString
//                        }
//                    }else{
//                        // Define the regular expression pattern D3
//                        //                    let pattern1 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)/>"
//                        //                    let pattern2 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
//                        let pattern1 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*>(.*?)</c>"
//                        let pattern2 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*/>"
//
//                        let combinedPattern = "\(pattern1)|\(pattern2)"
//
//                        // Create the regular expression object
//                        guard let regex2 = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
//                            fatalError("Failed to create regular expression")
//                        }
//
//                        // Find matches in the XML string
//                        let range = NSRange(targetRowTag.startIndex..<targetRowTag.endIndex, in: targetRowTag)
//                        let matches = regex2.matches(in: targetRowTag, range: range)
//
//                        // Extract matching substrings
//                        if let match = matches.first{
//                            if let matchRange = Range(match.range, in: targetRowTag) {
//                                var matchingSubstring = targetRowTag[matchRange].description
//
//                                if matchingSubstring.contains("<row r"){
//                                    matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
//                                }
//
//                                if matchingSubstring.hasSuffix("</row>"){
//                                    matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
//                                }
//
//                                let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
//                                var items = modified.components(separatedBy: "!")
//                                //first is always ""
//                                let item = items[1] ?? ""
//                                print("item", item)
//                                var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//
//                                if styleIdx > 0{
//                                    newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                                }
//
//                                // Find the correct position to insert the new element
//                                if let range = xmlString?.range(of: item) {
//                                    // Insert the new element after the element with r="J2"
//                                    xmlString?.insert(contentsOf: newElement, at: range.lowerBound)
//                                    let validator = XMLValidator()
//                                    if validator.validateXML(xmlString: xmlString!) {
//                                        print("XML is valid.")
//                                    } else {
//                                        print("XML is not valid.")
//                                        //print(xmlString)
//                                        return backUpXmlString
//                                    }
//                                }
//                            }
//                        }
//                    }
//
//                }else{
//                    //row not exists
//                    //first c tag with sharedstring idx == nil
//                    var sortedRowcnt = [String]()
//                    var sortedRowstr = ""
//                    var sortedRowInt = [Int]()
//                    if targetRowTag == ""{
//                        //"<sheetData><row r=\"4\"><c r=\"A4\" s=\"1\"><v>10</v></c></row>"
//                        //var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
//                        var newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" >\(functionstr)<v>\(String(vIndex!))</v></c></row>"
//                        if (sValueId != nil && sValueId! != 0){
//                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c></row>"
//                        }
//
//                        if styleIdx > 0{
//                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c></row>"
//                        }
//
//                        var replaced = xmlString?.replacingOccurrences(of: "<sheetData>", with: newElement)
//
//                        if ((replaced?.contains("<sheetData/>")) != nil){
//                            replaced = replaced?.replacingOccurrences(of: "<sheetData/>", with: newElement + "</sheetData>")
//                        }
//
//                        xml = XMLHash.parse(replaced!)
//
//                        if let sortedRows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children{
//                            // Sort the rows based on some criteria (e.g., the value of the "r" attribute of cells)
//                            let sortedCells = sortedRows.sorted { (row1, row2) -> Bool in
//                                guard
//                                    let text1 = row1.element?.attribute(by: "r")?.text,
//                                    let text2 = row2.element?.attribute(by: "r")?.text
//
//                                else {
//                                    return false
//                                }
//
//                                return text1 < text2
//                            }
//
//                            // Use the sorted cells
//                            // For example, print them
//                            for cell in sortedCells {
//                                let idx = cell.element?.attribute(by: "r")?.text.description
//                                sortedRowcnt.append(cell.description)
//                                sortedRowInt.append(Int(idx!)!)
//                                sortedRowstr += cell.description
//                            }
//                        }
//
//                        if let sheetDataSubstring = extractSheetDataSubstring(from: replaced!) {
//
//                            let zippedArray = zip(sortedRowcnt, sortedRowInt)
//
//                            // Sort the zipped array based on the second element (sortedRowInt)
//                            let sortedZippedArray = zippedArray.sorted { $0.1 < $1.1 }
//
//                            // Extract the sorted strings from the sorted zipped array
//                            let sortedStrings = sortedZippedArray.map { $0.0 }
//
//                            let rowSortedStr = replaced!.replacingOccurrences(of: sheetDataSubstring, with:"<sheetData>" + sortedStrings.joined(separator: "") + "</sheetData>")
//                            xml = XMLHash.parse(rowSortedStr)
//                        }
//
//                        let validator = XMLValidator()
//                        if validator.validateXML(xmlString: xml.description) {
//                            print("XML is valid.")
//                            return xml.description
//                        } else {
//                            print("XML is not valid.")
//                            print(xml.description)
//                            return backUpXmlString
//                        }
//                    }else{
//                        //row exists c element exists
//                        //targetRowTag   "<row r=\"1\"><c r=\"B1\" t=\"s\"><v>78</v></c></row>"
//                        var rowPart = targetRowTag
//                        if rowPart.hasSuffix("/>"){
//                            rowPart = rowPart.replacingOccurrences(of: "/>", with: ">")
//                        }
//                        if !rowPart.hasSuffix(">"){
//                            rowPart = rowPart + ">"
//                        }
//                        let rowNumber = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//                        //var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
//                        var newElement2 = "<c r=\"\(String(index!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                        if (sValueId != nil && sValueId! != 0){
//                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                        }
//
//                        if (styleIdx > 0){
//                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(String(vIndex!))</v></c>"
//                        }
//
//
//
//                        var replacing = rowPart.replacingOccurrences(of: "</row>", with: "")
//                        replacing = replacing + newElement2 + "</row>"
//                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
//                        let validator0 = XMLValidator()
//                        if validator0.validateXML(xmlString: replaced!) {
//                            print("XML is valid.")
//                        } else {
//                            print("XML is not valid.")
//                            //print(xmlString)
//                            return backUpXmlString
//                        }
//                        let old = xmlString
//                        rowPart = ""
//                        xml = XMLHash.parse(replaced!)
//                        if let rows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children {
//                            // Iterate through the rows
//                            for row in rows {
//                                // Sort the child elements (cells) within each row based on some criteria
//                                let sortedCells = row.children.sorted { (cell1: XMLIndexer, cell2: XMLIndexer) -> Bool in
//                                    // Compare cells based on some criteria (e.g., column index)
//                                    if let name1 = cell1.element?.attribute(by: "r")?.text, let name2 = cell2.element?.attribute(by: "r")?.text {
//                                        let indices1 = extractIndices(from: name1)
//                                        let indices2 = extractIndices(from: name2)
//                                        if indices1?.row.description == rowNumber{
//
//                                            // Rows are equal, compare columns
//                                            if indices1!.column < indices2!.column{
//                                                return name1 < name2
//                                            }
//                                        }
//                                    }
//
//                                    return false // Modify as per your sorting criteria
//                                }
//
//                                // Convert sortedCells back to an array of XMLIndexer objects
//                                let sortedCellsArray: [XMLIndexer] = sortedCells.map { $0 }
//
//
//
//                                // Update the children of the current row with the sorted cells
//                                // Note: You may need to find an alternative way to update the children of the row element
//                                // row.children = sortedCellsArray // This will not work due to read-only property
//
//                                // Print the sorted cells (optional)
//                                for cell in sortedCellsArray {
//                                    let name1 = (cell.element?.attribute(by: "r")?.text)!
//                                    let indices1 = extractIndices(from: name1)
//                                    if indices1?.row.description == rowNumber{
//                                        print(cell)
//                                        rowPart += cell.description
//                                    }
//                                }
//                            }
//                        } else {
//                            print("No rows found or there are no children under the specified path")
//                        }
//
//                        rowPart = rowPart.replacingOccurrences(of: "</row>", with: "")
//                        rowPart = "<row r=\"\(row)\">" + rowPart + "</row>"
//                        let final = old!.replacingOccurrences(of: targetRowTag, with: rowPart)
//                        let validator = XMLValidator()
//                        if validator.validateXML(xmlString: final) {
//                            print("XML is valid.")
//                            return final
//                        } else {
//                            print("XML is not valid.")
//                            print("xmlDESC",final)
//                            return backUpXmlString
//                        }
//                    }
//                }
//
//            } catch {
//                print("Error: \(error)")
//            }
//
//
//        }
//        return nil
//    }
//

    
//    func testUpdateFormula(url:URL? = nil, vIndex:String?, index:String?, numFmtId:Int?, fString:String? = nil, calculated:String = "") -> String?{
//        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        //get style id
//        var styleIdx = -1
//        let slocatinIdx = appd.excelStyleLocationAlphabet.firstIndex(of: String(index!))
//        var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
//
//        if (slocatinIdx != nil){
//            styleIdx = appd.excelStyleIdx[slocatinIdx!]
//        }
//        if let url2 = url{
//            let xmlData = try? Data(contentsOf: url2)
//            let parser = XMLParser(data: xmlData!)
//            // Set XMLParserDelegate
//            let delegate = CustomXMLParserDelegate()
//            parser.delegate = delegate
//
//
//            var patternFound = false
//            // Start parsing
//            if parser.parse() {
//                // Retrieve the extracted part
//                let extractedPart = delegate.extractedPart
//                //print(extractedPart)
//            }
//
//            //regular expression
//            var xmlString = try? String(contentsOf: url2)
//            let backUpXmlString = xmlString
//            var xml = XMLHash.parse(xmlString!)
//
//            // Define the regular expression pattern D3
//            let pattern4 = "<c[^>]*r=\"\(String(index!))\"[^>]*/>"//"<c r=\"\(String(index!))\".*?/>"
//            //#"<c\s+r="B1".*?</c>"#
//
//            // Create the regular expression object
//            guard let regex4 = try? NSRegularExpression(pattern: pattern4, options: []) else {
//                fatalError("Failed to create regular expression")
//            }
//
//            // Find matches in the XML string
//            let range4 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
//            let matches4 = regex4.matches(in: xmlString!, range: range4)
//
//            // Extract matching substrings
//            //TODO switch sharedString or value here or not?
//            if let match = matches4.first{
//                if let matchRange = Range(match.range, in: xmlString!) {
//                    var matchingSubstring = xmlString![matchRange].description
//                    var functionstr = ""
//                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
//                    if (fString != nil){
//                        functionstr = "<f>\(fString!)</f>"
//                    }
//                    if (fString == nil){
//                        functionstr = "<f>\(String(vIndex!).replacingOccurrences(of: "=", with: ""))</f>"
//                    }
//
//                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
//
//                    if styleIdx > 0{
//                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
//                    }
//
//                    //"<c r=\"D14\" s=\"54\"><v>0.375</v></c><c r=\"E14\" s=\"55\"><v>0.75</v></c><c r=\"F14\" s=\"56\"><v>0.5</v></c><c r=\"G14\" s=\"57\"><v>0.54166666666666663</v></c><c r=\"H14\" s=\"56\"/>"
//                    xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
//
//                    let validator = XMLValidator()
//                    if validator.validateXML(xmlString: xmlString!) {
//                        print("XML is valid.")
//                        return xmlString
//                    } else {
//                        print("XML is not valid.")
//                        //print(xmlString)
//                        return backUpXmlString
//                    }
//                }
//            }
//
//            // Define the regular expression pattern D3
//            let pattern3 = "<c[^>]*r=\"\(String(index!))\"[^>]*>(.*?)</c>"//"<c r=\"\(String(index!))\".*?/>"
//            //#"<c\s+r="B1".*?</c>"#
//
//            // Create the regular expression object
//            guard let regex3 = try? NSRegularExpression(pattern: pattern3, options: []) else {
//                fatalError("Failed to create regular expression")
//            }
//
//            // Find matches in the XML string
//            let range3 = NSRange(xmlString!.startIndex..<xmlString!.endIndex, in: xmlString!)
//            let matches3 = regex3.matches(in: xmlString!, range: range3)
//
//            // Extract matching substrings
//            //TODO switch sharedString or value here or not?
//            if let match = matches3.first{
//                if let matchRange = Range(match.range, in: xmlString!) {
//                    var matchingSubstring = xmlString![matchRange].description
//                    var functionstr = ""
//                    functionstr = extractFunctionSubstring(from: matchingSubstring) ?? ""
//                    if (fString != nil){
//                        functionstr = "<f>\(fString!)</f>"
//                    }
//                    if (fString == nil){
//                        functionstr = "<f>\(String(vIndex!).replacingOccurrences(of: "=", with: ""))</f>"
//                    }
//                    //<c r="B4"><f>SUM(A1:A7)</f><v>8</v></c>
//                    var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
//
//                    if styleIdx > 0{
//                        newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
//                    }
//
//                    //"<c r=\"D14\" s=\"54\"><v>0.375</v></c><c r=\"E14\" s=\"55\"><v>0.75</v></c><c r=\"F14\" s=\"56\"><v>0.5</v></c><c r=\"G14\" s=\"57\"><v>0.54166666666666663</v></c><c r=\"H14\" s=\"56\"/>"
//
//                    xmlString = xmlString?.replacingOccurrences(of: matchingSubstring, with: newElement)
//
//                    let validator = XMLValidator()
//                    if validator.validateXML(xmlString: xmlString!) {
//                        print("XML is valid.")
//                        return xmlString
//                    } else {
//                        print("XML is not valid.")
//                        //print(xmlString)
//                        return backUpXmlString
//                    }
//                }
//            }
//
//
//            //get the list of locations
//            do {
//                var functionstr = ""
//                if (fString != nil){
//                    functionstr = "<f>\(fString!)</f>"
//                }
//                if (fString == nil){
//                    functionstr = "<f>\(String(vIndex!).replacingOccurrences(of: "=", with: ""))</f>"
//                }
//                let row = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//
//                // Retrieve all row tags
//                let patternRow = "<row r=\"\(row)\".*?>(.*?)</row>"
//                let regexRow = try NSRegularExpression(pattern: patternRow, options: [])
//
//                // Find all matches in the XML snippet
//                let matchesRow = regexRow.matches(in: xmlString!, options: [], range: NSRange(location: 0, length: xmlString!.utf16.count))
//
//                var targetRowTag = ""
//                for match in matchesRow {
//                    // Extract the row number from the match
//                    let nsRange = match.range(at: 1) // Use the capture group index
//                    if let range = Range(nsRange, in: xmlString!) {
//                        if let matchRange = Range(match.range, in: xmlString!) {
//                            targetRowTag = String(xmlString![matchRange]).description
//                            if targetRowTag.contains("/><row"){
//                                let items = targetRowTag.components(separatedBy: "/><row")
//                                if (items.first != nil){
//                                    targetRowTag = items.first! + "/>"
//                                    print(targetRowTag)
//                                }
//                            }
//                        }
//                    }
//                }
//
//                // Create a regular expression pattern to match the r attribute C4,C44
//                let pattern = #"r=\"([A-Z]+\d+)\""#
//
//                // Create a regular expression object
//                let regex = try NSRegularExpression(pattern: pattern, options: [])
//
//                // Find all matches in the XML snippet
//                let matches = regex.matches(in: targetRowTag, options: [], range: NSRange(location: 0, length: targetRowTag.utf16.count))
//
//                // Extract the r values from the matches
//                var rValues = matches.map { match -> String in
//                    guard let range = Range(match.range(at: 1), in: xmlString!) else {
//                        return ""
//                    }
//                    return String(targetRowTag[range])
//                }
//
//                // Output the list of r values D1, G1
//                //rValues.append(String(index!))
//
//                let rValues2 = rValues.sorted { (r1, r2) -> Bool in
//                    // Extract the alphabetic part of the cell reference
//                    let alphabeticPart1 = r1.prefix(while: { $0.isLetter })
//                    let alphabeticPart2 = r2.prefix(while: { $0.isLetter })
//
//                    // If the alphabetic parts are different, compare them
//                    if alphabeticPart1 != alphabeticPart2 {
//                        return alphabeticPart1 < alphabeticPart2
//                    }
//
//                    // If the alphabetic parts are the same, compare the numeric parts
//                    let numericPart1 = Int(r1.drop(while: { !$0.isNumber })) ?? 0
//                    let numericPart2 = Int(r2.drop(while: { !$0.isNumber })) ?? 0
//
//                    return numericPart1 < numericPart2
//                }
//
//                //is it first
//                if let idx = rValues2.firstIndex(of: String(index!)) {
//                    print("rowindex",idx)
//                    if idx == rValues2.count-1{
//                        var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
//
//                        if styleIdx > 0{
//                            newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
//                        }
//
//                        var replacing = targetRowTag.replacingOccurrences(of: "</row>", with: "")
//                        replacing = replacing + newElement + "</row>"
//                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
//                        print(replaced)
//                        let validator = XMLValidator()
//                        if validator.validateXML(xmlString: replaced!) {
//                            print("XML is valid.")
//                            return replaced
//                        } else {
//                            print("XML is not valid.")
//                            print(replaced)
//                            return backUpXmlString
//                        }
//                    }else{
//                        // Define the regular expression pattern D3
//                        //                    let pattern1 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)/>"
//                        //                    let pattern2 = "<c r=\"\(rValues2[idx+1])\".*?>(.*?)</c>" //#"<c\s+r="B1".*?</c>"#
//                        let pattern1 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*>(.*?)</c>"
//                        let pattern2 = "<c[^>]*r=\"\(rValues2[idx+1])\"[^>]*/>"
//
//                        let combinedPattern = "\(pattern1)|\(pattern2)"
//
//                        // Create the regular expression object
//                        guard let regex2 = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
//                            fatalError("Failed to create regular expression")
//                        }
//
//                        // Find matches in the XML string
//                        let range = NSRange(targetRowTag.startIndex..<targetRowTag.endIndex, in: targetRowTag)
//                        let matches = regex2.matches(in: targetRowTag, range: range)
//
//                        // Extract matching substrings
//                        if let match = matches.first{
//                            if let matchRange = Range(match.range, in: targetRowTag) {
//                                var matchingSubstring = targetRowTag[matchRange].description
//
//                                if matchingSubstring.contains("<row r"){
//                                    matchingSubstring = matchingSubstring.components(separatedBy: "<row r").first!
//                                }
//
//                                if matchingSubstring.hasSuffix("</row>"){
//                                    matchingSubstring = matchingSubstring.replacingOccurrences(of: "</row>", with: "")
//                                }
//
//                                let modified = matchingSubstring.replacingOccurrences(of: "<c", with: "!<c")
//                                var items = modified.components(separatedBy: "!")
//                                //first is always ""
//                                let item = items[1] ?? ""
//                                print("item", item)
//                                var newElement = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
//
//                                if styleIdx > 0{
//                                    newElement = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
//                                }
//
//                                // Find the correct position to insert the new element
//                                if let range = xmlString?.range(of: item) {
//                                    // Insert the new element after the element with r="J2"
//                                    xmlString?.insert(contentsOf: newElement, at: range.lowerBound)
//                                    let validator = XMLValidator()
//                                    if validator.validateXML(xmlString: xmlString!) {
//                                        print("XML is valid.")
//                                    } else {
//                                        print("XML is not valid.")
//                                        //print(xmlString)
//                                        return backUpXmlString
//                                    }
//                                }
//                            }
//                        }
//                    }
//
//                }else{
//                    //row not exists
//                    //first c tag with sharedstring idx == nil
//                    var sortedRowcnt = [String]()
//                    var sortedRowstr = ""
//                    var sortedRowInt = [Int]()
//                    if targetRowTag == ""{
//                        //"<sheetData><row r=\"4\"><c r=\"A4\" s=\"1\"><v>10</v></c></row>"
//                        //var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
//                        var newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" >\(functionstr)<v>\(calculated)</v></c></row>"
//                        if (sValueId != nil && sValueId! != 0){
//                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c></row>"
//                        }
//
//                        if styleIdx > 0{
//                            newElement = "<sheetData><row r=\"\(row)\">" + "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c></row>"
//                        }
//
//                        var replaced = xmlString?.replacingOccurrences(of: "<sheetData>", with: newElement)
//
//                        if ((replaced?.contains("<sheetData/>")) != nil){
//                            replaced = replaced?.replacingOccurrences(of: "<sheetData/>", with: newElement + "</sheetData>")
//                        }
//
//                        xml = XMLHash.parse(replaced!)
//
//                        if let sortedRows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children{
//                            // Sort the rows based on some criteria (e.g., the value of the "r" attribute of cells)
//                            let sortedCells = sortedRows.sorted { (row1, row2) -> Bool in
//                                guard
//                                    let text1 = row1.element?.attribute(by: "r")?.text,
//                                    let text2 = row2.element?.attribute(by: "r")?.text
//
//                                else {
//                                    return false
//                                }
//
//                                return text1 < text2
//                            }
//
//                            // Use the sorted cells
//                            // For example, print them
//                            for cell in sortedCells {
//                                let idx = cell.element?.attribute(by: "r")?.text.description
//                                sortedRowcnt.append(cell.description)
//                                sortedRowInt.append(Int(idx!)!)
//                                sortedRowstr += cell.description
//                            }
//                        }
//
//                        if let sheetDataSubstring = extractSheetDataSubstring(from: replaced!) {
//
//                            let zippedArray = zip(sortedRowcnt, sortedRowInt)
//
//                            // Sort the zipped array based on the second element (sortedRowInt)
//                            let sortedZippedArray = zippedArray.sorted { $0.1 < $1.1 }
//
//                            // Extract the sorted strings from the sorted zipped array
//                            let sortedStrings = sortedZippedArray.map { $0.0 }
//
//                            let rowSortedStr = replaced!.replacingOccurrences(of: sheetDataSubstring, with:"<sheetData>" + sortedStrings.joined(separator: "") + "</sheetData>")
//                            xml = XMLHash.parse(rowSortedStr)
//                        }
//
//                        let validator = XMLValidator()
//                        if validator.validateXML(xmlString: xml.description) {
//                            print("XML is valid.")
//                            return xml.description
//                        } else {
//                            print("XML is not valid.")
//                            print(xml.description)
//                            return backUpXmlString
//                        }
//                    }else{
//                        //row exists c element exists
//                        //targetRowTag   "<row r=\"1\"><c r=\"B1\" t=\"s\"><v>78</v></c></row>"
//                        var rowPart = targetRowTag
//                        if rowPart.hasSuffix("/>"){
//                            rowPart = rowPart.replacingOccurrences(of: "/>", with: ">")
//                        }
//                        if !rowPart.hasSuffix(">"){
//                            rowPart = rowPart + ">"
//                        }
//                        let rowNumber = String(index!).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//                        //var sValueId = appd.numFmtIds.lastIndex(of: numFmtId ?? 0)
//                        var newElement2 = "<c r=\"\(String(index!))\">\(functionstr)<v>\(calculated)</v></c>"
//                        if (sValueId != nil && sValueId! != 0){
//                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(sValueId!))\">\(functionstr)<v>\(calculated)</v></c>"
//                        }
//
//                        if (styleIdx > 0){
//                            newElement2 = "<c r=\"\(String(index!))\" s=\"\(String(styleIdx))\">\(functionstr)<v>\(calculated)</v></c>"
//                        }
//
//
//
//                        var replacing = rowPart.replacingOccurrences(of: "</row>", with: "")
//                        replacing = replacing + newElement2 + "</row>"
//                        let replaced = xmlString?.replacingOccurrences(of: targetRowTag, with: replacing)
//                        let validator0 = XMLValidator()
//                        if validator0.validateXML(xmlString: replaced!) {
//                            print("XML is valid.")
//                        } else {
//                            print("XML is not valid.")
//                            //print(xmlString)
//                            return backUpXmlString
//                        }
//                        let old = xmlString
//                        rowPart = ""
//                        xml = XMLHash.parse(replaced!)
//                        if let rows = xml.children.first?.children.first(where: { $0.element?.name == "sheetData" })?.children {
//                            // Iterate through the rows
//                            for row in rows {
//                                // Sort the child elements (cells) within each row based on some criteria
//                                let sortedCells = row.children.sorted { (cell1: XMLIndexer, cell2: XMLIndexer) -> Bool in
//                                    // Compare cells based on some criteria (e.g., column index)
//                                    if let name1 = cell1.element?.attribute(by: "r")?.text, let name2 = cell2.element?.attribute(by: "r")?.text {
//                                        let indices1 = extractIndices(from: name1)
//                                        let indices2 = extractIndices(from: name2)
//                                        if indices1?.row.description == rowNumber{
//
//                                            // Rows are equal, compare columns
//                                            if indices1!.column < indices2!.column{
//                                                return name1 < name2
//                                            }
//                                        }
//                                    }
//
//                                    return false // Modify as per your sorting criteria
//                                }
//
//                                // Convert sortedCells back to an array of XMLIndexer objects
//                                let sortedCellsArray: [XMLIndexer] = sortedCells.map { $0 }
//
//
//
//                                // Update the children of the current row with the sorted cells
//                                // Note: You may need to find an alternative way to update the children of the row element
//                                // row.children = sortedCellsArray // This will not work due to read-only property
//
//                                // Print the sorted cells (optional)
//                                for cell in sortedCellsArray {
//                                    let name1 = (cell.element?.attribute(by: "r")?.text)!
//                                    let indices1 = extractIndices(from: name1)
//                                    if indices1?.row.description == rowNumber{
//                                        print(cell)
//                                        rowPart += cell.description
//                                    }
//                                }
//                            }
//                        } else {
//                            print("No rows found or there are no children under the specified path")
//                        }
//
//                        rowPart = rowPart.replacingOccurrences(of: "</row>", with: "")
//                        rowPart = "<row r=\"\(row)\">" + rowPart + "</row>"
//                        let final = old!.replacingOccurrences(of: targetRowTag, with: rowPart)
//                        let validator = XMLValidator()
//                        if validator.validateXML(xmlString: final) {
//                            print("XML is valid.")
//                            return final
//                        } else {
//                            print("XML is not valid.")
//                            print("xmlDESC",final)
//                            return backUpXmlString
//                        }
//                    }
//                }
//
//            } catch {
//                print("Error: \(error)")
//            }
//
//
//        }
//        return nil
//    }

