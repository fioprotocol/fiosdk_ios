//
//  ValidatorTests.swift
//  FIOSDKTests
//
//  Created by shawn arney on 12/2/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//


import XCTest
@testable import FIOSDK

class ValidatorTests: XCTestCase {
    
    func testFioAddress() {
        
        let fioSDK = FIOSDK()
        
        XCTAssert(fioSDK.isFioNameValid(fioName: "a@9"), "should be valid fio address")
        
        XCTAssert(fioSDK.isFioNameValid(fioName: "fred@testnet"), "should be valid fio address")
        
        XCTAssert(fioSDK.isFioNameValid(fioName: "fred-a@testnet") == true, "should be valid fio address")
        
        XCTAssert(fioSDK.isFioNameValid(fioName: "fred--:testnet") == false, "should be invalid fio address")
        
        XCTAssert(fioSDK.isFioNameValid(fioName: "fred@:testnet") == false, "should be invalid fio address")
        
        XCTAssert(fioSDK.isFioNameValid(fioName: ":") == false, "should be invalid fio address")
        
        XCTAssert(fioSDK.isFioNameValid(fioName: "64charsrekldowerehfredabcdedefgeteckewerekldowereh@testneth81234") == true, "should be valid fio address")

        XCTAssert(fioSDK.isFioNameValid(fioName: "65charsgrekldowerehfredabcdedefgeteckewerekldowereh@testneth81234") == false, "should be invalid fio address")
        
    }
   
    func testFioDomain() {
           
           let fioSDK = FIOSDK()

           XCTAssert(fioSDK.isFioNameValid(fioName: "a9"), "should be valid fio address")
           
           XCTAssert(fioSDK.isFioNameValid(fioName: "fredtestnet"), "should be valid fio address")
           
           XCTAssert(fioSDK.isFioNameValid(fioName: "fred-atestnet") == true, "should be valid fio address")
           
           XCTAssert(fioSDK.isFioNameValid(fioName: "fred--testnet") == false, "should be invalid fio address")
           
           XCTAssert(fioSDK.isFioNameValid(fioName: "fred:testnet") == false, "should be invalid fio address")
           
           XCTAssert(fioSDK.isFioNameValid(fioName: "") == false, "should be invalid fio address")
           
           XCTAssert(fioSDK.isFioNameValid(fioName: "62charasekldowerehfredabcdedefgeteckewerekldowerehatestneth812") == true, "should be valid fio address")

           XCTAssert(fioSDK.isFioNameValid(fioName: "63charsaekldowerehfredabcdedefgeteckewerekldowerehatestneth812a") == false, "should be invalid fio address")

       }
    
}

