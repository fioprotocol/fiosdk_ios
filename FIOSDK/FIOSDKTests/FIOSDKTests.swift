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
    
    // stage 1 server: 18.223.14.244
    private let TIMEOUT:Double = 120.0
    
    private let useStaging = true
    
    // test variables
    private var requesteeFioName: String = ""
    private let requesteeAddress:String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
    private var requestorFioName: String = ""
    private let requestorAddress:String = "0x3A2522321656285661Df2012a3A05bEF84C8B1ed"
    
    // {"table_key":"","lower_bound":"","key_type":"","index_position":"","code":"fio.finance","scope":"fio.finance","table":"trxlogs","limit":10,"encode_type":"dec","upper_bound":"","json":true}
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let timestamp = NSDate().timeIntervalSince1970
        requesteeFioName = "sha\(Int(timestamp.rounded())).brd"
        requestorFioName = "bar\(Int(timestamp.rounded())).brd"
        
        if (useStaging){
            //
           // _ = FIOSDK.sharedInstance(accountName: "fioname11111", privateKey: "5K2HBexbraViJLQUJVJqZc42A8dxkouCmzMamdrZsLHhUHv77jF", publicKey: "EOS5GpUwQtFrfvwqxAv24VvMJFeMHutpQJseTz8JYUBfZXP2zR8VY",systemPrivateKey:"5KBX1dwHME4VyuUss2sYM25D5ZTDvyYrbEz37UJqwAVAsR4tGuY", systemPublicKey:"EOS7isxEua78KPVbGzKemH4nj2bWE52gqj8Hkac3tc7jKNvpfWzYS", url: "http://18.223.14.244:8889/v1")
            
           // _ = FIOSDK.sharedInstance(accountName: "fio.system", privateKey: "5KBX1dwHME4VyuUss2sYM25D5ZTDvyYrbEz37UJqwAVAsR4tGuY", publicKey: "EOS7isxEua78KPVbGzKemH4nj2bWE52gqj8Hkac3tc7jKNvpfWzYS",systemPrivateKey:"5KBX1dwHME4VyuUss2sYM25D5ZTDvyYrbEz37UJqwAVAsR4tGuY", systemPublicKey:"EOS7isxEua78KPVbGzKemH4nj2bWE52gqj8Hkac3tc7jKNvpfWzYS", url: "http://34.220.213.187:8889/v1")
            _ = FIOSDK.sharedInstance(accountName: "fioname11111", privateKey: "5K2HBexbraViJLQUJVJqZc42A8dxkouCmzMamdrZsLHhUHv77jF", publicKey: "EOS5GpUwQtFrfvwqxAv24VvMJFeMHutpQJseTz8JYUBfZXP2zR8VY",systemPrivateKey:"5KBX1dwHME4VyuUss2sYM25D5ZTDvyYrbEz37UJqwAVAsR4tGuY", systemPublicKey:"EOS7isxEua78KPVbGzKemH4nj2bWE52gqj8Hkac3tc7jKNvpfWzYS", url: "http://18.210.240.10:8889/v1", mockUrl: "http://localhost:8080")
        }

        else{
            _ = FIOSDK.sharedInstance(accountName: accountName,  privateKey: privateKey, publicKey: publicKey, systemPrivateKey: "", systemPublicKey: "", url: url)
        }
        
