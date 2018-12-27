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
             _ = FIOSDK.sharedInstance(accountName: "fioname11111", privateKey: "5K2HBexbraViJLQUJVJqZc42A8dxkouCmzMamdrZsLHhUHv77jF", publicKey: "EOS5GpUwQtFrfvwqxAv24VvMJFeMHutpQJseTz8JYUBfZXP2zR8VY",systemPrivateKey:"5KBX1dwHME4VyuUss2sYM25D5ZTDvyYrbEz37UJqwAVAsR4tGuY", systemPublicKey:"EOS7isxEua78KPVbGzKemH4nj2bWE52gqj8Hkac3tc7jKNvpfWzYS", url: "http://18.210.240.10:8889/v1")
        }

        else{
            _ = FIOSDK.sharedInstance(accountName: accountName,  privateKey: privateKey, publicKey: publicKey, systemPrivateKey: "", systemPublicKey: "", url: url)
        }
        

        let expectation = XCTestExpectation(description: "testRegisterFIOName")
        
        let publicReceiveAddresses:Dictionary<String,String> = ["ETH":requesteeAddress]
        FIOSDK.sharedInstance().registerFioName(fioName: requesteeFioName, publicReceiveAddresses: publicReceiveAddresses, completion: {error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
            print (self.requesteeFioName)
            
            let receiveAddresses:Dictionary<String,String> = ["ETH":self.requestorAddress]
            FIOSDK.sharedInstance().registerFioName(fioName: self.requestorFioName, publicReceiveAddresses: receiveAddresses, completion: {error in ()
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL" + (error?.localizedDescription ?? "") )
                print(error)
                print(self.requestorFioName)
                expectation.fulfill()
            })
            
        })
        
        wait(for: [expectation], timeout: TIMEOUT)


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
   
        FIOSDK.sharedInstance().getAddressByFioName(fioName: self.requesteeFioName, currencyCode: "ETH", completion: { result, error in ()
            print(result.address)
            print(result.isRegistered)
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "getAddressByFIOName NOT FOUND")
            
            FIOSDK.sharedInstance().getFioNameByAddress(publicAddress: self.requesteeAddress, currencyCode: "ETH", completion:  {result, error in ()
                print(result.name)
                XCTAssert((result.name.count > 3), "getFioNameByAddress NOT FOUND")
                expectation.fulfill()
            })
            
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
 
    func testRequestFundsByAddressAndApproveFunds(){
        let expectation = XCTestExpectation(description: "testRequestFundsByAddress")

        FIOSDK.sharedInstance().requestFundsByAddress(requestorAddress: self.requestorAddress, requestorCurrencyCode: "ETH", requesteeFioName: self.requesteeFioName, chain: "FIO", asset: "ETH", amount: 1.0000, memo: "shawn test request by address") { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "requestFundsByAddress NOT SUCCESSFUL")
            
            FIOSDK.sharedInstance().getRequesteePendingHistoryByAddress(address: self.requesteeAddress, currencyCode: "ETH", maxItemsReturned: 10, completion: { (response, error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testGetPendingRequestHistoryByAddress NOT SUCCESSFUL")
                XCTAssert(response.count > 0 , "testGetPendingRequestHistoryByAddress NOT SUCCESSFUL")
                
                if (response.count > 0 ){
                    FIOSDK.sharedInstance().approveRequestFunds(requesteeAccountName: response[0].requesteeAccountName, fioAppId: response[0].fioappid, obtId:"" , memo: "")  { (error) in
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

    func testRequestFundsByAddressAndRejectFunds(){
        let expectation = XCTestExpectation(description: "testRequestFundsByAddress")
        
        FIOSDK.sharedInstance().requestFundsByAddress(requestorAddress: self.requestorAddress, requestorCurrencyCode: "ETH", requesteeFioName: self.requesteeFioName, chain: "FIO", asset: "ETH", amount: 1.0000, memo: "shawn test request by address") { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "requestFundsByAddress NOT SUCCESSFUL")
            
            FIOSDK.sharedInstance().getRequesteePendingHistoryByAddress(address: self.requesteeAddress, currencyCode: "ETH", maxItemsReturned: 10, completion: { (response, error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testGetPendingRequestHistoryByAddress NOT SUCCESSFUL")
                XCTAssert(response.count > 0 , "testGetPendingRequestHistoryByAddress NOT SUCCESSFUL")
                
                if (response.count > 0 ){
                    FIOSDK.sharedInstance().rejectRequestFunds(requesteeAccountName: response[0].requesteeAccountName, fioAppId: response[0].fioappid, memo: "")  { (error) in
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

    //getRequestorHistoryByAddress
    
    func testGetRequestorHistoryAndCancel(){
        let expectation = XCTestExpectation(description: "testGetRequestorHistory")
        
        FIOSDK.sharedInstance().requestFundsByAddress(requestorAddress: self.requestorAddress, requestorCurrencyCode: "ETH", requesteeFioName: self.requesteeFioName, chain: "FIO", asset: "ETH", amount: 1.0000, memo: "shawn test request by address") { (error) in
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
        
        FIOSDK.sharedInstance().requestFundsByAddress(requestorAddress: self.requestorAddress, requestorCurrencyCode: "ETH", requesteeFioName: self.requesteeFioName, chain: "FIO", asset: "ETH", amount: 1.0000, memo: "shawn test request by address") { (error) in
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
        let expectation = XCTestExpectation(description: "testGetRequestorHistoryByAddress")
        
        FIOSDK.sharedInstance().isAvailable(fioAddress:self.requestorFioName) { (isAvailable, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "isFioAddressOrDomainRegistered NOT SUCCESSFUL")
            
            XCTAssert((isAvailable == false), "isFioAddressOrDomainRegistered NOT SUCCESSFUL")
                
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testAddAddress(){
        let expectation = XCTestExpectation(description: "testaddaddress")
        let publicReceiveAddresses:Dictionary<String,String> = ["ETH":requestorAddress]
        FIOSDK.sharedInstance().addAllPublicAddresses(fioName: self.requestorFioName, publicReceiveAddresses:publicReceiveAddresses, completion:{ (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testaddaddress NOT SUCCESSFUL")
       
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
}
