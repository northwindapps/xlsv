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
