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
    private let TIMEOUT:Double = 240.0
    
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
//            _ = FIOSDK.sharedInstance(accountName: "fioname11111", privateKey: "5K2HBexbraViJLQUJVJqZc42A8dxkouCmzMamdrZsLHhUHv77jF", publicKey: "EOS5GpUwQtFrfvwqxAv24VvMJFeMHutpQJseTz8JYUBfZXP2zR8VY",systemPrivateKey:"5KBX1dwHME4VyuUss2sYM25D5ZTDvyYrbEz37UJqwAVAsR4tGuY", systemPublicKey:"EOS7isxEua78KPVbGzKemH4nj2bWE52gqj8Hkac3tc7jKNvpfWzYS", url: "http://18.210.240.10:8889/v1", mockUrl: "http://localhost:8080")
            _ = FIOSDK.sharedInstance(accountName: "fioname11111", privateKey: "5K2HBexbraViJLQUJVJqZc42A8dxkouCmzMamdrZsLHhUHv77jF", publicKey: "EOS5GpUwQtFrfvwqxAv24VvMJFeMHutpQJseTz8JYUBfZXP2zR8VY",systemPrivateKey:"5KBX1dwHME4VyuUss2sYM25D5ZTDvyYrbEz37UJqwAVAsR4tGuY", systemPublicKey:"EOS7isxEua78KPVbGzKemH4nj2bWE52gqj8Hkac3tc7jKNvpfWzYS", url: "http://34.214.170.140:8889/v1", mockUrl: "http://localhost:8080")//54.202.124.82:8889// 54.218.97.18:8889 //34.213.160.31:8889
            
        }

        else{
            _ = FIOSDK.sharedInstance(accountName: accountName,  privateKey: privateKey, publicKey: publicKey, systemPrivateKey: "", systemPublicKey: "", url: url)
        }
        

        let expectation = XCTestExpectation(description: "testRegisterFIOName")

        FIOSDK.sharedInstance().registerFioName(fioName: requesteeFioName, publicReceiveAddresses: [:] , completion: {error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
            print (self.requesteeFioName)

            FIOSDK.sharedInstance().registerFioName(fioName: self.requestorFioName,publicReceiveAddresses: [:], completion: {error in ()
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

    func testValidation(){
        
        XCTAssert(FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd"), "should be valid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "test1234567890123456.brd"), "should be valid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd.brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test#!.brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test12345678901234567.brd"), "should be invalid")
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
        let timestamp = NSDate().timeIntervalSince1970
        let pubAdd = "pubAdd\(Int(timestamp.rounded()))"
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chain: "ETH", publicAddress: pubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    
    /// Tests the getPendingFioRequests method on FIOSDK using constant values ->
    /// publicAddress = self.requesteeAddress
    func testGetPendingFioRequests(){
        let expectation = XCTestExpectation(description: "testgetpendingfiorequest")
        let metadata = FIOSDK.RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
        let timestamp = NSDate().timeIntervalSince1970
        let from = self.requestorFioName
        let to = self.requesteeFioName
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "BTC", publicAddress: fromPubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "BTC", publicAddress: toPubAdd) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                FIOSDK.sharedInstance().requestFunds(from: from, to: to, toPublicAddress: toPubAdd, amount: 1.0, tokenCode: "BTC", metadata: metadata) { (response, error) in
                    if error?.kind == .Success {
                        FIOSDK.sharedInstance().getPendingFioRequests(fioPublicAddress: fromPubAdd) { (data, error) in
                            XCTAssert(error?.kind == FIOError.ErrorKind.Success, "testgetpendingfiorequest not successful: \(error?.localizedDescription ?? "unknown")")
                            XCTAssertNotNil(data, "testgetpendingfiorequest result came out nil")
                            expectation.fulfill()
                        }
                    }
                    else {
                        XCTFail("Failed to call requestFunds prior to getting pending requests")
                        expectation.fulfill()
                    }
                }
            }
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetFIONameFromPubAddress(){
        let expectation = XCTestExpectation(description: "testGetRegisteredFioName")
        
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: self.requesteeFioName, tokenCode: "FIO") { (response, error) in
            XCTAssert(error.kind == .Success, "getPublicAddress error")
            XCTAssertNotNil(response, "getPublicAddress error")
            
            if error.kind != .Success {
                expectation.fulfill()
            }
            else {
                FIOSDK.sharedInstance().getFioNames(publicAddress: response!.publicAddress, completion: { (response, error) in
                    XCTAssertNotNil(response?.addresses.first?.address, "getFioNames NOT FOUND")
                    expectation.fulfill()
                })
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    func testGetFioNamesWithUnvalidAddressShouldRespondWithNotFound(){
        let expectation = XCTestExpectation(description: "testgetfionames")
        FIOSDK.sharedInstance().getFioNames(publicAddress: "NOT VALID ADDRESS") { (data, error) in
            XCTAssert(error?.kind == FIOError.ErrorKind.Failure, "Should have failed")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    /// Tests the getPublicAddress method on FIOSDK using constant values ->
    /// fioAddress: self.requesteeFioName, tokenCode: "BTC"
    func testGetPublicAddress(){
        let expectation = XCTestExpectation(description: "testgetpublicaddress")
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: requesteeFioName, tokenCode: "FIO") { (response, error) in
            XCTAssert(error.kind == .Success, "testgetpublicaddress not succesful")
            XCTAssertNotNil(response, "testgetpublicaddress not successful: \(error.localizedDescription)")
            XCTAssertFalse(response!.publicAddress.isEmpty, "testgetpublicadddress not succesful no public address was found")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetPublicAddressWithNonRegisteredTokenShouldFail(){
        let expectation = XCTestExpectation(description: "testgetpublicaddress")
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: requesteeFioName, tokenCode: "NOTVALID") { (response, error) in
            XCTAssert(error.kind == .Failure, "should've failed")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRequestFundsWithGeneratedAccountShouldSucceed(){
        let expectation = XCTestExpectation(description: "testRequestFunds")
        let metadata = FIOSDK.RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
        
        FIOSDK.sharedInstance().requestFunds(from: self.requestorFioName, to: self.requesteeFioName, toPublicAddress: self.requesteeAddress, amount: 1.0, tokenCode: "DAI", metadata: metadata) { (response, error) in
            XCTAssert(error?.kind == .Success, "requestFunds failed")
            XCTAssertNotNil(response)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRequestFundsWithNewPubAddressesAccountsShouldSucceed(){
        let expectation = XCTestExpectation(description: "testRequestFunds")
        let metadata = FIOSDK.RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
        
        let from = self.requestorFioName
        let to = self.requesteeFioName
        let timestamp = NSDate().timeIntervalSince1970
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "BTC", publicAddress: fromPubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "BTC", publicAddress: toPubAdd) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
        
                FIOSDK.sharedInstance().requestFunds(from: from, to: to, toPublicAddress: toPubAdd, amount: 1.0, tokenCode: "BTC", metadata: metadata) { (response, error) in
                    XCTAssert(error?.kind == .Success, "requestFunds failed")
                    XCTAssertNotNil(response)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRejectFundsRequestWithDefaultAccountsShouldSucceed(){
        let expectation = XCTestExpectation(description: "testRejectFundsRequest")
        let amount = Float.random(in: 1111.0...4444)
        FIOSDK.sharedInstance().requestFunds(from: "adam.brd ", to: "casey.brd", toPublicAddress: "0xab5801a7d398351b8be11c439e05c5b3259aec9b", amount: amount, tokenCode: "BTC", metadata: FIOSDK.RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)) { (response, error) in
            XCTAssert(error?.kind == .Success && response != nil, "testRejectFundsRequest Couldn't create mock request")
            
            if let response = response {
                FIOSDK.sharedInstance().rejectFundsRequest(fundsRequestId: String(response.fundsRequestId), completion: { (response, error) in
                    XCTAssert(error.kind == .Success, "testRejectFundsRequest couldn't reject request")
                    expectation.fulfill()
                })
            }
            else {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRejectFundsRequest(){
        let expectation = XCTestExpectation(description: "testRejectFundsRequest")
        let amount = Float.random(in: 1111.0...4444)
        //requestor is sender, requestee is receiver
        FIOSDK.sharedInstance().requestFunds(from: self.requestorFioName, to: requesteeFioName, toPublicAddress: requesteeAddress, amount: amount, tokenCode: "BTC", metadata: FIOSDK.RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)) { (response, error) in
            XCTAssert(error?.kind == .Success && response != nil, "testRejectFundsRequest Couldn't create mock request")
            
            if let response = response {
                FIOSDK.sharedInstance().rejectFundsRequest(fundsRequestId: String(response.fundsRequestId), completion: { (response, error) in
                    XCTAssert(error.kind == .Success, "testRejectFundsRequest couldn't reject request")
                    expectation.fulfill()
                })
            }
            else {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    /// Test for get_sent_fio_requests
    func testGetSentRequest(){
        let expRequestFunds = XCTestExpectation(description: "test getSentRequests request funds")
        let expGetSentRequest = XCTestExpectation(description: "test getSentRequests get")
        let expRejectRequest = XCTestExpectation(description: "test getSentRequests reject request")
        
        let amount = Float.random(in: 1111.0...4444)
        let from = self.requestorFioName
        let to = self.requesteeFioName
        let timestamp = NSDate().timeIntervalSince1970
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "BTC", publicAddress: fromPubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "BTC", publicAddress: toPubAdd) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                FIOSDK.sharedInstance().requestFunds(from: from, to: to, toPublicAddress: toPubAdd, amount: amount, tokenCode: "BTC", metadata: FIOSDK.RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)) { (response, error) in
                    XCTAssert(error?.kind == .Success && response != nil, "testGetSentRequests Couldn't create mock request")
                    expRequestFunds.fulfill()
                    guard let fundsRequestId = response?.fundsRequestId else {
                        expGetSentRequest.fulfill()
                        expRejectRequest.fulfill()
                        return
                    }
                    FIOSDK.sharedInstance().getSentFioRequest(publicAddress: toPubAdd, completion: { (response, error) in
                        XCTAssert(error.kind == .Success && response != nil, "testGetSentRequest couldn't retreive request")
                        XCTAssertFalse(response!.requests.filter({ (request) -> Bool in
                            return request.fundsRequestId == fundsRequestId
                        }).isEmpty,  "testGetsentRequest couldn't found the request")
                        expGetSentRequest.fulfill()
                        FIOSDK.sharedInstance().rejectFundsRequest(fundsRequestId: fundsRequestId, completion: { (response, error) in
                            XCTAssert(error.kind == .Success, "testGetSentRequests couldn't reject test request")
                            expRejectRequest.fulfill()
                        })
                    })
                }
            }
        }
        
        wait(for: [expRequestFunds, expGetSentRequest, expRejectRequest], timeout: TIMEOUT)
    }
    
    func testGenerateAccountNameGeneratorWithProperValuesOutputCorrectResult() {
        let publicKey = "EOS6cDpi7vPnvRwMEdXtLnAmFwygaQ8CzD7vqKLBJ2GfgtHBQ4PPy"
        let expectedOutput = "2odzomo2v4pe"
        let accountName = AccountNameGenerator.run(withPublicKey: publicKey)
        XCTAssertEqual(accountName, expectedOutput)
    }
    
    func testGenerateAccountNameGeneratorWithEmptyPubKeyOutputEmptyResult() {
        let publicKey = ""
        let expectedOutput = ""
        let accountName = AccountNameGenerator.run(withPublicKey: publicKey)
        XCTAssertEqual(accountName, expectedOutput)
    }
    
    func testRegisterFIONameWithNewValueShouldRegister() {
        let timestamp = NSDate().timeIntervalSince1970
        let fioName = "sha\(Int(timestamp.rounded())).brd"
        let expectation = XCTestExpectation(description: "testRegisterFIONameWithNewValueShouldRegister")

        FIOSDK.sharedInstance().registerFioName(fioName: fioName, publicReceiveAddresses: ["BTC":"1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs", "ETH":requestorAddress], completion: {error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRegisterFIONameWithAlreadyRegisteredValueShouldFail() {
        let timestamp = NSDate().timeIntervalSince1970
        let fioName = "sha\(Int(timestamp.rounded())).brd"
        let expectation = XCTestExpectation(description: "testRegisterFIONameWithAlreadyRegisteredValueShouldFail")

        FIOSDK.sharedInstance().registerFioName(fioName: fioName, publicReceiveAddresses: [:], completion: {error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
            FIOSDK.sharedInstance().registerFioName(fioName: fioName, publicReceiveAddresses: [:], completion: {error in ()
                XCTAssert((error?.kind == FIOError.ErrorKind.Failure), "registerFIOName NOT SUCCESSFUL")
                expectation.fulfill()
            })
        })

        wait(for: [expectation], timeout: TIMEOUT)
    }
    
}