//
//        let expectation = XCTestExpectation(description: "testRegisterFIOName")
//
//        let publicReceiveAddresses:Dictionary<String,String> = ["ETH":requesteeAddress]
//        FIOSDK.sharedInstance().registerFioName(fioName: requesteeFioName, publicReceiveAddresses: publicReceiveAddresses, completion: {error in ()
//            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
//            print (self.requesteeFioName)
//
//            let receiveAddresses:Dictionary<String,String> = ["ETH":self.requestorAddress]
//            FIOSDK.sharedInstance().registerFioName(fioName: self.requestorFioName, publicReceiveAddresses: receiveAddresses, completion: {error in ()
//                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL" + (error?.localizedDescription ?? "") )
//                print(error)
//                print(self.requestorFioName)
//                expectation.fulfill()
//            })
//
//        })
//
//        wait(for: [expectation], timeout: TIMEOUT)
//

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRandomAccountString (){
        let newAccountName = FIOSDK.sharedInstance().createRandomAccountName()
        print(newAccountName)
        XCTAssert(newAccountName.count == 12, "newAccountName should be 12 chars")
    }
    

    func testValidation(){
        
        XCTAssert(FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd"), "should be valid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "test1234567890123456.brd"), "should be valid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd.brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test#!.brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test12345678901234567.brd"), "should be invalid")
    }

    func testGetRegisteredFioName(){
        let expectation = XCTestExpectation(description: "testGetRegisteredFioName")
        
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: self.requesteeFioName, tokenCode: "ETH") { (response, error) in
            XCTAssert(error.kind == .Success, "getPublicAddress error")
            XCTAssertNotNil(response, "getPublicAddress error")
            
            FIOSDK.sharedInstance().getFioNames(publicAddress: self.requesteeAddress, completion: { (response, error) in
                XCTAssertNotNil(response?.addresses.first?.address, "getFioNames NOT FOUND")
                expectation.fulfill()
            })
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
 
    func testRequestFundsByAddressAndApproveFunds(){
//        let expectation = XCTestExpectation(description: "testRequestFundsByAddress")
//
//        FIOSDK.sharedInstance().requestFundsByAddress(requestorAddress: self.requestorAddress, requestorCurrencyCode: "ETH", requesteeFioName: self.requesteeFioName, chain: "FIO", asset: "ETH", amount: 1.0000, memo: "shawn test request by address") { (error) in
//            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "requestFundsByAddress NOT SUCCESSFUL")
//
//            FIOSDK.sharedInstance().getRequesteePendingHistoryByAddress(address: self.requesteeAddress, currencyCode: "ETH", maxItemsReturned: 10, completion: { (response, error) in
//                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testGetPendingRequestHistoryByAddress NOT SUCCESSFUL")
//                XCTAssert(response.count > 0 , "testGetPendingRequestHistoryByAddress NOT SUCCESSFUL")
//
//                if (response.count > 0 ){
//                    FIOSDK.sharedInstance().approveRequestFunds(requesteeAccountName: response[0].requesteeAccountName, fioAppId: response[0].fioappid, obtId:"" , memo: "")  { (error) in
//                        XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testApproveFunds NOT SUCCESSFUL")
//                        expectation.fulfill()
//                    }
//                }
//                else {
//                    expectation.fulfill()
//                }
//            })
//        }
//
//        wait(for: [expectation], timeout: TIMEOUT)
    }

    //getRequestorHistoryByAddress
    
    func testGetRequestorHistoryAndCancel(){
        let expectation = XCTestExpectation(description: "testGetRequestorHistory")
        FIOSDK.sharedInstance().requestFunds(from: self.requesteeFioName, to: self.requestorFioName, toPublicAddress: self.requestorAddress, amount: "1.000", tokenCode: "ETH", metadata: FIOSDK.RequestFundsRequest.MetaData(memo: "memo", hash: nil, offlineUrl: nil)) { (requestFundsResponse, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "requestFundsByAddress NOT SUCCESSFUL")
            
            FIOSDK.sharedInstance().getRequestorHistoryByFioName(fioName : self.requestorFioName, currencyCode: "ETH", maxItemsReturned: 100, completion: { (response, error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "getRequestorHistoryByFioName NOT SUCCESSFUL")
                XCTAssert(response.count > 0 , "getRequestorHistoryByFioName NOT SUCCESSFUL")
                
                if (response.count > 0 ){
                    FIOSDK.sharedInstance().cancelRequestFunds(requestorAccountName: response[0].requestorAccountName, requestId: response[0].requestid, memo: "cancel shawn text")  { (error) in
                        XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testApproveFunds NOT SUCCESSFUL")
                        expectation.fulfill()
                    }
                }
                else {
                    expectation.fulfill()
                }
                
            })
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }

    func testGetRequestorHistoryByAddress(){
        let expectation = XCTestExpectation(description: "testGetRequestorHistoryByAddress")
        
        FIOSDK.sharedInstance().requestFunds(from: self.requesteeFioName, to: self.requestorFioName, toPublicAddress: self.requestorAddress, amount: "1.0000", tokenCode: "ETH", metadata: FIOSDK.RequestFundsRequest.MetaData(memo: "MEMO", hash: nil, offlineUrl: nil)) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "requestFundsByAddress NOT SUCCESSFUL")
            
            FIOSDK.sharedInstance().getRequestorHistoryByAddress(address: self.requestorAddress, currencyCode: "ETH", maxItemsReturned: 10, completion: { (response, error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "getRequestorHistoryByFioName NOT SUCCESSFUL")
                XCTAssert(response.count > 0 , "getRequestorHistoryByFioName NOT SUCCESSFUL")
                
                expectation.fulfill()
            })
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testIsAvailable(){
        let expectation = XCTestExpectation(description: "testIsAvailable")
        
        FIOSDK.sharedInstance().isAvailable(fioAddress:self.requestorFioName) { (isAvailable, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testIsAvailable NOT SUCCESSFUL")
            
            XCTAssert((isAvailable == false), "testIsAvailable NOT SUCCESSFUL")
                
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    /// Tests the addPublic address method on FIOSDK using constant values ->
    /// address: self.requestorFioName, chain: "FIO", publicAddress: self.requesteeAddress
    func testAddPublicAddress(){
        let expectation = XCTestExpectation(description: "testaddpublicaddress")
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chain: "ETH", publicAddress: self.requesteeAddress) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    
    /// Tests the getPendingFioRequests method on FIOSDK using constant values ->
    /// publicAddress = self.requesteeAddress
    func testGetPendingFioRequests(){
        let expectation = XCTestExpectation(description: "testgetpendingfiorequest")
        FIOSDK.sharedInstance().getPendingFioRequests(fioPublicAddress: self.requesteeAddress) { (data, error) in
            XCTAssert(error?.kind == FIOError.ErrorKind.Success, "testgetpendingfiorequest not successful: \(error?.localizedDescription ?? "unknown")")
            XCTAssertNotNil(data, "testgetpendingfiorequest result came out nil")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    
    /// Tests the getFioNames method on FIOSDK using constant values ->
    /// fioPublicAddress = sself.requesteeAddress
    func testGetFioNames(){
        let expectation = XCTestExpectation(description: "testgetfionames")
        FIOSDK.sharedInstance().getFioNames(publicAddress: self.requesteeAddress) { (data, error) in
            XCTAssert(error?.kind == FIOError.ErrorKind.Success, "testgetfionames not successful: \(error?.localizedDescription ?? "unknown")")
            XCTAssertNotNil(data, "testgetfionames result came out nil")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    /// Tests the getPublicAddress method on FIOSDK using constant values ->
    /// fioAddress: self.requesteeFioName, tokenCode: "BTC"
    func testGetPublicAddress(){
        let expectation = XCTestExpectation(description: "testgetpublicaddress")
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: requesteeFioName, tokenCode: "BTC") { (response, error) in
            XCTAssert(error.kind == .Success, "testgetpublicaddress not succesful")
            XCTAssertNotNil(response, "testgetpublicaddress not successful: \(error.localizedDescription)")
            XCTAssertFalse(response!.publicAddress.isEmpty, "testgetpublicadddress not succesful no public address was found")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    /// Tests the requestFUnds method on FIOSDK
    /// ```
    /// //using the following constant values:
    /// from: self.requesteeFioName
    /// to: self.requestorFioName
    /// toPublicAddress: self.requestorAddress
    /// ```
    func testRequestFunds(){
        let expectation = XCTestExpectation(description: "testRequestFunds")
        let metadata = FIOSDK.RequestFundsRequest.MetaData(memo: "this is the memo", hash: nil, offlineUrl: nil)
        FIOSDK.sharedInstance().requestFunds(from: requesteeFioName, to: requestorFioName, toPublicAddress: requestorAddress, amount: "100", tokenCode: "BTC", metadata: metadata) { (_, error) in
            XCTAssert(error?.kind == .Success, "requestFunds failed")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRejectFundsRequest(){
        let expectation = XCTestExpectation(description: "testRejectFundsRequest")
        let amount = Double.random(in: 1111.0...4444)
        FIOSDK.sharedInstance().requestFunds(from: self.requesteeFioName, to: requestorFioName, toPublicAddress: requestorAddress, amount: String(amount), tokenCode: "BTC", metadata: FIOSDK.RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)) { (response, error) in
            XCTAssert(error?.kind == .Success && response != nil, "testRejectFundsRequest Couldn't create mock request")
            
            FIOSDK.sharedInstance().rejectFundsRequest(fundsRequestId: response!.fundsRequestId, completion: { (response, error) in
                XCTAssert(error.kind == .Success, "testRejectFundsRequest couldn't reject request")
                expectation.fulfill()
            })
            
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
}
