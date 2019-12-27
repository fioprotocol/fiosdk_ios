//
//  FIOSDKTests.swift
//  FIOSDKTests
//
//  Created by shawn arney on 10/19/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import XCTest
@testable import FIOSDK

private let useDefaultServer = false //want a custom server, set to true and then set the DEFAULT_SERVER to your ip/url
private let useAlternateServer = true

private let DEFAULT_SERVER = "http://dev3.fio.dev:8889/v1"
private let MOCK_DEFAULT_SERVER = "http://mock.dapix.io/mockd/DEV3/register_fio_name"

private let ALTERNATE_SERVER = "http://dev2.fio.dev:8889/v1"
private let MOCK_ALTERNATE_SERVER = "http://mock.dapix.io/mockd/DEV2/register_fio_name"

class FIOSDKTests: XCTestCase {
    
    private let privateKey:String = "5KDQzVMaD1iUdYDrA2PNK3qEP7zNbUf8D41ZVKqGzZ117PdM5Ap"
    private let publicKey:String = "FIO6D6gSipBmP1KW9SMB5r4ELjooaogFt77gEs25V9TU9FrxKVeFb"
    

    // stage 1 server: 18.223.14.244
    private let TIMEOUT:Double = 240.0
    
    //MARK: Constants
    private let defaultServer   = (useDefaultServer ? DEFAULT_SERVER : ALTERNATE_SERVER)
    private let defaultMnemonic = "valley alien library bread worry brother bundle hammer loyal barely dune brave"
    private let expectedDefaultPrivateKey = "5Kbb37EAqQgZ9vWUHoPiC2uXYhyGSFNbL6oiDp24Ea1ADxV1qnu"
    private let expectedDefaultPublicKey = "FIO5kJKNHwctcfUM5XZyiWSqSTM5HTzznJP9F3ZdbhaQAHEVq575o"
    private let mockUrl = (useDefaultServer ? MOCK_DEFAULT_SERVER : MOCK_ALTERNATE_SERVER)
    
    private let fioPrivateKey = "5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF"
    private let fioPublicKey  = "FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82"
    
    private let fioPrivateKeyAlternative = "5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
    private let fioPublicKeyAlternative  = "FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"
    
