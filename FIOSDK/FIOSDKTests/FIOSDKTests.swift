//
//  FIOSDKTests.swift
//  FIOSDKTests
//
//  Created by shawn arney on 10/19/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import XCTest
@testable import FIOSDK

private let useDev2 = false
private let useDev4 = true
private let useDefaultServer = false //want a custom server, set to true and then set the DEFAULT_SERVER to your ip/url

private let SERVER_DEV2 = "http://dev2.fio.dev:8889/v1"
private let MOCK_SERVER_DEV2 = "http://mock.dapix.io/mockd/DEV2/register_fio_name"

private let SERVER_DEV4 = "http://dev4.fio.dev:8889/v1"
private let MOCK_SERVER_DEV4 = "http://mock.dapix.io/mockd/DEV4/register_fio_name"

private let DEFAULT_SERVER = "http://dev4.fio.dev:8889/v1"
private let MOCK_DEFAULT_SERVER = "http://mock.dapix.io/mockd/DEV4/register_fio_name"

class FIOSDKTests: XCTestCase {
    
    private let accountName:String = "exchange1111"
    private let accountNameForRequestFunds:String = "exchange2222"
    private let privateKey:String = "5KDQzVMaD1iUdYDrA2PNK3qEP7zNbUf8D41ZVKqGzZ117PdM5Ap"
    private let publicKey:String = "EOS6D6gSipBmP1KW9SMB5r4ELjooaogFt77gEs25V9TU9FrxKVeFb"
    

    // stage 1 server: 18.223.14.244
    private let TIMEOUT:Double = 240.0
    
    //MARK: Constants
    private let defaultAccount  = "fioname11111"
    private let defaultServer   = (useDev2 ? SERVER_DEV2 : (useDev4 ? SERVER_DEV4 : DEFAULT_SERVER))
    private let defaultMnemonic = "valley alien library bread worry brother bundle hammer loyal barely dune brave"
    private let expectedDefaultPrivateKey = "5Kbb37EAqQgZ9vWUHoPiC2uXYhyGSFNbL6oiDp24Ea1ADxV1qnu"
    private let expectedDefaultPublicKey = "EOS5kJKNHwctcfUM5XZyiWSqSTM5HTzznJP9F3ZdbhaQAHEVq575o"
    private let mockUrl = (useDev2 ? MOCK_SERVER_DEV2 : (useDev4 ? MOCK_SERVER_DEV4 : MOCK_DEFAULT_SERVER))
    
    private let fioAccount    = "r41zuwovtn44"
    private let fioPrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
    private let fioPublicKey  = "EOS5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
    
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

        defaultSDKConfig()

        registerDefaultUsers()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func defaultSDKConfig() {
        try? FIOSDK.wipePrivPubKeys()
        let keyPair = FIOSDK.privatePubKeyPair(forMnemonic: defaultMnemonic)
        _ = FIOSDK.sharedInstance(accountName: defaultAccount, privateKey: keyPair.privateKey, publicKey: keyPair.publicKey,systemPrivateKey:keyPair.privateKey, systemPublicKey:keyPair.publicKey, url: defaultServer, mockUrl: mockUrl)
    }
    
    private func alternativeSDKConfig() {
        try? FIOSDK.wipePrivPubKeys()
        let keyPair = FIOSDK.privatePubKeyPair(forMnemonic: "gallery hero weekend notable inherit chuckle village spread business scrap surprise finger")
        _ = FIOSDK.sharedInstance(accountName: defaultAccount, privateKey: keyPair.privateKey, publicKey: keyPair.publicKey,systemPrivateKey:keyPair.privateKey, systemPublicKey:keyPair.publicKey, url: defaultServer, mockUrl: mockUrl)
    }
    
    func registerDefaultUsers() {
        let timestamp = NSDate().timeIntervalSince1970
        requesteeFioName = "sha\(Int(timestamp.rounded())):brd"
        requestorFioName = "bar\(Int(timestamp.rounded())):brd"
        
        let expectation = XCTestExpectation(description: "testRegisterFIOName")
        
        print (FIOSDK.sharedInstance().getPublicKey())
        FIOSDK.sharedInstance().registerFIONameOnBehalfOfUser(fioName: requesteeFioName, publicKey: FIOSDK.sharedInstance().getPublicKey(), onCompletion: { response, error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
            print (self.requesteeFioName)
            let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
            FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 9, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
                if error?.kind == .Success {
                    sleep(60)
                    
                    self.alternativeSDKConfig()
                    print (FIOSDK.sharedInstance().getPublicKey())
                    FIOSDK.sharedInstance().registerFIONameOnBehalfOfUser(fioName: self.requestorFioName, publicKey: FIOSDK.sharedInstance().getPublicKey(), onCompletion: { response, error in ()
                        XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL" + (error?.localizedDescription ?? "") )
                        print(error)
                        print(self.requestorFioName)
                        
                        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requestorFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 9, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
                            if error?.kind == .Success {
                                sleep(60)
                                
                                self.defaultSDKConfig()
                                expectation.fulfill()
                            }
                        }
                    })
                }
            }
        })
        
