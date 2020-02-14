//
//  SUFUtilsTests.swift
//  FIOSDKTests
//
//  Created by Vitor Navarro on 2019-05-13.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import XCTest
@testable import FIOSDK

class SUFUtilsTests: XCTestCase {

    func testAmountToSUFWithFullValueShouldBeSuccessful() {
        
        let result = SUFUtils.amountToSUF(amount: 30.0)
        let expected: Int = 30000000000
        
        XCTAssert(result == expected, String(format:"Result %d and expected %d are different", result, expected))
        
    }

    func testAmountToSUFSTringWithFullValueShouldBeSuccessful() {
        
        let result = SUFUtils.amountToSUFString(amount: 30.0)
        let expected = "30000000000"
        
        XCTAssert(result == expected, String(format:"Result %s and expected %s are different", result, expected))
        
    }
    
    func testAmountToSUFWithDoubleValueShouldBeSuccessful() {
        
        let result = SUFUtils.amountToSUF(amount: 31.3456)
        let expected = 31345600000
        
        XCTAssert(result == expected, String(format:"Result %i and expected %i are different", result, expected))
        
    }
    
    func testAmountToSUFSTringWithDoubleValueShouldBeSuccessful() {
        
        let result = SUFUtils.amountToSUFString(amount: 0.25)
        let expected = "250000000"
        
        XCTAssert(result == expected, String(format:"Result %s and expected %s are different", result, expected))
        
    }

}
