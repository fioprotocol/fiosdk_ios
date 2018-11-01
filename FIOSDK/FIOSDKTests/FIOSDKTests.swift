//
//  FIOSDKTests.swift
//  FIOSDKTests
//
//  Created by shawn arney on 10/19/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import XCTest
@testable import FIOSDK

class FIOSDKTests: XCTestCase {

    private let accountName:String = "exchange1111"
    private let privateKey:String = "5KDQzVMaD1iUdYDrA2PNK3qEP7zNbUf8D41ZVKqGzZ117PdM5Ap"
    private let publicKey:String = "EOS6D6gSipBmP1KW9SMB5r4ELjooaogFt77gEs25V9TU9FrxKVeFb"
    private let url:String = "http://52.14.221.174:8889/v1"
    
    private let TIMEOUT:Double = 10.0
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        _ = FIOSDK.sharedInstance(accountName: accountName, privateKey: privateKey, publicKey: publicKey, url: url)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetAddressByFioName() {
        let expectation = XCTestExpectation(description: "testGetAddressByFIOName")
        
        FIOSDK.sharedInstance().getAddressByFioName(fioName: "shanapi.brd", currencyCode: "ETH", completion: { result, error in ()
            print(result.address)
            print(result.isRegistered)
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "getAddressByFIOName NOT FOUND")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetFioNameByAddress(){
        let expectation = XCTestExpectation(description: "testGetFIONameByKey")
        
        let receiveAddress:String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        
        FIOSDK.sharedInstance().getFioNameByAddress(publicAddress: receiveAddress, currencyCode: "ETH", completion:  {result, error in ()
            print(result.name)
            XCTAssert((result.name.count > 3), "getFIONameByKey NOT FOUND")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRegisterFioName(){
        let expectation = XCTestExpectation(description: "testRegisterFIOName")
        
        let receiveAddress:String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        
        let timestamp = NSDate().timeIntervalSince1970
        print(Int(timestamp.rounded()))
        
        let publicReceiveAddresses:Dictionary<String,String> = [receiveAddress:"ETH"]
        FIOSDK.sharedInstance().registerFioName(fioName: ("sha\(Int(timestamp.rounded())).brd"), publicReceiveAddresses: publicReceiveAddresses, completion: {error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testValidation(){
        
        XCTAssert(FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd"), "should be valid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "test1234567890123456.brd"), "should be valid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd.brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test#!.brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test12345678901234567.brd"), "should be invalid")
    }


    func testCreateAccount() {
        
        let expectation = XCTestExpectation(description: "testNewAccountCreation")
        
        FIOSDK.sharedInstance().createNewAccount(newAccountName:"testnew");
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetAccount() {
        let expectation = XCTestExpectation(description: "testGetAccount")
        
        FIOSDK.sharedInstance().getAccount(accountName:"testnew");
        
        wait(for: [expectation], timeout: TIMEOUT)
        
    }

    func testCreateRandomAccountName() {
        let accountName = FIOSDK.sharedInstance().createRandomAccountName()
        
        print (accountName)
        print (accountName.count)
        XCTAssert(accountName.count == 12, "should be 12 characters")
        
    }
    
}