//        FIOSDK.sharedInstance().registerFioName(fioName: requesteeFioName, publicReceiveAddresses: [:] , completion: {error in ()
//            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
//            print (self.requesteeFioName)
//
//            FIOSDK.sharedInstance().registerFioName(fioName: self.requestorFioName,publicReceiveAddresses: [:], completion: {error in ()
//                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL" + (error?.localizedDescription ?? "") )
//                print(error)
//                print(self.requestorFioName)
//                expectation.fulfill()
//            })
//
//        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    //MARK: -
    
    func testPublicKeyFromStringShouldGeneratePublicKey() {
        try? FIOSDK.wipePrivPubKeys()
        let mnemonic = "gallery hero weekend notable inherit chuckle village spread business scrap surprise finger"
        let keyPair = FIOSDK.privatePubKeyPair(forMnemonic: mnemonic)
        let privKey = try? PrivateKey(enclave: .Secp256k1, mnemonicString: mnemonic, slip: 235)
        guard let pk = privKey else {
            XCTFail()
            return
        }
        guard let pubkey = try? PublicKey(keyString: keyPair.publicKey) else {
            XCTFail()
            return
        }
        XCTAssert(pubkey!.rawPublicKey() == PublicKey(privateKey: pk!).rawPublicKey())
    }
    
    func testPrivateKeyGetSharedSecret() {
        guard let pk = try? PrivateKey(keyString:"5JSV3LwQNDLYi4yGc1My2bYggDBTSEJNf9TrGYxX4JMnZp4E8AQ") else {
            XCTFail()
            return
        }
        let shared_secret_result = pk!.getSharedSecret(publicKey: "FIO7sfDWLaHU8RqxD4jXHiCxmH9RUR62CsadFKAhwSPk5j5aGFoda")//FIOSDK.sharedInstance().getPublicKey())
        let shared_secret_expected = "5AC4A2297F941BD14727FD8F7463DA138EDF46983EB4AEAE088BE0F7009794555FBB3D8EE9C6D30CF936AA50CA9CB8E68FF675D8C806216262D27AF68288B0A4"
    
        XCTAssert(shared_secret_result == shared_secret_expected, "Shared Secret not Correct")
    }
    
    //MARK: -

    func testValidation(){
        
        XCTAssert(FIOSDK.sharedInstance().isFioNameValid(fioName: "test:brd"), "should be valid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "test1234567890123456:brd"), "should be valid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test:brd:brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test#!:brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "12:brd"), "should be invalid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "brd"), "should be valid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "brd-brd"), "should be valid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "brd-"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "-brd"), "should be invalid")
        
        var domainWith51Chars = ""
        (0...50).forEach { _ in domainWith51Chars.append("1") }
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: domainWith51Chars), "should be invalid")
        
        var addressWith101Chars = ""
        (0...100).forEach { _ in addressWith101Chars.append("1") }
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: addressWith101Chars), "should be invalid")
        
    }
    
    func testIsAvailableWithAlreadyTakenNameShouldNotBeAvailable(){
        let expectation = XCTestExpectation(description: "testIsAvailable")
        
        FIOSDK.sharedInstance().isAvailable(fioAddress:self.requestorFioName) { (isAvailable, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testIsAvailable NOT SUCCESSFUL")
            
            XCTAssert((isAvailable == false), "testIsAvailable NOT SUCCESSFUL")
                
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testIsAvailableWithNewNameShouldBeAvailable(){
        let expectation = XCTestExpectation(description: "testIsAvailable")
        let timestamp = NSDate().timeIntervalSince1970
        let fioAddress = "fioaddress\(Int(timestamp.rounded())):brd"
        FIOSDK.sharedInstance().isAvailable(fioAddress:fioAddress) { (isAvailable, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testIsAvailable NOT SUCCESSFUL")
            
            XCTAssert((isAvailable == true), "testIsAvailable NOT SUCCESSFUL")
            
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
        self.alternativeSDKConfig()
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chain: "ETH", publicAddress: pubAdd, maxFee: 0) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testAddPublicAddressWithFIOTokenShouldFail(){
        let expectation = XCTestExpectation(description: "testaddpublicaddress")
        let timestamp = NSDate().timeIntervalSince1970
        let pubAdd = "pubAdd\(Int(timestamp.rounded()))"
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chain: "FIO", publicAddress: pubAdd, maxFee: 0) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), "testAddPublicAddressWithFIOTokenShouldFail tried to add FIO Token address.")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testAddPublicKeyAsPublicAddress(){
        let expectation = XCTestExpectation(description: "testaddpublicaddress")

        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chain: "PKEY", publicAddress: FIOSDK.sharedInstance().getPublicKey(), maxFee: 0) { (error) in
            guard error?.kind == FIOError.ErrorKind.Success else {
                expectation.fulfill()
                return
            }
            FIOSDK.sharedInstance().getPublicAddress(fioAddress: self.requestorFioName, tokenCode: "PKEY", completion: { (response, error) in
                XCTAssert((error.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error.localizedDescription)")
                expectation.fulfill()
            })
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
        self.alternativeSDKConfig()
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "BTC", publicAddress: fromPubAdd, maxFee: 0) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            expectationAddPubAddA.fulfill()
            self.defaultSDKConfig()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "BTC", publicAddress: toPubAdd, maxFee: 0) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                expectationAddPubAddB.fulfill()
                FIOSDK.sharedInstance().requestFunds(payer: from, payee: to, payeePublicAddress: toPubAdd, amount: 1.0, tokenCode: "BTC", metadata: metadata, maxFee: 0) { (response, error) in
                    if error?.kind == .Success {
                        expectationReqFunds.fulfill()
                        self.alternativeSDKConfig()
                        FIOSDK.sharedInstance().getPendingFioRequests(fioPublicKey: FIOSDK.sharedInstance().getPublicKey()) { (data, error) in
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
    
    func testGetFioNamesWithUnvalidAddressShouldRespondWithNotFound(){
        let expectation = XCTestExpectation(description: "testgetfionames")
        FIOSDK.sharedInstance().getFioNames(fioPublicKey: "NOT VALID ADDRESS") { (data, error) in
            XCTAssert(error?.kind == FIOError.ErrorKind.Failure, "Should have failed")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    func testGetFIONameDetailsWithGoodNameShouldSucceed() {
        let expectation = XCTestExpectation(description: "testGetFIONameDetailsWithGoodNameShouldSucceed")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().getFIONameDetails(self.requesteeFioName) { (response, error) in
            XCTAssert(error.kind == .Success, "getPublicAddress error")
            XCTAssertNotNil(response, "getPublicAddress error")
            
            if error.kind != .Success {
                expectation.fulfill()
            }
            else {
                XCTAssert(response?.address == self.requesteeFioName, "Wrong fio address")
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
            XCTAssert(response == nil || error.kind == .Failure, "Should've failed but succeeded")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    /// Tests the getPublicAddress method on FIOSDK using constant values ->
    /// fioAddress: self.requesteeFioName, tokenCode: "BTC"
    func testGetPublicAddress(){
        let expectation = XCTestExpectation(description: "testgetpublicaddress")
        self.defaultSDKConfig()
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
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: requesteeFioName, tokenCode: "NOTVALID") { (response, error) in
            XCTAssert(error.kind == .Failure, "should've failed")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    //THere is something with the ordering after register fio name that is not right, maybe my ordering is not right
    func testGetTokenPublicAddressWithValidPubAddressShouldSucceed() {
        let expectation = XCTestExpectation(description: "testGetTokenPublicAddressWithValidPubAddressShouldSucceed")
        
        let timestamp = NSDate().timeIntervalSince1970
        let tokenPubAdd = "smp\(Int(timestamp.rounded()))"
        let fioName = "fio\(Int(timestamp.rounded())):brd"
        
        
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 2, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().registerFioAddress(fioName, maxFee: 2 ) { (response, error) in
                    guard error?.kind == .Success else {
                        XCTFail("User not registered")
                        expectation.fulfill()
                        return
                    }
                    FIOSDK.sharedInstance().getPublicAddress(fioAddress: fioName, tokenCode: "FIO") { (response, error) in
                        guard error.kind == .Success, let fioPubAddress = response?.publicAddress else {
                            XCTFail("Public address not found")
                            expectation.fulfill()
                            return
                        }
                        FIOSDK.sharedInstance().getTokenPublicAddress(forToken: "BTC", withFIOPublicAddress: fioPubAddress) { (response, error) in
                            XCTAssert(error.kind == .Success, "getTokenPublicAddress failed")
                            XCTAssertNotNil(response)
                            expectation.fulfill()
                        }
                    }
                }
            }
            else {
                XCTFail("Failed to call requestFunds prior to registering domain requests")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }    
    
    func testGetTokenPublicAddressWithInvalidTokenShouldFail() {
        let expectation = XCTestExpectation(description: "testGetTokenPublicAddressWithInvalidTokenShouldFail")
        
        let timestamp = NSDate().timeIntervalSince1970
        let tokenPubAdd = "smp\(Int(timestamp.rounded()))"
        
        FIOSDK.sharedInstance().getTokenPublicAddress(forToken: "NOTVALIDTOKEN", withFIOPublicAddress: tokenPubAdd, onCompletion: { (response, error) in
            XCTAssert(response == nil, "should've failed")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRequestFundsWithGeneratedAccountShouldSucceed(){
        let expectation = XCTestExpectation(description: "testRequestFundsWithGeneratedAccountShouldSucceed")
        let metadata = RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
        
        FIOSDK.sharedInstance().requestFunds(payer: self.requestorFioName, payee: self.requesteeFioName, payeePublicAddress: self.requesteeAddress, amount: 1.0, tokenCode: "DAI", metadata: metadata, maxFee: 0) { (response, error) in
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
        self.alternativeSDKConfig()
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "BTC", publicAddress: fromPubAdd, maxFee: 0) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            self.defaultSDKConfig()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "BTC", publicAddress: toPubAdd, maxFee: 0) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
        
                FIOSDK.sharedInstance().requestFunds(payer: from, payee: to, payeePublicAddress: toPubAdd, amount: 1.0, tokenCode: "BTC", metadata: metadata, maxFee: 0) { (response, error) in
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
        self.alternativeSDKConfig()
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "BTC", publicAddress: fromPubAdd, maxFee: 0) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            self.defaultSDKConfig()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "BTC", publicAddress: toPubAdd, maxFee: 0) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                
                //requestor is sender, requestee is receiver
                FIOSDK.sharedInstance().requestFunds(payer: from, payee: to, payeePublicAddress: toPubAdd, amount: amount, tokenCode: "BTC", metadata: RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil), maxFee: 0) { (response, error) in
                    XCTAssert(error?.kind == .Success && response != nil, "testRejectFundsRequest Couldn't create mock request")
                    
                    if let response = response {
                        self.alternativeSDKConfig()
                        FIOSDK.sharedInstance().rejectFundsRequest(fundsRequestId: String(response.fundsRequestId), maxFee: 0, completion: { (response, error) in
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
        self.alternativeSDKConfig()
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "ETH", publicAddress: fromPubAdd, maxFee: 0) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            self.defaultSDKConfig()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "ETH", publicAddress: toPubAdd, maxFee: 0) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                FIOSDK.sharedInstance().requestFunds(payer: from, payee: to, payeePublicAddress: toPubAdd, amount: amount, tokenCode: "BTC", metadata: RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil), maxFee: 0) { (response, error) in
                    XCTAssert(error?.kind == .Success && response != nil, "testGetSentRequests Couldn't create mock request")
                    expRequestFunds.fulfill()
                    guard let fundsRequestId = response?.fundsRequestId else {
                        expGetSentRequest.fulfill()
                        expRejectRequest.fulfill()
                        return
                    }
                    FIOSDK.sharedInstance().getSentFioRequests(fioPublicKey: FIOSDK.sharedInstance().getPublicKey(), completion: { (response, error) in
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
                        self.alternativeSDKConfig()
                        FIOSDK.sharedInstance().rejectFundsRequest(fundsRequestId: fundsRequestId, maxFee: 0, completion: { (response, error) in
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
    
    //MARK: Test Registration
    
    func testRegisterFIONameWithNewValueShouldRegister() {
        let timestamp = NSDate().timeIntervalSince1970
        let fioName = "sha\(Int(timestamp.rounded())):brd"
        let expectation = XCTestExpectation(description: "testRegisterFIONameWithNewValueShouldRegister")

        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 2, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().registerFioAddress(fioName, maxFee: 2, onCompletion: {response, error in ()
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call requestFunds prior to registering domain requests")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRegisterFIONameWithAlreadyRegisteredValueShouldFail() {
        let timestamp = NSDate().timeIntervalSince1970
        let fioName = "sha\(Int(timestamp.rounded())):brd"
        let expectation = XCTestExpectation(description: "testRegisterFIONameWithAlreadyRegisteredValueShouldFail")

        
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 2, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().registerFioAddress(fioName, maxFee: 2, onCompletion: { response, error in ()
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
                    FIOSDK.sharedInstance().registerFioAddress(fioName, maxFee: 2, onCompletion: { response, error in ()
                        XCTAssert((error?.kind == FIOError.ErrorKind.Failure), "registerFIOName NOT SUCCESSFUL")
                        expectation.fulfill()
                    })
                })
            }
            else {
                XCTFail("Failed to call requestFunds prior to registering domain requests")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRegisterFIONameWithFIOTokenAddressShouldNotAddAddress() {
        let timestamp = NSDate().timeIntervalSince1970
        let fioName = "sha\(Int(timestamp.rounded())):brd"
        let expectation = XCTestExpectation(description: "testRegisterFIONameWithAlreadyRegisteredValueShouldFail")
        
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 2, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().registerFioAddress(fioName, maxFee:2, onCompletion: { response, error in ()
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
                    FIOSDK.sharedInstance().getFioNames(fioPublicKey: "ignoreme", completion: { (response, error) in
                        XCTAssert((error?.kind == FIOError.ErrorKind.Failure), "Added the address it shouldn´t be added")
                        expectation.fulfill()
                    })
                })
            }
            else {
                XCTFail("Failed to call requestFunds prior to registering domain requests")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRenewFIODomainWithNewValueShouldRenewNoWallet() {
        let timestamp = NSDate().timeIntervalSince1970
        let domain = "test\(Int(timestamp.rounded()))"
        let expectation = XCTestExpectation(description: "testRenewFIODomainWithNewValueShouldRenewNoWallet")
        self.defaultSDKConfig()
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: 30.0, onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: 30.0, onCompletion: { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "renewFIODomain NOT SUCCESSFUL")
                    XCTAssertNotNil(response)
                    XCTAssert(response?.status != "")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call registerFioDomain prior to renew domain requests")
                expectation.fulfill()
            }
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIODomainWithInvalidValueShouldNotRenewNoWallet() {
        let domain = "#&*("
        let expectation = XCTestExpectation(description: "testRenewFIODomainWithInvalidValueShouldNotRenewNoWallet")
        
        FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: 30.0, onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"renewFIODomain Should not renew invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIODomainWithNewValueShouldRenew() {
        let timestamp = NSDate().timeIntervalSince1970
        let domain = "test\(Int(timestamp.rounded()))"
        let expectation = XCTestExpectation(description: "testRenewFIODomainWithNewValueShouldRenew")
        let walletFioAddress = "test:edge"
        self.defaultSDKConfig()
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: 30.0, onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: 30.0, walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "renewFIODomain NOT SUCCESSFUL")
                    XCTAssertNotNil(response)
                    XCTAssert(response?.status != "")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call registerFioDomain prior to renew domain requests")
                expectation.fulfill()
            }
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIODomainWithInvalidValueShouldNotRenew() {
        let domain = "#&*("
        let expectation = XCTestExpectation(description: "testRenewFIODomainWithInvalidValueShouldNotRenew")
        let walletFioAddress = "test:edge"
        
        FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: 30.0,walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"renewFIODomain Should not renew invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIODomainWithNewValueShouldRegister() {
        let timestamp = NSDate().timeIntervalSince1970
        let domain = "test\(Int(timestamp.rounded()))"
        let expectation = XCTestExpectation(description: "testRegisterFIODomainWithNewValueShouldRegister")
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 30, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: 30.0, walletFioAddress:"", onCompletion: { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIODomain NOT SUCCESSFUL")
                    XCTAssertNotNil(response)
                    XCTAssert(response?.status != "")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call requestFunds prior to registering domain requests")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIODomainWithInvalidValueShouldNotRegister() {
        let domain = "#&*("
        let expectation = XCTestExpectation(description: "testRegisterFIODomainWithNewValueShouldRegister")
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: 30.0, walletFioAddress:"", onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIODomain Should not register invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIODomainWithNewValueShouldRegisterNoWallet() {
        let timestamp = NSDate().timeIntervalSince1970
        let domain = "test\(Int(timestamp.rounded()))"
        let expectation = XCTestExpectation(description: "testRegisterFIODomainWithNewValueShouldRegister")
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 30, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: 30.0, onCompletion: { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIODomain NOT SUCCESSFUL")
                    XCTAssertNotNil(response)
                    XCTAssert(response?.status != "")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call requestFunds prior to registering domain requests")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIODomainWithInvalidValueShouldNotRegisterNoWallet() {
        let domain = "#&*("
        let expectation = XCTestExpectation(description: "testRegisterFIODomainWithNewValueShouldRegister")
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: 30.0, onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIODomain Should not register invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIOAddressWithNewValueShouldRegister() {
        let timestamp = NSDate().timeIntervalSince1970
        let address = "test\(Int(timestamp.rounded())):brd"
        let expectation = XCTestExpectation(description: "testRegisterFIOAddressWithNewValueShouldRegister")
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        let walletFioAddress = "test:edge"
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 2, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().registerFioAddress(address, maxFee: 2, walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOAddress NOT SUCCESSFUL")
                    XCTAssertNotNil(response)
                    XCTAssert(response?.status != "")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call requestFunds prior to registering address requests")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIOAddressWithInvalidValueShouldNotRegister() {
        let address = "#&*("
        let expectation = XCTestExpectation(description: "testRegisterFIOAddressWithInvalidValueShouldNotRegister")
        let walletFioAddress = "test:edge"
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: 2, walletFioAddress: walletFioAddress , onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIOAddress Should not register invalid address: %@", address))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIOAddressWithNewValueShouldRegisterNoWallet() {
        let timestamp = NSDate().timeIntervalSince1970
        let address = "test\(Int(timestamp.rounded())):brd"
        let expectation = XCTestExpectation(description: "testRegisterFIOAddressWithNewValueShouldRegister")
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requesteeFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 2, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().registerFioAddress(address, maxFee: 2, onCompletion: { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOAddress NOT SUCCESSFUL")
                    XCTAssertNotNil(response)
                    XCTAssert(response?.status != "")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call requestFunds prior to registering address requests")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIOAddressWithInvalidValueShouldNotRegisterNoWallet() {
        let address = "#&*("
        let expectation = XCTestExpectation(description: "testRegisterFIOAddressWithInvalidValueShouldNotRegister")
        
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: 2, onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIOAddress Should not register invalid address: %@", address))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    //MARK: -
    
    func testRecordSendWithFakeDataShouldSucceeded() {
        let expectation = XCTestExpectation(description: "testRecordSendWithFakeDataShouldSucceeded")
        
        let amount = Float.random(in: 1111.0...4444)
        let from = self.requestorFioName
        let to = self.requesteeFioName
        let timestamp = NSDate().timeIntervalSince1970
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        let obtID = "0xf6eaddd3851923f6f9653838d3021c02ab123a4a6e4485e83f5063b3711e000b"
        
        self.alternativeSDKConfig()
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "VIT", publicAddress: fromPubAdd, maxFee: 0) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            guard error?.kind == FIOError.ErrorKind.Success else {
                expectation.fulfill()
                return
            }
            self.defaultSDKConfig()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "VIT", publicAddress: toPubAdd, maxFee: 0) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                guard error?.kind == FIOError.ErrorKind.Success else {
                    expectation.fulfill()
                    return
                }
                
                self.alternativeSDKConfig()
                FIOSDK.sharedInstance().recordSend(payerFIOAddress: from, payeeFIOAddress: to, payerPublicAddress: fromPubAdd, payeePublicAddress: toPubAdd, amount: amount, tokenCode: "VIT", obtID: obtID, memo: "Record Send Unit Test", maxFee: 0) { (response, error) in
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

        self.alternativeSDKConfig()
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chain: "VIT", publicAddress: fromPubAdd, maxFee: 0) { (error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            guard error?.kind == FIOError.ErrorKind.Success else {
                expectation.fulfill()
                return
            }
            self.defaultSDKConfig()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chain: "VIT", publicAddress: toPubAdd, maxFee: 0) { (error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
                guard error?.kind == FIOError.ErrorKind.Success else {
                    expectation.fulfill()
                    return
                }
                
                self.alternativeSDKConfig()
                FIOSDK.sharedInstance().recordSendAutoResolvingWith(payeeFIOAddress: to, andPayerPublicAddress: fromPubAdd, amountSent: amount, forTokenCode: "VIT", obtID: obtID, memo: "Record send unit test", maxFee: 0) { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "recordSend NOT SUCCESSFUL")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    func testGetFIOPublicAddressWithKeysShouldExist() {
        try? FIOSDK.wipePrivPubKeys()
        let keyPair = FIOSDK.privatePubKeyPair(forMnemonic: defaultMnemonic)
        let fioPublicAddress = FIOSDK.sharedInstance(accountName: defaultAccount, privateKey: keyPair.privateKey, publicKey: keyPair.publicKey,systemPrivateKey:keyPair.privateKey, systemPublicKey:keyPair.publicKey, url: defaultServer).getFIOPublicAddress()
        let expected = "ltwagbt4qpuk"
        let privateKeyExpected = keyPair.privateKey
        let publicKeyExpected = keyPair.publicKey
        XCTAssertEqual(expectedDefaultPrivateKey, privateKeyExpected)
        XCTAssertEqual(expectedDefaultPublicKey, publicKeyExpected)
        XCTAssertEqual(fioPublicAddress, expected)
    }
    
    func testGetFIOPublicAddressWithoutKeysShouldBeEmpty() {
        let fioPublicAddress = FIOSDK.sharedInstance(accountName: defaultAccount, privateKey: "", publicKey: "",systemPrivateKey:"", systemPublicKey:"", url: defaultServer).getFIOPublicAddress()
        let expected = ""
        XCTAssertEqual(fioPublicAddress, expected)
    }
    
    func testGetFIOBalanceWithProperSetupShouldReturnValue() {
        let expectation = XCTestExpectation(description: "testGetFIOBalanceWithProperSetupShouldReturnValue")
        let fioPubAddress = FIOSDK.sharedInstance().publicKey;
        
        FIOSDK.sharedInstance().getFIOBalance(fioPublicAddress: fioPubAddress) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "Get FIO Balance NOT SUCCESSFUL: \(error.localizedDescription )")
            XCTAssert((response?.displayBalance() != nil ), "Get FIO Balance NOT SUCCESSFUL: \(error.localizedDescription )")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testTransferTokensWithGoodAccountsShouldBeSuccessful() {
        let expectation = XCTestExpectation(description: "testTransferTokensWithGoodAccountsShouldBeSuccessful")
        
        self.defaultSDKConfig()
        let payeePublicKey = FIOSDK.sharedInstance().getPublicKey()
        let fioSDK = FIOSDK.sharedInstance(accountName: fioAccount, privateKey: fioPrivateKey, publicKey: fioPublicKey,systemPrivateKey:fioPrivateKey, systemPublicKey:fioPublicKey, url: defaultServer)
        let payerPublicKey = fioSDK.getPublicKey()
        let amount: Double = 1.0
        let maxFee = 0.25
        let walletFioAddress = "test:edge"
        
        fioSDK.transferFIOTokens(payeePublicKey: payeePublicKey, amount: amount, maxFee: maxFee , walletFioAddress: walletFioAddress) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
            XCTAssertNotNil(response?.feeCollected)
            //Transfer back
            self.defaultSDKConfig()
            sleep(60)
            FIOSDK.sharedInstance().transferFIOTokens(payeePublicKey: payerPublicKey, amount: amount, maxFee: maxFee ,walletFioAddress: walletFioAddress) { (response, error) in
                XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testTransferTokensWithGoodAccountsShouldBeSuccessfulNoWallet() {
        let expectation = XCTestExpectation(description: "testTransferTokensWithGoodAccountsShouldBeSuccessfulNoWallet")
        
        self.defaultSDKConfig()
        let payeePublicKey = FIOSDK.sharedInstance().getPublicKey()
        let fioSDK = FIOSDK.sharedInstance(accountName: fioAccount, privateKey: fioPrivateKey, publicKey: fioPublicKey,systemPrivateKey:fioPrivateKey, systemPublicKey:fioPublicKey, url: defaultServer)
        let payerPublicKey = fioSDK.getPublicKey()
        let amount: Double = 1.0
        let maxFee = 0.25
        
        fioSDK.transferFIOTokens(payeePublicKey: payeePublicKey, amount: amount, maxFee: maxFee) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
            XCTAssertNotNil(response?.feeCollected)
            //Transfer back
            self.defaultSDKConfig()
            sleep(60)
            FIOSDK.sharedInstance().transferFIOTokens(payeePublicKey: payerPublicKey, amount: amount, maxFee: maxFee) { (response, error) in
                XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    
    /*
    func testTransferTokensWithInsufficientAmountShouldNotBeSuccessful() {
        let expectation = XCTestExpectation(description: "testTransferTokensWithInsufficientAmountShouldNotBeSuccessful")
        
        let fioSDK = FIOSDK.sharedInstance(accountName: fioAccount, privateKey: fioPrivateKey, publicKey: fioPublicKey,systemPrivateKey:fioPrivateKey, systemPublicKey:fioPublicKey, url: dev1Server)
        let payeePublicAddress = "htjonrkf1lgs"
        let payerPublicAddress = fioAccount
        let amount: Double = 900000000.0
        let maxFee = 0.25
        
        fioSDK.transferFIOTokens(payeePublicKey: payeePublicAddress, amount: amount, maxFee: maxFee) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Failure), "transfer failed: \(error.localizedDescription )")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
 */
    
    func testPrivatePubKeyPairMultipleGenerateShouldWork() {
        try? FIOSDK.wipePrivPubKeys()
        var keys = FIOSDK.privatePubKeyPair(forMnemonic: "hotel royal gasp strike hurdle expect dish surface era observe casual pond")
        XCTAssert(!keys.privateKey.isEmpty && !keys.publicKey.isEmpty)
        keys = FIOSDK.privatePubKeyPair(forMnemonic: "mirror bid phrase scheme wing valid fringe insane august wasp join toast")
        XCTAssert(!keys.privateKey.isEmpty && !keys.publicKey.isEmpty)
        keys = FIOSDK.privatePubKeyPair(forMnemonic: defaultMnemonic)
        XCTAssert(!keys.privateKey.isEmpty && !keys.publicKey.isEmpty)
    }
    
    func testRegisterFIONameOnBehalfOfUserShouldReturnSucess() {
        let expectation = XCTestExpectation(description: "registerFIONameOnBehalfOfUserShouldReturnSucess")
        
        let timestamp = NSDate().timeIntervalSince1970
        let fioName = "test\(Int(timestamp.rounded())):brd"
        let publicKey = "EOS8PRe4WRZJj5mkem6qVGKyvNFgPsNnjNN6kPhh6EaCpzCVin5Jj"
        
        FIOSDK.sharedInstance().registerFIONameOnBehalfOfUser(fioName: fioName, publicKey: publicKey) { (response, error) in
            XCTAssert(response != nil, "Something went wrong")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    //MARK: Get Fee tests
    
    func testGetFeeWithEmptyAddressShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeWithEmptyAddressShouldReturnFee")
        
        FIOSDK.sharedInstance().getFee(endPoint: FIOSDK.Params.FeeEndpoint.transferTokensPubKey, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetFeeWithNonEmptyAddressShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeWithNonEmptyAddressShouldReturnFee")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().getFee(endPoint: FIOSDK.Params.FeeEndpoint.addPubAddress, fioAddress: self.requesteeFioName, onCompletion: { (response, error) in
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee >= 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetFeeWithNonEmptyWrongAddressShouldNotReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeWithNonEmptyWrongAddressShouldNotReturnFee")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().getFee(endPoint: FIOSDK.Params.FeeEndpoint.addPubAddress, fioAddress: "NOTVALID", onCompletion: { (response, error) in
            XCTAssert(error.kind == .Failure, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetAbi() {
        let expectation = XCTestExpectation(description: "testGetABI")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().getABI(accountName:"fio.system", onCompletion: { (response, error) in
            print("**")
            print (response)
            XCTAssert(error.kind == .Success, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    func testRegisterFioAddress() {
        let expectation = XCTestExpectation(description: "testGetTokenPublicAddressWithValidPubAddressShouldSucceed")
        
        let timestamp = NSDate().timeIntervalSince1970
        //let tokenPubAdd = "smp\(Int(timestamp.rounded()))"
        let fioName = "fio\(Int(timestamp.rounded())):brd"
        
        self.defaultSDKConfig()
        
        FIOSDK.sharedInstance().registerFioAddress(fioName,  maxFee: 2) { (response, error) in
            guard error?.kind == .Success else {
                XCTFail("User not registered")
                expectation.fulfill()
                return
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    /*
    func testRegisterFIONameOnBehalfOfUserShouldReturnSucess() {
        let expectation = XCTestExpectation(description: "registerFIONameOnBehalfOfUserShouldReturnSucess")
        
        let timestamp = NSDate().timeIntervalSince1970
        let fioName = "test\(Int(timestamp.rounded())):brd"
        let publicKey = "EOS8PRe4WRZJj5mkem6qVGKyvNFgPsNnjNN6kPhh6EaCpzCVin5Jj"
        
        FIOSDK.sharedInstance().registerFIONameOnBehalfOfUser(fioName: fioName, publicKey: publicKey, publicReceiveAddresses: [:]) { (response, error) in
            XCTAssert(response != nil, "Something went wrong")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    */
    
}
