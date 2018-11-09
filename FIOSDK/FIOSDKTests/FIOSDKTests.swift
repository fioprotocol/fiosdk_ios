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
    private let accountNameForRequestFunds:String = "exchange2222"
    private let privateKey:String = "5KDQzVMaD1iUdYDrA2PNK3qEP7zNbUf8D41ZVKqGzZ117PdM5Ap"
    private let publicKey:String = "EOS6D6gSipBmP1KW9SMB5r4ELjooaogFt77gEs25V9TU9FrxKVeFb"
    private let url:String = "http://52.14.221.174:8889/v1"
    
    private let TIMEOUT:Double = 10.0
    
    private let useStaging = true
    
    // {"table_key":"","lower_bound":"","key_type":"","index_position":"","code":"fio.finance","scope":"fio.finance","table":"trxlogs","limit":10,"encode_type":"dec","upper_bound":"","json":true}
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        if (useStaging){
            _ = FIOSDK.sharedInstance(accountName: "fioname11111", accountNameForRequestFunds: "fioname11111", privateKey: "5K2HBexbraViJLQUJVJqZc42A8dxkouCmzMamdrZsLHhUHv77jF", publicKey: "EOS5GpUwQtFrfvwqxAv24VvMJFeMHutpQJseTz8JYUBfZXP2zR8VY", url: "http://18.223.56.185:8889/v1")
        }

        else{
            _ = FIOSDK.sharedInstance(accountName: accountName, accountNameForRequestFunds: accountNameForRequestFunds, privateKey: privateKey, publicKey: publicKey, url: url)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
  /*
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

  */
    /*
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
        
        wait(for: [expectation], timeout: TIMEOUT*3000)
    }


    func testRegister(){
        let expectation = XCTestExpectation(description: "testRegisterFIOName")
        
        let receiveAddress:String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        
        let timestamp = NSDate().timeIntervalSince1970
        print(Int(timestamp.rounded()))
        
        let publicReceiveAddresses:Dictionary<String,String> = [receiveAddress:"ETH"]
        FIOSDK.sharedInstance().register(fioName: ("sha\(Int(timestamp.rounded())).brd"),newAccountName:"test", publicReceiveAddresses: publicReceiveAddresses, completion: {error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT*3000)
    }

    func testValidation(){
        
        XCTAssert(FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd"), "should be valid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "test1234567890123456.brd"), "should be valid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd.brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test#!.brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test12345678901234567.brd"), "should be invalid")
    }
*/
    /*
    func testGetRequestDetails(){
        let expectation = XCTestExpectation(description: "testGetRequestDetails")
        
        FIOSDK.sharedInstance().getRequestDetails(appIdStart: 1, appIdEnd: 5, maxItemsReturned: 10) { (requests, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testGetRequestDetails NOT SUCCESSFUL")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT*3000)
    }
    */
 
    /*
    func testApproveFunds(){
        let expectation = XCTestExpectation(description: "testApproveFunds")
        
        FIOSDK.sharedInstance().approveRequestFunds(requesteeAccountName: "fioname22222", fioAppId: 2, obtId:"" , memo: "")  { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testApproveFunds NOT SUCCESSFUL")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT*30000)
    }

  */
    func testGetPendingRequestHistory(){
        let expectation = XCTestExpectation(description: "testGetPendingRequestHistory")
        
        FIOSDK.sharedInstance().getRequestPendingHistory(requesteeAccountName: "fioname22222", maxItemsReturned: 10, completion: { (requests, error) in
            
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testGetPendingRequestHistory NOT SUCCESSFUL")
            expectation.fulfill()
            
        })
        
        wait(for: [expectation], timeout: TIMEOUT*3000)
    }

 
/*
    func testRequestFunds(){
        let expectation = XCTestExpectation(description: "testRequestFunds")
        
        FIOSDK.sharedInstance().requestFunds(requestorAccountName: "fioname11111", requesteeAccountName: "fioname22222", chain: "FIO", asset: "FIO", amount: 10.0000, memo: "shawn test") { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testRequestFunds NOT SUCCESSFUL")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT*30000)
    }


    func testRejectRequestFunds(){
        let expectation = XCTestExpectation(description: "testRejectRequestFunds")
        
        FIOSDK.sharedInstance().rejectRequestFunds(requesteeAccountName: "fioname22222", fioAppId: 4 , memo: "rejecting shawn test") {  (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "rejectRequestFunds NOT SUCCESSFUL")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }

    func testCancelRequestFunds(){
        let expectation = XCTestExpectation(description: "testCancelRequestFunds")
        
        FIOSDK.sharedInstance().cancelRequestFunds(requestorAccountName: "fioname11111", requestId: 10000, memo: "cancel shawn text") {  (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testCancelRequestFunds NOT SUCCESSFUL")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
   */
    //
    /*
    func testGetAccountName(){
        let expectation = XCTestExpectation(description: "testGetAccountName")
        
        let receiveAddress:String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        
        FIOSDK.sharedInstance().getAccount(accountName: "5jnzm4k4g4vn", completion: { (account, error) in
            if (account != nil){
                print ("account name found")
                print(account?.accountName)
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "getAccountName NOT SUCCESSFUL")
                expectation.fulfill()
            }
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    func testAddAccountPermissions(){
        let expectation = XCTestExpectation(description: "testAddAccountPermissions")
        
        let receiveAddress:String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        
        FIOSDK.sharedInstance().addAccountPermissions(accountName: "5jnzm4k4g4vn", completion: { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddAccountPermissions NOT SUCCESSFUL")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
 */
}
