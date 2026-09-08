//
//  XLSVTests.swift
//  XLSVTests
//
//  Created by yujin on 2024/03/09.
//  Copyright © 2024 Credera. All rights reserved.
//

import XCTest
@testable import XLSV
final class XLSVTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    // MARK: - StyleTableEditor (in-app cell styling)

    private let sampleStylesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/><scheme val="minor"/></font><font><b/><sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/><scheme val="minor"/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles><dxfs count="0"/></styleSheet>
    """

    func testStyleEditorAppendsFontAndXfForTextColor() throws {
        let editor = try XCTUnwrap(StyleTableEditor(stylesXML: sampleStylesXML))
        let idx = editor.styleIndex(baseXf: 0, textColorHex: "#FF0000", bgColorHex: nil, fontSize: nil)

        XCTAssertTrue(editor.didChange)
        XCTAssertEqual(idx, 2, "new xf should be appended at the end")

        let out = editor.serializedXML()
        XCTAssertTrue(out.contains("<color rgb=\"FFFF0000\"/>"), "explicit rgb font colour written")
        XCTAssertTrue(out.contains("<fonts count=\"3\">"), "font count bumped")
        XCTAssertTrue(out.contains("<cellXfs count=\"3\">"), "xf count bumped")
        XCTAssertTrue(out.contains("fontId=\"2\""))
        XCTAssertTrue(XMLValidator().validateXML(xmlString: out), "output is well-formed")
    }

    func testStyleEditorReusesExistingEntriesOnSecondPass() throws {
        let firstPass = try XCTUnwrap(StyleTableEditor(stylesXML: sampleStylesXML))
        _ = firstPass.styleIndex(baseXf: 0, textColorHex: "#00FF00", bgColorHex: "#FFFF00", fontSize: nil)
        let rewritten = firstPass.serializedXML()

        let secondPass = try XCTUnwrap(StyleTableEditor(stylesXML: rewritten))
        let idx = secondPass.styleIndex(baseXf: 0, textColorHex: "#00FF00", bgColorHex: "#FFFF00", fontSize: nil)
        XCTAssertFalse(secondPass.didChange, "an identical request must reuse the existing font/fill/xf")
        XCTAssertEqual(secondPass.serializedXML(), rewritten)
        XCTAssertGreaterThan(idx, 0)
    }

    func testStyleEditorBoldReusesExistingBoldFont() throws {
        // sampleStylesXML already has a bold font at fontId 1 (used by xf 1).
        let editor = try XCTUnwrap(StyleTableEditor(stylesXML: sampleStylesXML))
        let idx = editor.styleIndex(baseXf: 0, textColorHex: nil, bgColorHex: nil, fontSize: nil,
                                    bold: true, italic: nil)
        XCTAssertFalse(editor.didChange, "bold-ing the default font should reuse the existing bold font (id 1)")
        // xf 1 is (numFmtId 0, fontId 1, fillId 0, borderId 0) -> matches
        XCTAssertEqual(idx, 1)
    }

    func testStyleEditorItalicAppendsFont() throws {
        let editor = try XCTUnwrap(StyleTableEditor(stylesXML: sampleStylesXML))
        let idx = editor.styleIndex(baseXf: 0, textColorHex: nil, bgColorHex: nil, fontSize: nil,
                                    bold: nil, italic: true)
        XCTAssertTrue(editor.didChange)
        XCTAssertEqual(idx, 2)
        let out = editor.serializedXML()
        XCTAssertTrue(out.contains("<i/>"))
        XCTAssertTrue(out.contains("<fonts count=\"3\">"))
        XCTAssertTrue(XMLValidator().validateXML(xmlString: out))
    }

    func testStyleEditorNoOpWhenNothingChanges() throws {
        let editor = try XCTUnwrap(StyleTableEditor(stylesXML: sampleStylesXML))
        let idx = editor.styleIndex(baseXf: 1, textColorHex: nil, bgColorHex: nil, fontSize: nil)
        XCTAssertFalse(editor.didChange)
        XCTAssertEqual(idx, 1)
        XCTAssertEqual(editor.serializedXML(), sampleStylesXML)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testControllerMethod() throws {
            // Given
            let controller = iCloudViewController() // Instantiate your controller
            
            // When
            let result = controller.test // Call the method to test
            
            // Then
            // Assert the result or side effects of the method
            XCTAssertEqual(result, true) // Example assertion
            
            // You can add more assertions based on the behavior of your method
        }

}
