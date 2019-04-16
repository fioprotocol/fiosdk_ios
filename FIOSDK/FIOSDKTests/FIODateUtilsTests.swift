//
//  FIODateUtils.swift
//  FIOSDKTests
//
//  Created by Vitor Navarro on 2019-04-08.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import XCTest
@testable import FIOSDK

class FIODateUtilsTests: XCTestCase {
    
    func testFormattedDateWithDateShouldFormatWithDefault() {
        let date = Date(timeIntervalSince1970: 1554751877)
        let expected = "Apr 08, 2019"
        XCTAssertEqual(FIOSDK.DateUtils.formattedDate(date: date), expected)
    }
    
    func testFormattedDateWithIntervalShouldFormatWithDefault() {
        let date: Double = 1554751877
        let expected = "Apr 08, 2019"
        XCTAssertEqual(FIOSDK.DateUtils.formattedDate(interval: date), expected)
    }
    
    func testFormattedDateWithDateShouldFormat() {
        let date = Date(timeIntervalSince1970: 1554751877)
        let expected = "08, April, 2019" //Monday, 8 April 2019 19:31:17
        XCTAssertEqual(FIOSDK.DateUtils.formattedDate(date: date, format: "dd, MMMM, yyyy"), expected)
    }
    
    func testFormattedDateWithIntervalShouldFormat() {
        let date: Double = 1554751877
        let expected = "Monday - Apr 08, 2019"
        XCTAssertEqual(FIOSDK.DateUtils.formattedDate(interval: date, format: "EEEE - MMM dd, yyyy"), expected)
    }
    
    func testFormattedDateWithDateAndInvalidFormatShouldFailSilently() {
        let date = Date(timeIntervalSince1970: 1554751877)
        let expected = ""
        XCTAssertEqual(FIOSDK.DateUtils.formattedDate(date: date, format: "invalid"), expected)
    }
    
    func testFormattedDateWithIntervalAndInvalidFormatShouldFailSilently() {
        let date: Double = 1554751877
        XCTAssertNil(FIOSDK.DateUtils.formattedDate(interval: date, format: "invalid"))
    }
    
}