    //MARK: test variables
    private var requesteeFioName: String = ""
    private let requesteeAddress: String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
    private var requestorFioName: String = ""
    private let requestorAddress: String = "0x3A2522321656285661Df2012a3A05bEF84C8B1ed"
    
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
        _ = FIOSDK.sharedInstance(privateKey: keyPair.privateKey, publicKey: keyPair.publicKey, url: defaultServer, mockUrl: mockUrl)
    }
    
    private func alternativeSDKConfig() {
        try? FIOSDK.wipePrivPubKeys()
        let keyPair = FIOSDK.privatePubKeyPair(forMnemonic: "gallery hero weekend notable inherit chuckle village spread business scrap surprise finger")
        _ = FIOSDK.sharedInstance(privateKey: keyPair.privateKey, publicKey: keyPair.publicKey, url: defaultServer, mockUrl: mockUrl)
    }
    
    func registerDefaultUsers() {
        let timestamp = NSDate().timeIntervalSince1970
        requesteeFioName = "sha\(Int(timestamp.rounded())):brd"
        requestorFioName = "bar\(Int(timestamp.rounded())):brd"
        
        let expectation = XCTestExpectation(description: "testRegisterFIOName")
        
        print (FIOSDK.sharedInstance().getPublicKey())
        FIOSDK.sharedInstance().registerFIONameOnBehalfOfUser(fioName: requesteeFioName, publicKey: FIOSDK.sharedInstance().getPublicKey(), onCompletion: { response, error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
             print ("REQUESTEE:")
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
                        print ("REQUESTOR:")
                        print(self.requestorFioName)
                        
                        FIOSDK.sharedInstance().requestFunds(payer: "faucet:fio", payee: self.requestorFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 9, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
                            if error?.kind == .Success {
                                sleep(60)
                                
                                self.defaultSDKConfig()
                                expectation.fulfill()
                            }
                            else {
                                print ("failed to request funds - second user")
                                expectation.fulfill()
                            }
                        }
                    })
                }
                else {
                    print ("failed to request funds - first user")
                    expectation.fulfill()
                }
            }
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    //MARK: -
    
    func testPublicKeyFromStringShouldGeneratePublicKey() {
        try? FIOSDK.wipePrivPubKeys()
        let mnemonic = "gallery hero weekend notable inherit chuckle village spread business scrap surprise finger"
        let keyPair = FIOSDK.privatePubKeyPair(forMnemonic: mnemonic)
        let privKey = try? PrivateKey(enclave: .Secp256k1, mnemonicString: mnemonic)
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
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "12-:brd"), "should be invalid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "brd"), "should be valid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "brd-brd"), "should be valid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "brd-"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "-brd"), "should be invalid")
        
        var domainWith61Chars = ""
        (0...61).forEach { _ in domainWith61Chars.append("1") }
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: domainWith61Chars), "should be valid")
        
        var addressWith62Chars = ""
        (0...62).forEach { _ in addressWith62Chars.append("1") }
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: addressWith62Chars), "should be invalid")
        
    }
    
    func testIsAvailableWithAlreadyTakenNameShouldNotBeAvailable(){
        let expectation = XCTestExpectation(description: "testIsAvailableNN")
        
        FIOSDK.sharedInstance().isAvailable(fioName:self.requestorFioName) { (isAvailable, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testIsAvailable NOT SUCCESSFUL")
            
            print (self.requestorFioName)
            print (isAvailable)
            XCTAssertFalse(isAvailable, "testIsAvailable NOT SUCCESSFUL")
                
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testIsAvailableWithNewNameShouldBeAvailable(){
        let expectation = XCTestExpectation(description: "testIsAvailable")
        let timestamp = NSDate().timeIntervalSince1970
        let fioAddress = "fioaddress\(Int(timestamp.rounded())):brd"
        FIOSDK.sharedInstance().isAvailable(fioName:fioAddress) { (isAvailable, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testIsAvailable NOT SUCCESSFUL")
            
            print (fioAddress)
            print (isAvailable)
            
            XCTAssert(isAvailable, "testIsAvailable NOT SUCCESSFUL")
            
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
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, tokenCode: "ETH", publicAddress: pubAdd, maxFee: 0) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testAddPublicAddressWithFIOTokenShouldFail(){
        let expectation = XCTestExpectation(description: "testaddpublicaddress")
        let timestamp = NSDate().timeIntervalSince1970
        let pubAdd = "pubAdd\(Int(timestamp.rounded()))"
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, tokenCode: "FIO", publicAddress: pubAdd, maxFee: 0) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), "testAddPublicAddressWithFIOTokenShouldFail tried to add FIO Token address.")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testAddPublicKeyAsPublicAddress(){
        let expectation = XCTestExpectation(description: "testaddpublicaddress")

        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, tokenCode: "PKEY", publicAddress: FIOSDK.sharedInstance().getPublicKey(), maxFee: 0) { (response, error) in
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
            
            if (response != nil) {
                XCTAssertFalse(response!.publicAddress.isEmpty, "testgetpublicadddress not succesful no public address was found")
            }
            
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
                        FIOSDK.sharedInstance().getPublicAddress(fioPublicKey: fioPubAddress, tokenCode: "BTC") { (response, error) in
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
        
        FIOSDK.sharedInstance().getPublicAddress(fioPublicKey: tokenPubAdd, tokenCode: "INVALIDTOKEN", onCompletion: { (response, error) in
            XCTAssert(response == nil, "should've failed")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    /// shawn - this call works for new request funds flow
    func testRequestFunds() {
        let expectationReqFunds = XCTestExpectation(description: "testRequestFunds")
        
        self.defaultSDKConfig()
        let metadata = RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
        let timestamp = NSDate().timeIntervalSince1970
        let payee = self.requesteeFioName
        let payer = self.requestorFioName
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        
        FIOSDK.sharedInstance().requestFunds(payer: payer, payee: payee, payeePublicAddress: toPubAdd, amount: 1.0, tokenCode: "BTC", metadata: metadata, maxFee: 3000000000, walletFioAddress: "") { (response, error) in
                if error?.kind == .Success {
                    expectationReqFunds.fulfill()
                }
                else {
                    XCTFail("Failed to call requestFunds")
                    expectationReqFunds.fulfill()
                }
        }
        
        wait(for: [expectationReqFunds], timeout: TIMEOUT*2)
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
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, tokenCode: "BTC", publicAddress: fromPubAdd, maxFee: 2 * SUFUtils.SUFUnit) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            self.defaultSDKConfig()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, tokenCode: "BTC", publicAddress: toPubAdd, maxFee: 0) { (response, error) in
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
    
    
    func testAddPublicAddresses(){
        let expectation = XCTestExpectation(description: "testAddPublicAddresses")
        let to = self.requesteeFioName
        let timestamp = NSDate().timeIntervalSince1970
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        self.defaultSDKConfig()
        
        let publicAddresses = PublicAddress(tokenCode: "BTC", publicAddress: fromPubAdd)
        FIOSDK.sharedInstance().addPublicAddresses(fioAddress: to, publicAddresses: [publicAddresses], maxFee: 2 * SUFUtils.SUFUnit) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddresses NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    /// Test for reject_funds_request
    func testRejectFundsRequest(){
        let expectation = XCTestExpectation(description: "testRejectFundsRequest")
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        self.alternativeSDKConfig()
        //requestor is sender, requestee is receiver
        FIOSDK.sharedInstance().requestFunds(payer: self.requesteeFioName, payee: self.requestorFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 9, tokenCode: "FIO", metadata: metadata, maxFee: 0) { (response, error) in
            XCTAssert(error?.kind == .Success && response != nil, "testRejectFundsRequest Couldn't create mock request")
            if let response = response {
                self.defaultSDKConfig()
                FIOSDK.sharedInstance().rejectFundsRequest(fioRequestId: response.fioRequestId, maxFee: 0, completion: { (response, error) in
                    XCTAssert(error.kind == .Success, "testRejectFundsRequest couldn't reject request")
                    expectation.fulfill()
                })
            }
            else {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    /// Test for get_sent_fio_requests
     func testGetSentAndPendingRequests(){
         let expRequestFunds = XCTestExpectation(description: "test getSentRequests request funds")
         let expGetSentRequest = XCTestExpectation(description: "test getSentRequests get")
         let expGetPendingRequest = XCTestExpectation(description: "test getPendingRequests get")
         
         self.defaultSDKConfig()
         let metadata = RequestFundsRequest.MetaData(memo: "Invoice1234", hash: nil, offlineUrl: nil)
         let timestamp = NSDate().timeIntervalSince1970
         let payee = self.requesteeFioName
         let payer = self.requestorFioName
         let fromPubAdd = "from\(Int(timestamp.rounded()))"
         let toPubAdd = "to\(Int(timestamp.rounded()))"
         
         FIOSDK.sharedInstance().requestFunds(payer: payer, payee: payee, payeePublicAddress: toPubAdd, amount: 1.0, tokenCode: "BTC", metadata: metadata, maxFee: 3000000000, walletFioAddress: "") { (response, error) in
                 if error?.kind == .Success {
                     expRequestFunds.fulfill()
                     
                     FIOSDK.sharedInstance().getSentFioRequests() { (sentRecords, sentError) in
                         
                         XCTAssert(sentError.kind == .Success && sentRecords != nil, "Sent Request couldn't retreive request")
                         guard sentError.kind == .Success, sentRecords != nil else {
                            XCTFail("testGetSentAndPendingRequests Request should have sent fio requests")
                            expGetSentRequest.fulfill()
                            return
                         }

                         expGetSentRequest.fulfill()
                         
                         self.alternativeSDKConfig()
                         FIOSDK.sharedInstance().getPendingFioRequests { (pendRecords, pendError) in
                             
                             XCTAssert(pendError.kind == .Success && pendRecords != nil, "Pending Request couldn't retreive request")
                             guard pendError.kind == .Success, pendRecords != nil else {
                               XCTFail("testGetSentAndPendingRequests Request should have pending fio requests")
                               expGetPendingRequest.fulfill()
                               return
                             }
                             
                             expGetPendingRequest.fulfill()
                         }
                     }
                     
                 }
                 else {
                     XCTFail("Failed to call requestFunds for getSentRequests")
                     expRequestFunds.fulfill()
                     expGetSentRequest.fulfill()
                 }
         }

         wait(for: [expRequestFunds, expGetSentRequest,expGetPendingRequest], timeout: TIMEOUT*5)
     }
    
    func testGenerateAccountNameGeneratorWithProperValuesOutputCorrectResult() {
        let publicKey = "FIO6cDpi7vPnvRwMEdXtLnAmFwygaQ8CzD7vqKLBJ2GfgtHBQ4PPy"
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
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 2.0), onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
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
        
        FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
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
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(10)
                FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
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
        
        wait(for: [expectation], timeout: TIMEOUT * 2)
    }
    
    func testRenewFIODomainWithInvalidValueShouldNotRenew() {
        let domain = "#&*("
        let expectation = XCTestExpectation(description: "testRenewFIODomainWithInvalidValueShouldNotRenew")
        let walletFioAddress = "test:edge"
        
        FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
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
                FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), walletFioAddress:"", onCompletion: { (response, error) in
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
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), walletFioAddress:"", onCompletion: { (response, error) in
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
                FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
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
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIODomain Should not register invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIOAddressWithNewValueShouldRenew() {
        let timestamp = NSDate().timeIntervalSince1970
        let address = "test\(Int(timestamp.rounded())):brd"
        let expectation = XCTestExpectation(description: "testRenewFIOAddressWithNewValueShouldRenew")
        let walletFioAddress = "test:edge"
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().renewFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "renewFIOAddress NOT SUCCESSFUL")
                    XCTAssertNotNil(response)
                    XCTAssert(response?.status != "")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call registerFioAddress prior to renew address requests")
                expectation.fulfill()
            }
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIOAddressWithInvalidValueShouldNotRenew() {
        let address = "#&*("
        let expectation = XCTestExpectation(description: "testRenewFIOAddressWithInvalidValueShouldNotRenew")
        let walletFioAddress = "test:edge"
        
        FIOSDK.sharedInstance().renewFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"renewFIODomain Should not renew invalid address: %@", address))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIOAddressWithNewValueShouldRegisterNoWallet() {
        let timestamp = NSDate().timeIntervalSince1970
        let address = "test\(Int(timestamp.rounded())):brd"
        let expectation = XCTestExpectation(description: "testRenewFIOAddressWithNewValueShouldRegister")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().renewFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
                    XCTAssert((error?.kind == FIOError.ErrorKind.Success), "renewFIOAddress NOT SUCCESSFUL")
                    XCTAssertNotNil(response)
                    XCTAssert(response?.status != "")
                    expectation.fulfill()
                })
            }
            else {
                XCTFail("Failed to call registerFioAddress prior to renew address requests")
                expectation.fulfill()
            }
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIOAddressWithInvalidValueShouldNotRegisterNoWallet() {
        let address = "#&*("
        let expectation = XCTestExpectation(description: "testRenewFIOAddressWithInvalidValueShouldNotRegisterNoWallet")
        
        FIOSDK.sharedInstance().renewFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"renewFIODomain Should not renew invalid address: %@", address))
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
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), walletFioAddress: walletFioAddress , onCompletion: { (response, error) in
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
                FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
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
        
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 3.0), onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIOAddress Should not register invalid address: %@", address))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
   
    //MARK: -
    // broken here
    func testRecordSendWithFakeDataShouldSucceeded() {
        let expectation = XCTestExpectation(description: "testRecordSendWithFakeDataShouldSucceeded")
        
        let amount = 4.65
        let payee = self.requestorFioName
        let payor = self.requesteeFioName
        let timestamp = NSDate().timeIntervalSince1970
        let fromPubAdd = "from\(Int(timestamp.rounded()))"
        let toPubAdd = "to\(Int(timestamp.rounded()))"
        let obtID = "0xf6eaddd3851923f6f9653838d3021c02ab123a4a6e4485e83f5063b3711e000b"
        
        defaultSDKConfig()
        let metaData = RecordSendRequest.MetaData(memo: "", hash: "", offlineUrl: "")
        FIOSDK.sharedInstance().recordSend(payerFIOAddress: payee, payeeFIOAddress: payor, payerTokenPublicAddress: fromPubAdd, payeeTokenPublicAddress: toPubAdd, amount: amount, tokenCode: "VIT", obtId: obtID, maxFee: SUFUtils.amountToSUF(amount: 2.0), metaData: metaData) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "recordSend NOT SUCCESSFUL")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetFIOBalanceWithProperSetupShouldReturnValue() {
        let expectation = XCTestExpectation(description: "testGetFIOBalanceWithProperSetupShouldReturnValue")
        let fioPubAddress = FIOSDK.sharedInstance().publicKey;
        
        FIOSDK.sharedInstance().getFIOBalance(fioPublicKey: fioPubAddress) { (response, error) in
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
        let fioSDK = FIOSDK.sharedInstance(privateKey: fioPrivateKey, publicKey: fioPublicKey, url: defaultServer)
        let payerPublicKey = fioSDK.getPublicKey()
        let amount: Double = 1.0
        let walletFioAddress = "test:edge"
        
        fioSDK.transferFIOTokens(payeePublicKey: payeePublicKey, amount: SUFUtils.amountToSUF(amount: amount), maxFee: SUFUtils.amountToSUF(amount: 2.0), walletFioAddress: walletFioAddress) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
            XCTAssertNotNil(response?.feeCollected)
            //Transfer back
            self.defaultSDKConfig()
            sleep(60)
            FIOSDK.sharedInstance().transferFIOTokens(payeePublicKey: payerPublicKey, amount: SUFUtils.amountToSUF(amount: amount), maxFee: SUFUtils.amountToSUF(amount: 2.0), walletFioAddress: walletFioAddress) { (response, error) in
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
        let fioSDK = FIOSDK.sharedInstance(privateKey: fioPrivateKey, publicKey: fioPublicKey, url: defaultServer)
        let payerPublicKey = fioSDK.getPublicKey()
        let amount: Double = 1.0
        
        fioSDK.transferFIOTokens(payeePublicKey: payeePublicKey, amount: SUFUtils.amountToSUF(amount: amount), maxFee: SUFUtils.amountToSUF(amount: 2.0)) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
            XCTAssertNotNil(response?.feeCollected)
            //Transfer back
            self.defaultSDKConfig()
            sleep(60)
            FIOSDK.sharedInstance().transferFIOTokens(payeePublicKey: payerPublicKey, amount: SUFUtils.amountToSUF(amount: amount), maxFee: SUFUtils.amountToSUF(amount: 2.0)) { (response, error) in
                XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
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
        let publicKey = "FIO8PRe4WRZJj5mkem6qVGKyvNFgPsNnjNN6kPhh6EaCpzCVin5Jj"
        
        FIOSDK.sharedInstance().registerFIONameOnBehalfOfUser(fioName: fioName, publicKey: publicKey) { (response, error) in
            XCTAssert(response != nil, "Something went wrong")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    //MARK: Get Fee tests
    
    func testGetFeeShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeShouldReturnFee")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().getFee(endPoint: FIOSDK.Params.FeeEndpoint.transferTokensUsingPublicKey, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForRegisterFioDomainShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForRegisterFioDomainShouldReturnFee")
        
        FIOSDK.sharedInstance().getFee(endPoint: .registerFIODomain, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForRegisterFioAddressShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForRegisterFioAddressShouldReturnFee")
        FIOSDK.sharedInstance().getFee(endPoint: .registerFIOAddress, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForTransferTokensPubKeyShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForTransferTokensPubKeyShouldReturnFee")
        FIOSDK.sharedInstance().getFee(endPoint: .transferTokensUsingPublicKey, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForTransferTokensFioAddressShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForTransferTokensFioAddressShouldReturnFee")
        FIOSDK.sharedInstance().getFee(endPoint: .transferTokensUsingFIOAddress, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForAddPublicAddressShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForAddPublicAddressShouldReturnFee")

        FIOSDK.sharedInstance().getFeeForAddPublicAddress(fioAddress: self.requestorFioName, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForNewFundsRequestShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForNewFundsRequestShouldReturnFee")
        FIOSDK.sharedInstance().getFeeForNewFundsRequest(payeePublicAddress: self.requesteeAddress, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    
    func testGetFeeForRejectFundsRequestShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForRejectFundsRequestShouldReturnFee")
        
        FIOSDK.sharedInstance().getFeeForRejectFundsRequest(payeePublicAddress: self.requestorFioName, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForRecordSendShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForRecordSendShouldReturnFee")

        FIOSDK.sharedInstance().getFeeForRecordSend(payerFioAddress: self.requesteeFioName, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee > 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetAbi() {
        let expectation = XCTestExpectation(description: "testGetABI")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().getABI(accountName:"fio.address", onCompletion: { (response, error) in
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
    
}
