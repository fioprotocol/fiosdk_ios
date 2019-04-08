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
    
    //MARK: Constants
    private let defaultAccount  = "fioname11111"
    private let defaultServer   = "http://34.214.170.140:8889/v1"
    private let defaultMnemonic = "valley alien library bread worry brother bundle hammer loyal barely dune brave"
    
    private let alternativeServerA = "http://54.202.124.82:8889/v1"
    private let alternativeServerB = "http://54.218.97.18:8889/v1"
    private let alternativeServerC = "http://34.213.160.31:8889/v1"
    private let alternativeServerD = "http://34.214.170.140:8889/v1"
    
    private let fioAccount    = "r41zuwovtn44"
    private let fioPrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
    private let fioPublicKey  = "EOS5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
    private let fioServer     = "http://18.236.248.110:8889/v1"
    
    private let fioAccountAlternative    = "htjonrkf1lgs"
    private let fioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
    private let fioPublicKeyAlternative  = "EOS7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"
    
    //MARK: test variables
    private var requesteeFioName: String = ""
    private let requesteeAddress:String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
    private var requestorFioName: String = ""
    private let requestorAddress:String = "0x3A2522321656285661Df2012a3A05bEF84C8B1ed"
    
    //MARK: Setup
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let timestamp = NSDate().timeIntervalSince1970
        requesteeFioName = "sha\(Int(timestamp.rounded())).brd"
        requestorFioName = "bar\(Int(timestamp.rounded())).brd"
        
        if (useStaging){
            let keyPair = FIOSDK.privatePubKeyPair(forMnemonic: defaultMnemonic)
            _ = FIOSDK.sharedInstance(accountName: defaultAccount, privateKey: keyPair.privateKey, publicKey: keyPair.publicKey,systemPrivateKey:keyPair.privateKey, systemPublicKey:keyPair.publicKey, url: defaultServer, mockUrl: "http://localhost:8080")
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
    
    //MARK: -

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
        let expectationAddPubAddA = XCTestExpectation(description: "testgetpendingfiorequest")
        let expectationAddPubAddB = XCTestExpectation(description: "testgetpendingfiorequest")
        let expectationReqFunds = XCTestExpectation(description: "testgetpendingfiorequest")
        let expectationPendingReq = XCTestExpectation(description: "testgetpendingfiorequest")
        let metadata = RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
        let timestamp = NSDate().timeIntervalSince1970
        let from = self.requestorFioName
        let to = self.requesteeFioName
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "BTC", publicAddress: fromPubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            expectationAddPubAddA.fulfill()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "BTC", publicAddress: toPubAdd) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                expectationAddPubAddB.fulfill()
                FIOSDK.sharedInstance().requestFunds(from: from, to: to, toPublicAddress: toPubAdd, amount: 1.0, tokenCode: "BTC", metadata: metadata) { (response, error) in
                    if error?.kind == .Success {
                        expectationReqFunds.fulfill()
                        FIOSDK.sharedInstance().getPendingFioRequests(fioPublicAddress: fromPubAdd) { (data, error) in
                            XCTAssert(error?.kind == FIOError.ErrorKind.Success, "testgetpendingfiorequest not successful: \(error?.localizedDescription ?? "unknown")")
                            XCTAssertNotNil(data, "testgetpendingfiorequest result came out nil")
                            expectationPendingReq.fulfill()
                        }
                    }
                    else {
                        XCTFail("Failed to call requestFunds prior to getting pending requests")
                        expectationReqFunds.fulfill()
                    }
                }
            }
        }
        wait(for: [expectationAddPubAddA,expectationAddPubAddB, expectationReqFunds, expectationPendingReq], timeout: TIMEOUT)
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
    
    
    func testGetFIONameDetailsWithGoodNameShouldSucceed() {
        let expectation = XCTestExpectation(description: "testGetFIONameDetailsWithGoodNameShouldSucceed")
        
        FIOSDK.sharedInstance().getFIONameDetails(self.requesteeFioName) { (response, error) in
            XCTAssert(error.kind == .Success, "getPublicAddress error")
            XCTAssertNotNil(response, "getPublicAddress error")
            
            if error.kind != .Success {
                expectation.fulfill()
            }
            else {
                XCTAssertNotNil(response?.address, "name NOT FOUND")
                XCTAssertNotNil(response?.expiration, "date NOT FOUND")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetFIONameDetailsWithBadNameShouldFail() {
        let expectation = XCTestExpectation(description: "testGetFIONameDetailsWithBadNameShouldFail")
        
        FIOSDK.sharedInstance().getFIONameDetails("NOT_VALID_NAME") { (response, error) in
            XCTAssert(error.kind == .Failure, "Should've failed but succeeded")
            XCTAssertNil(response)
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
    
    func testGetTokenPublicAddressWithValidPubAddressShouldSucceed() {
        let expectation = XCTestExpectation(description: "testGetTokenPublicAddressWithValidPubAddressShouldSucceed")
        
        let timestamp = NSDate().timeIntervalSince1970
        let tokenPubAdd = "smp\(Int(timestamp.rounded()))"
        
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chain: "SMP", publicAddress: tokenPubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "getTokenPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            
            FIOSDK.sharedInstance().getTokenPublicAddress(forToken: "SMP", withFIOPublicAddress: tokenPubAdd, onCompletion: { (response, error) in
                XCTAssert(error.kind == .Success, "getTokenPublicAddress failed")
                XCTAssertNotNil(response)
                expectation.fulfill()
            })
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }    
    
    func testGetTokenPublicAddressWithInvalidTokenShouldFail() {
        let expectation = XCTestExpectation(description: "testGetTokenPublicAddressWithInvalidTokenShouldFail")
        
        let timestamp = NSDate().timeIntervalSince1970
        let tokenPubAdd = "smp\(Int(timestamp.rounded()))"
        
        FIOSDK.sharedInstance().getTokenPublicAddress(forToken: "NOTVALIDTOKEN", withFIOPublicAddress: tokenPubAdd, onCompletion: { (response, error) in
            XCTAssert(error.kind == .Failure, "should've failed")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRequestFundsWithGeneratedAccountShouldSucceed(){
        let expectation = XCTestExpectation(description: "testRequestFundsWithGeneratedAccountShouldSucceed")
        let metadata = RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
        
        FIOSDK.sharedInstance().requestFunds(from: self.requestorFioName, to: self.requesteeFioName, toPublicAddress: self.requesteeAddress, amount: 1.0, tokenCode: "DAI", metadata: metadata) { (response, error) in
            XCTAssert(error?.kind == .Success, "requestFunds failed")
            XCTAssertNotNil(response)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRequestFundsWithNewPubAddressesAccountsShouldSucceed(){
        let expectation = XCTestExpectation(description: "testRequestFundsWithNewPubAddressesAccountsShouldSucceed")
        let metadata = RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
        
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
    
    func testRejectFundsRequest(){
        let expectation = XCTestExpectation(description: "testRejectFundsRequest")
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
                
                //requestor is sender, requestee is receiver
                FIOSDK.sharedInstance().requestFunds(from: from, to: to, toPublicAddress: toPubAdd, amount: amount, tokenCode: "BTC", metadata: RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)) { (response, error) in
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
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "ETH", publicAddress: fromPubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "ETH", publicAddress: toPubAdd) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                FIOSDK.sharedInstance().requestFunds(from: from, to: to, toPublicAddress: toPubAdd, amount: amount, tokenCode: "BTC", metadata: RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)) { (response, error) in
                    XCTAssert(error?.kind == .Success && response != nil, "testGetSentRequests Couldn't create mock request")
                    expRequestFunds.fulfill()
                    guard let fundsRequestId = response?.fundsRequestId else {
                        expGetSentRequest.fulfill()
                        expRejectRequest.fulfill()
                        return
                    }
                    FIOSDK.sharedInstance().getSentFioRequest(publicAddress: toPubAdd, completion: { (response, error) in
                        XCTAssert(error.kind == .Success && response != nil, "testGetSentRequest couldn't retreive request")
                        guard error.kind == .Success, response != nil else {
                            XCTFail("getSentFioRequest Request should have sent fio requests")
                            expGetSentRequest.fulfill()
                            expRejectRequest.fulfill()
                            return
                        }
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
    
    func testRecordSendWithFakeDataShouldSucceeded() {
        let expectation = XCTestExpectation(description: "testRecordSendWithFakeDataShouldSucceeded")
        
        let amount = Float.random(in: 1111.0...4444)
        let from = self.requestorFioName
        let to = self.requesteeFioName
        let timestamp = NSDate().timeIntervalSince1970
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        let obtID = "0xf6eaddd3851923f6f9653838d3021c02ab123a4a6e4485e83f5063b3711e000b"
        
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "VIT", publicAddress: fromPubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            guard error?.kind == FIOError.ErrorKind.Success else {
                expectation.fulfill()
                return
            }
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "VIT", publicAddress: toPubAdd) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                guard error?.kind == FIOError.ErrorKind.Success else {
                    expectation.fulfill()
                    return
                }
                
                FIOSDK.sharedInstance().recordSend(fromFIOAdd: from, toFIOAdd: to, fromPubAdd: fromPubAdd, toPubAdd: toPubAdd, amount: amount, fromTokenCode: "VIT", toTokenCode: "VIT", obtID: obtID, memo: "Record Send Unit Test") { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "recordSend NOT SUCCESSFUL")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRecordSendAutoResolveWithFakeDataShouldSucceeded() {
        let expectation = XCTestExpectation(description: "testRecordSendAutoResolveWithFakeDataShouldSucceeded")
        
        let amount = Float.random(in: 1111.0...4444)
        let from = self.requestorFioName
        let to = self.requesteeFioName
        let timestamp = NSDate().timeIntervalSince1970
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        let obtID = "0xf6eaddd3851923f6f9653838d3021c02ab123a4a6e4485e83f5063b3711e000b"

        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "VIT", publicAddress: fromPubAdd) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            guard error?.kind == FIOError.ErrorKind.Success else {
                expectation.fulfill()
                return
            }
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "VIT", publicAddress: toPubAdd) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                guard error?.kind == FIOError.ErrorKind.Success else {
                    expectation.fulfill()
                    return
                }
                
                FIOSDK.sharedInstance().recordSendAutoResolvingWith(toFIOAdd: to, andFromPubAdd: fromPubAdd, amountSent: amount, forTokenCode: "VIT", obtID: obtID, memo: "Record send unit test") { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "recordSend NOT SUCCESSFUL")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    func testGetFIOPublicAddressWithKeysShouldExist() {
        let keyPair = FIOSDK.privatePubKeyPair(forMnemonic: defaultMnemonic)
        let fioPublicAddress = FIOSDK.sharedInstance(accountName: defaultAccount, privateKey: keyPair.privateKey, publicKey: keyPair.publicKey,systemPrivateKey:keyPair.privateKey, systemPublicKey:keyPair.publicKey, url: defaultServer).getFIOPublicAddress()
        let expected = "ltwagbt4qpuk"
        XCTAssertEqual(fioPublicAddress, expected)
    }
    
    func testGetFIOPublicAddressWithoutKeysShouldBeEmpty() {
        let fioPublicAddress = FIOSDK.sharedInstance(accountName: defaultAccount, privateKey: "", publicKey: "",systemPrivateKey:"", systemPublicKey:"", url: defaultServer).getFIOPublicAddress()
        let expected = ""
        XCTAssertEqual(fioPublicAddress, expected)
    }
    
    func testGetFIOBalanceWithProperSetupShouldReturnValue() {
        let expectation = XCTestExpectation(description: "testGetFIOBalanceWithProperSetupShouldReturnValue")

        let fioSDK = FIOSDK.sharedInstance(accountName: fioAccount, privateKey: fioPrivateKey, publicKey: fioPublicKey,systemPrivateKey:fioPrivateKey, systemPublicKey:fioPublicKey, url: fioServer)
        let fioPubAddress = fioSDK.getFIOPublicAddress()
        
        fioSDK.getFIOBalance(fioPublicAddress: fioPubAddress) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "Get FIO Balance NOT SUCCESSFUL: \(error.localizedDescription )")
            XCTAssert((response?.balance != nil && !response!.balance.isEmpty), "Balance is empty:")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetFIOBalanceWithWrongAccountShouldReturnError() {
        let expectation = XCTestExpectation(description: "testGetFIOBalanceWithWrongAccountShouldReturnError")
        
        let fioSDK = FIOSDK.sharedInstance(accountName: fioAccount, privateKey: fioPrivateKey, publicKey: fioPublicKey,systemPrivateKey:fioPrivateKey, systemPublicKey:fioPublicKey, url: fioServer)
        let fioPubAddress = "ltwagbt4qpuk"
        
        fioSDK.getFIOBalance(fioPublicAddress: fioPubAddress) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Failure), "Get FIO Balance Found non existent account: \(error.localizedDescription )")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testTransferTokensWithGoodAccountsShouldBeSuccessful() {
        let expectation = XCTestExpectation(description: "testTransferTokensWithGoodAccountsShouldBeSuccessful")
        
        let fioSDK = FIOSDK.sharedInstance(accountName: fioAccount, privateKey: fioPrivateKey, publicKey: fioPublicKey,systemPrivateKey:fioPrivateKey, systemPublicKey:fioPublicKey, url: fioServer)
        let toFIOPubAddress = "htjonrkf1lgs"
        let fromFIOPubAddress = "r41zuwovtn44"
        let amount: Float = 1.0
        
        fioSDK.transferFIOTokens(toFIOPublicAddress: toFIOPubAddress, amount: amount) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
            //Transfer back
            FIOSDK.sharedInstance(accountName: self.fioAccountAlternative, privateKey: self.fioPrivateKeyAlternative, publicKey: self.fioPublicKeyAlternative, systemPrivateKey:self.fioPrivateKeyAlternative, systemPublicKey:self.fioPublicKeyAlternative, url: self.fioServer).transferFIOTokens(toFIOPublicAddress: fromFIOPubAddress, amount: amount) { (response, error) in
                XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testTransferTokensWithInsufficientAmountShouldNotBeSuccessful() {
        let expectation = XCTestExpectation(description: "testTransferTokensWithInsufficientAmountShouldNotBeSuccessful")
        
        let fioSDK = FIOSDK.sharedInstance(accountName: fioAccount, privateKey: fioPrivateKey, publicKey: fioPublicKey,systemPrivateKey:fioPrivateKey, systemPublicKey:fioPublicKey, url: fioServer)
        let toFIOPubAddress = "htjonrkf1lgs"
        let amount: Float = 9000000.0
        
        fioSDK.transferFIOTokens(toFIOPublicAddress: toFIOPubAddress, amount: amount) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Failure), "transfer failed: \(error.localizedDescription )")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
}
