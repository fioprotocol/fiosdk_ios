//
//  FIOSDKTests.swift
//  FIOSDKTests
//
//  Created by shawn arney on 10/19/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import XCTest
@testable import FIOSDK

private let useDefaultServer = true //want a custom server, set to true and then set the DEFAULT_SERVER to your ip/url
private let useAlternateServer = false

private let DEFAULT_SERVER = "https://testnet.fioprotocol.io/v1"
private let MOCK_DEFAULT_SERVER = ""

private let ALTERNATE_SERVER = "https://dev2.fio.dev/v1"
private let MOCK_ALTERNATE_SERVER = ""

class FIOSDKTests: XCTestCase {
    
    private let TIMEOUT:Double = 240.0
    
    //MARK: Constants
    private let defaultServer   = (useDefaultServer ? DEFAULT_SERVER : ALTERNATE_SERVER)
    private let defaultMnemonic = "valley alien library bread worry brother bundle hammer loyal barely dune brave"
    private let expectedDefaultPrivateKey = "5Kbb37EAqQgZ9vWUHoPiC2uXYhyGSFNbL6oiDp24Ea1ADxV1qnu"
    private let expectedDefaultPublicKey = "FIO5kJKNHwctcfUM5XZyiWSqSTM5HTzznJP9F3ZdbhaQAHEVq575o"
    private let mockUrl = (useDefaultServer ? MOCK_DEFAULT_SERVER : MOCK_ALTERNATE_SERVER)
    
    private let fioPrivateKey = "your private key from testnet"
    private let fioPublicKey = "your public key from testnet"
    private let fioPrivateKeyAlternative = "your private key from testnet"
    private let fioPublicKeyAlternative = "your public key from testnet"
    
    private let faucetPrivateKey = ""
    private let faucetPublicKey = ""
    private let faucetFioAddress = "fio@faucet"
    
    private let TEST_DOMAIN = "fiotestnet"
    
    //MARK: test variables
    private var requesteeFioName: String = "alicetest61@fiotestnet"
    private let requesteeAddress: String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
    private var requestorFioName: String = "bobtest61@fiotestnet"
    private let requestorAddress: String = "0x3A2522321656285661Df2012a3A05bEF84C8B1ed"
    private var isFunded: Bool = true
    
    //MARK: Setup
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        defaultSDKConfig()
        if (isFunded == false || requesteeFioName.count < 1){
            print("CHANGED REGISTRATION")
            isFunded = true
            let timestamp = NSDate().timeIntervalSince1970
            requesteeFioName = "sha\(Int(timestamp.rounded()))@brd"
            requestorFioName = "bar\(Int(timestamp.rounded()))@brd"
            
            fundAccountWithFaucet(fioPublicKeyToFund: fioPublicKey)
            fundAccountWithFaucet(fioPublicKeyToFund: fioPublicKeyAlternative)
        
            sleep(6)
            registerDefaultUsers()
        }
        defaultSDKConfig()
        sleep(6)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func defaultSDKConfig() {
        try? FIOSDK.wipePrivatePublicKeys()
        _ = FIOSDK.sharedInstance(privateKey: fioPrivateKey, publicKey: fioPublicKey, url: defaultServer, mockUrl: mockUrl)
        
    }
    
    private func fundAccountWithFaucet(fioPublicKeyToFund:String) {
        
        _ = FIOSDK.sharedInstance(privateKey: self.faucetPrivateKey, publicKey: self.faucetPublicKey, url: defaultServer, mockUrl: mockUrl)

        sleep(5)
        print ("*****FAUCET")
        print (self.faucetPublicKey)
        print (defaultServer)
        
        FIOSDK.sharedInstance().transferTokens(payeePublicKey: fioPublicKeyToFund, amount: SUFUtils.amountToSUF(amount: 10000), maxFee: SUFUtils.amountToSUF(amount: 10000)) { (response, error) in
            print("***HERE*****")
            print(response)
            print(error)
            
        }
    }
    
    private func alternativeSDKConfig() {
        try? FIOSDK.wipePrivatePublicKeys()
        _ = FIOSDK.sharedInstance(privateKey: fioPrivateKeyAlternative, publicKey: fioPublicKeyAlternative, url: defaultServer, mockUrl: mockUrl)
        
    }
    
    func registerDefaultUsers() {
        
        print ("*************REGISTERING*******")

        self.defaultSDKConfig()
        let expectation = XCTestExpectation(description: "testRegisterFIOName")

        FIOSDK.sharedInstance().registerFioAddress(requesteeFioName, maxFee: SUFUtils.amountToSUF(amount: 1000.0)) { (fioResponse, fioError) in
            XCTAssert((fioError?.kind == FIOError.ErrorKind.Success), "registerFIOName for default sdk, NOT SUCCESSFUL")
            
            if fioError?.kind == .Success {
                self.alternativeSDKConfig()

            
                FIOSDK.sharedInstance().registerFioAddress(self.requestorFioName, maxFee: SUFUtils.amountToSUF(amount: 1000.0)) { (fioResponse2, fioError2) in
                    XCTAssert((fioError2?.kind == FIOError.ErrorKind.Success), "registerFIOName for alternate sdk config, NOT SUCCESSFUL")
                    
                    self.defaultSDKConfig()
                    expectation.fulfill()
                }
            }
            else {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    //MARK: -
    
    func testPublicKeyFromStringShouldGeneratePublicKey() {
        try? FIOSDK.wipePrivatePublicKeys()
        let mnemonic = "gallery hero weekend notable inherit chuckle village spread business scrap surprise finger"
        let keyPair = FIOSDK.privatePublicKeyPair(forMnemonic: mnemonic)
        let privKey = try? PrivateKey(enclave: .Secp256k1, mnemonicString: mnemonic)
        guard let pk = privKey else {
            XCTFail()
            return
        }
        guard let pubkey = try? PublicKey(keyString: keyPair.publicKey) else {
            XCTFail()
            return
        }
        print ("*-*")
        print ("*" + pubkey!.rawPublicKey() + "*")
        print ("*" + PublicKey(privateKey: pk!).rawPublicKey() + "*")
        print ("*-*")
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
        
        XCTAssert(FIOSDK.sharedInstance().isFioNameValid(fioName: "test@brd"), "should be valid")
        
        XCTAssert (FIOSDK.sharedInstance().isFioNameValid(fioName: "test1234567890123456@brd"), "should be valid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test@brd@brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test#!@brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test#!:brd"), "should be invalid")
        
        XCTAssert (!FIOSDK.sharedInstance().isFioNameValid(fioName: "12-@brd"), "should be invalid")
        
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
        
        // chain code validation
        XCTAssert(FIOSDK.sharedInstance().isChainCodeValid("BTC0132342"), "should be valid")
        XCTAssert(FIOSDK.sharedInstance().isChainCodeValid("BTC"), "should be valid")
        XCTAssert(FIOSDK.sharedInstance().isChainCodeValid("B"), "should be valid")
        XCTAssert(FIOSDK.sharedInstance().isChainCodeValid("0"), "should be valid")
        XCTAssert(!FIOSDK.sharedInstance().isChainCodeValid("BTC01323423"), "should be invalid")
        XCTAssert(!FIOSDK.sharedInstance().isChainCodeValid(""), "should be invalid")
        
        // token code validation
        XCTAssert(FIOSDK.sharedInstance().isTokenCodeValid("BTC0132342"), "should be valid")
        XCTAssert(FIOSDK.sharedInstance().isTokenCodeValid("BTC"), "should be valid")
        XCTAssert(FIOSDK.sharedInstance().isTokenCodeValid("B"), "should be valid")
        XCTAssert(FIOSDK.sharedInstance().isTokenCodeValid("0"), "should be valid")
        XCTAssert(!FIOSDK.sharedInstance().isTokenCodeValid("BTC01323423"), "should be invalid")
        XCTAssert(!FIOSDK.sharedInstance().isTokenCodeValid(""), "should be invalid")
        
        // public address validation
        XCTAssert(FIOSDK.sharedInstance().isPublicAddressValid("b"), "should be valid")
        XCTAssert(FIOSDK.sharedInstance()   .isPublicAddressValid("abacdefghaiweroiefjewriefoiwej3314539104371571xwere343424373573244737473474747474774747474329sjxzdddddddddddddddddddhagagggyiila"), "should be valid")
        
        XCTAssert(!FIOSDK.sharedInstance().isPublicAddressValid(""), "should be invalid")
        XCTAssert(!FIOSDK.sharedInstance()   .isPublicAddressValid("aaabcdefghaiweroiefjewriefoiwej3314539104371571xwere343424373573244737473474747474774747474329sjxzdddddddddddddddddddhagagggyiila"), "should be invalid")
        
        // fio public key validation
        XCTAssert(FIOSDK.sharedInstance().isFioPublicKeyValid("FIOa"), "should be valid")  // really needs to be more sophisticated
        XCTAssert(!FIOSDK.sharedInstance().isFioPublicKeyValid("FIO"), "should be invalid")
        XCTAssert(!FIOSDK.sharedInstance().isFioPublicKeyValid("b"), "should be invalid")
        XCTAssert(!FIOSDK.sharedInstance().isFioPublicKeyValid(""), "should be invalid")
    
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
        let fioAddress = "fioaddress\(Int(timestamp.rounded()))@brd"
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
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chainCode:"ETH", tokenCode: "ETH", publicAddress: pubAdd, maxFee: SUFUtils.amountToSUF(amount: 1100.0)) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testAddPublicAddressWithFIOTokenShouldFail(){
        let expectation = XCTestExpectation(description: "testaddpublicaddress")
        let timestamp = NSDate().timeIntervalSince1970
        let pubAdd = "pubAdd\(Int(timestamp.rounded()))"
        
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chainCode: "FIO", tokenCode: "FIO", publicAddress: pubAdd, maxFee: SUFUtils.amountToSUF(amount: 1100.0)) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), "testAddPublicAddressWithFIOTokenShouldFail tried to add FIO Token address.")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testAddPublicKeyAsPublicAddress(){
        let expectation = XCTestExpectation(description: "testaddpublicaddress")

        FIOSDK.sharedInstance().addPublicAddress(fioAddress: self.requestorFioName, chainCode:"PKEY", tokenCode: "PKEY", publicAddress: FIOSDK.sharedInstance().getPublicKey(), maxFee: SUFUtils.amountToSUF(amount: 1100.0)) { (response, error) in
            guard error?.kind == FIOError.ErrorKind.Success else {
                expectation.fulfill()
                return
            }
            
            
            
            FIOSDK.sharedInstance().getPublicAddress(fioAddress: self.requestorFioName, chainCode:"PKEY", tokenCode: "PKEY", onCompletion: { (response, error) in
                XCTAssert((error.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error.localizedDescription)")
                expectation.fulfill()
            })
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testGetFioNamesWithInvalidAddressShouldRespondWithNotFound(){
        let expectation = XCTestExpectation(description: "testgetfionames")
        FIOSDK.sharedInstance().getFioNames(fioPublicKey: "NOT VALID ADDRESS") { (data, error) in

            if (data != nil){
                XCTAssertNil(data,  "Should have failed")
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    
    func testGetFIONameDetailsWithGoodNameShouldSucceed() {
        let expectation = XCTestExpectation(description: "testGetFIONameDetailsWithGoodNameShouldSucceed")
        
       // self.defaultSDKConfig()
        
        
        FIOSDK.sharedInstance().getFioAddressDetails(self.requesteeFioName) { (response, error) in
            XCTAssert(error.kind == .Success, "getPublicAddress error")
            XCTAssertNotNil(response, "getPublicAddress error")
            
            if error.kind != .Success {
                expectation.fulfill()
            }
            else {
                XCTAssert(response?.address == self.requesteeFioName, "Wrong fio address")
                XCTAssertNotNil(response?.address, "name NOT FOUND")
                XCTAssertNotNil(response?.expiration, "date NOT FOUND")
                print(error)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT*2)
    }
    
    func testGetFIONameDetailsWithBadNameShouldFail() {
        let expectation = XCTestExpectation(description: "testGetFIONameDetailsWithBadNameShouldFail")
        
        FIOSDK.sharedInstance().getFioAddressDetails("NOT_VALID_NAME") { (response, error) in
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
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: requesteeFioName, chainCode:"FIO", tokenCode: "FIO") { (response, error) in
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
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: requesteeFioName, chainCode:"NOtVALID", tokenCode: "NOTVALID") { (response, error) in
            XCTAssert(error.kind == .Failure, "should've failed")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT)
    }
        
    func testGetTokenPublicAddressWithInvalidTokenShouldFail() {
        let expectation = XCTestExpectation(description: "testGetTokenPublicAddressWithInvalidTokenShouldFail")
        
        let timestamp = NSDate().timeIntervalSince1970
        let tokenPubAdd = "smp\(Int(timestamp.rounded()))"
        
        FIOSDK.sharedInstance().getPublicAddress(fioPublicKey: tokenPubAdd, chainCode: "INVALIDTOKEN", tokenCode: "INVALIDTOKEN", onCompletion: { (response, error) in
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
        
        FIOSDK.sharedInstance().requestFunds(payer: payer, payee: payee, payeePublicAddress: toPubAdd, amount: 1.0, chainCode: "BTC", tokenCode: "BTC", metadata: metadata, maxFee: 3000000000, walletFioAddress: "") { (response, error) in
                if error?.kind == .Success {
                    expectationReqFunds.fulfill()
                }
                else {
                    XCTFail("Failed to call requestFunds")
                    print(error)
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
        FIOSDK.sharedInstance().addPublicAddress(fioAddress: from, chainCode: "BTC", tokenCode: "BTC", publicAddress: fromPubAdd, maxFee: 1000 * SUFUtils.SUFUnit) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
            self.defaultSDKConfig()
            FIOSDK.sharedInstance().addPublicAddress(fioAddress: to, chainCode: "BTC", tokenCode: "BTC", publicAddress: toPubAdd, maxFee: 0) { (response, error) in
                XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddress NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")
        
                FIOSDK.sharedInstance().requestFunds(payer: from, payee: to, payeePublicAddress: toPubAdd, amount: 1.0, chainCode: "BTC", tokenCode: "BTC", metadata: metadata, maxFee: 0) { (response, error) in
                    XCTAssert(error?.kind == .Success, "requestFunds failed")
                    XCTAssertNotNil(response)
                    print(error)
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
        
        let publicAddresses = PublicAddress(chainCode: "BTC", tokenCode: "BTC", publicAddress: fromPubAdd)
        FIOSDK.sharedInstance().addPublicAddresses(fioAddress: to, publicAddresses: [publicAddresses], maxFee: 1000 * SUFUtils.SUFUnit) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "testAddPublicAddresses NOT SUCCESSFUL: \(error?.localizedDescription ?? "")")

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
  ///sarney -failing
    /// Test for reject_funds_request
    func testRejectFundsRequest(){
        let expectation = XCTestExpectation(description: "testRejectFundsRequest")
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        self.alternativeSDKConfig()
        sleep(6)
        //requestor is sender, requestee is receiver
        FIOSDK.sharedInstance().requestFunds(payer: self.requesteeFioName, payee: self.requestorFioName, payeePublicAddress: FIOSDK.sharedInstance().getPublicKey(), amount: 9, chainCode: "FIO", tokenCode: "FIO", metadata: metadata, maxFee: 10000000000) { (response, error) in
            
            XCTAssert(error?.kind == .Success && response != nil, "testRejectFundsRequest Couldn't create mock request"  + (error?.localizedDescription ?? ""))
            if let response = response {
                self.defaultSDKConfig()
                FIOSDK.sharedInstance().rejectFundsRequest(fioRequestId: response.fioRequestId, maxFee: 10000000000, onCompletion: { (response, error) in
                    XCTAssert(error.kind == .Success, "testRejectFundsRequest couldn't reject request"  + (error.localizedDescription ?? ""))
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
         
        FIOSDK.sharedInstance().requestFunds(payer: payer, payee: payee, payeePublicAddress: toPubAdd, amount: 1.0, chainCode: "BTC", tokenCode: "BTC", metadata: metadata, maxFee: 1000000000000, walletFioAddress: "") { (response, error) in
                 if error?.kind == .Success {
                     expRequestFunds.fulfill()
                     
                     FIOSDK.sharedInstance().getSentFioRequests() { (sentRecords, sentError) in
                         
                         XCTAssert(sentError.kind == .Success && sentRecords != nil, "Sent Request couldn't retreive request")
                         guard sentError.kind == .Success, sentRecords != nil else {
                            XCTFail("testGetSentAndPendingRequests Request should have sent fio requests")
                            expGetSentRequest.fulfill()
                            expGetPendingRequest.fulfill()
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
                     expGetPendingRequest.fulfill()
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
        let fioName = "sha\(Int(timestamp.rounded()))@" + TEST_DOMAIN
        let expectation = XCTestExpectation(description: "testRegisterFIONameWithNewValueShouldRegister")
        
        self.defaultSDKConfig()
       
        FIOSDK.sharedInstance().registerFioAddress(fioName, maxFee: SUFUtils.amountToSUF(amount: 1000.0), onCompletion: {response, error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL" + (error?.localizedDescription ?? "") )
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    func testRegisterFIONameWithAlreadyRegisteredValueShouldFail() {
        let timestamp = NSDate().timeIntervalSince1970
        let fioName = "sha\(Int(timestamp.rounded()))@" + TEST_DOMAIN
        let expectation = XCTestExpectation(description: "testRegisterFIONameWithAlreadyRegisteredValueShouldFail")

        
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()

        FIOSDK.sharedInstance().registerFioAddress(fioName, maxFee: SUFUtils.amountToSUF(amount: 1100.0), onCompletion: { response, error in ()
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOName NOT SUCCESSFUL")
            FIOSDK.sharedInstance().registerFioAddress(fioName, maxFee: SUFUtils.amountToSUF(amount: 1100.0), onCompletion: { response, error in ()
                XCTAssert((error?.kind == FIOError.ErrorKind.Failure), "registerFIOName NOT SUCCESSFUL")
                expectation.fulfill()
            })
        })

        wait(for: [expectation], timeout: TIMEOUT)
    }
    
    ///sarney failing
    func testRegisterAndRenewFIODomainWithNewValueShouldRenewNoWallet() {
        let timestamp = NSDate().timeIntervalSince1970
        let domain = "test\(Int(timestamp.rounded()))"
        let expectation = XCTestExpectation(description: "testRenewFIODomainWithNewValueShouldRenewNoWallet")
        self.defaultSDKConfig()
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 1000.0), onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 1000.0), onCompletion: { (response, error) in
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
        
        FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 100.00), onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"renewFIODomain Should not renew invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    
    func testRenewFIODomainWithInvalidValueShouldNotRenew() {
        let domain = "#&*("
        let expectation = XCTestExpectation(description: "testRenewFIODomainWithInvalidValueShouldNotRenew")
        let walletFioAddress = "test@edge"
        
        FIOSDK.sharedInstance().renewFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 1100.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"renewFIODomain Should not renew invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    

    
    func testRegisterFIODomainWithInvalidValueShouldNotRegister() {
        let domain = "#&*("
        let expectation = XCTestExpectation(description: "testRegisterFIODomainWithNewValueShouldRegister")
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 20.0), walletFioAddress:"", onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIODomain Should not register invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIODomainWithInvalidValueShouldNotRegisterNoWallet() {
        let domain = "#&*("
        let expectation = XCTestExpectation(description: "testRegisterFIODomainWithNewValueShouldRegister")
        
        FIOSDK.sharedInstance().registerFioDomain(domain, maxFee: SUFUtils.amountToSUF(amount: 1100.0), onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIODomain Should not register invalid domains: %@", domain))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIOAddressWithNewValueShouldRenew() {
        let timestamp = NSDate().timeIntervalSince1970
        let address = "test\(Int(timestamp.rounded()))@" + TEST_DOMAIN
        let expectation = XCTestExpectation(description: "testRenewFIOAddressWithNewValueShouldRenew")
        let walletFioAddress = ""
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1100.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().renewFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1100.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
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
        let walletFioAddress = "test@fiotestnet"
        
        FIOSDK.sharedInstance().renewFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1100.0), walletFioAddress: walletFioAddress, onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"renewFIODomain Should not renew invalid address: %@", address))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRenewFIOAddressWithNewValueShouldRegisterNoWallet() {
        let timestamp = NSDate().timeIntervalSince1970
        let address = "test\(Int(timestamp.rounded()))@" + TEST_DOMAIN
        let expectation = XCTestExpectation(description: "testRenewFIOAddressWithNewValueShouldRegister")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1100.0), onCompletion: { (response, error) in
            if error?.kind == .Success {
                sleep(60)
                FIOSDK.sharedInstance().renewFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1100.0), onCompletion: { (response, error) in
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
        
        FIOSDK.sharedInstance().renewFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1100.0), onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"renewFIODomain Should not renew invalid address: %@", address))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIOAddressWithInvalidValueShouldNotRegister() {
        let address = "#&*("
        let expectation = XCTestExpectation(description: "testRegisterFIOAddressWithInvalidValueShouldNotRegister")
        let walletFioAddress = "test@fiotestnet"
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1100.0), walletFioAddress: walletFioAddress , onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIOAddress Should not register invalid address: %@", address))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIOAddressWithNewValueShouldRegisterNoWallet() {
        let timestamp = NSDate().timeIntervalSince1970
        let address = "test\(Int(timestamp.rounded()))@" + TEST_DOMAIN
        let expectation = XCTestExpectation(description: "testRegisterFIOAddressWithNewValueShouldRegister")
        let metadata = RequestFundsRequest.MetaData(memo: "", hash: nil, offlineUrl: nil)
        
        self.defaultSDKConfig()

        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1100.0), onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "registerFIOAddress NOT SUCCESSFUL")
            XCTAssertNotNil(response)
            XCTAssert(response?.status != "")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testRegisterFIOAddressWithInvalidValueShouldNotRegisterNoWallet() {
        let address = "#&*("
        let expectation = XCTestExpectation(description: "testRegisterFIOAddressWithInvalidValueShouldNotRegister")
        
        FIOSDK.sharedInstance().registerFioAddress(address, maxFee: SUFUtils.amountToSUF(amount: 1000.0), onCompletion: { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Failure), String(format:"registerFIOAddress Should not register invalid address: %@", address))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
   
    //MARK: -
    // broken here
    func testRecordObtDataAndGetObtData() {
        let expectation = XCTestExpectation(description: "testRecordObtDataAndGetObtData - recordObt")
        let expectationData = XCTestExpectation(description: "testRecordObtDataAndGetObtData - Data")
        
        let amount = 7.65
        let payee = self.requestorFioName
        let payer = self.requesteeFioName
        let timestamp = NSDate().timeIntervalSince1970
        let fromPubAdd = "froma\(Int(timestamp.rounded()))"
        let toPubAdd = "toa\(Int(timestamp.rounded()))"
        let obtID = "0xf6daddd3851923f6f9653838d3021c02ab123a4a6e4485e83f5063b3711e000b"
        
        defaultSDKConfig()
        let metaData = RecordObtDataRequest.MetaData(memo: "", hash: "", offlineUrl: "")
        FIOSDK.sharedInstance().recordObtData(payerFIOAddress: payer, payeeFIOAddress: payee, payerTokenPublicAddress: fromPubAdd, payeeTokenPublicAddress: toPubAdd, amount: amount, chainCode: "VIT", tokenCode: "VIT", obtId: obtID, maxFee: SUFUtils.amountToSUF(amount: 2.0), metaData: metaData) { (response, error) in
            XCTAssert((error?.kind == FIOError.ErrorKind.Success), "recordSend NOT SUCCESSFUL")
            expectation.fulfill()
            
            FIOSDK.sharedInstance().getObtData { (obtResponse, fioError) in
                XCTAssert(obtResponse != nil, "getObtData not found")

                if (obtResponse != nil) {
                    XCTAssert((obtResponse?.obtData.count ?? 0) > 0, "No getObtData")
                }
                expectationData.fulfill()
            }
            
        }

        wait(for: [expectation, expectationData], timeout: TIMEOUT)
    }
    
    func testGetFIOBalanceWithProperSetupShouldReturnValue() {
        let expectation = XCTestExpectation(description: "testGetFIOBalanceWithProperSetupShouldReturnValue")
        let fioPubAddress = FIOSDK.sharedInstance().publicKey;
        
        FIOSDK.sharedInstance().getFioBalance(fioPublicKey: fioPubAddress) { (response, error) in
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
        let walletFioAddress = "test@edge"
        
        fioSDK.transferTokens(payeePublicKey: payeePublicKey, amount: SUFUtils.amountToSUF(amount: amount), maxFee: SUFUtils.amountToSUF(amount: 12.0), walletFioAddress: walletFioAddress) { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
            XCTAssertNotNil(response?.feeCollected)
            //Transfer back
            self.defaultSDKConfig()
            sleep(20)
            FIOSDK.sharedInstance().transferTokens(payeePublicKey: payerPublicKey, amount: SUFUtils.amountToSUF(amount: amount), maxFee: SUFUtils.amountToSUF(amount: 2.0), walletFioAddress: walletFioAddress) { (response, error) in
                XCTAssert((error.kind == FIOError.ErrorKind.Success), "transfer failed: \(error.localizedDescription )")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: TIMEOUT * 1.5)
    }
    
    func testPrivatePubKeyPairMultipleGenerateShouldWork() {
        try? FIOSDK.wipePrivatePublicKeys()
        var keys = FIOSDK.privatePublicKeyPair(forMnemonic: "hotel royal gasp strike hurdle expect dish surface era observe casual pond")
        XCTAssert(!keys.privateKey.isEmpty && !keys.publicKey.isEmpty)
        keys = FIOSDK.privatePublicKeyPair(forMnemonic: "mirror bid phrase scheme wing valid fringe insane august wasp join toast")
        XCTAssert(!keys.privateKey.isEmpty && !keys.publicKey.isEmpty)
        keys = FIOSDK.privatePublicKeyPair(forMnemonic: defaultMnemonic)
        XCTAssert(!keys.privateKey.isEmpty && !keys.publicKey.isEmpty)
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
            XCTAssert(fee >= 0, "Something went wrong")
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
            XCTAssert(fee >= 0, "Something went wrong")
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
            XCTAssert(fee >= 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    
    func testGetFeeForAddPublicAddressShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForAddPublicAddressShouldReturnFee")
print("****")
        print(self.requestorFioName)
        FIOSDK.sharedInstance().getFeeForAddPublicAddress(fioAddress: self.requestorFioName, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee >= 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForNewFundsRequestShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForNewFundsRequestShouldReturnFee")
        print("****")
        print(self.requesteeAddress)
        FIOSDK.sharedInstance().getFeeForNewFundsRequest(payeeFioAddress: self.requesteeFioName, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee >= 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    
    func testGetFeeForRejectFundsRequestShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForRejectFundsRequestShouldReturnFee")
        
        FIOSDK.sharedInstance().getFeeForRejectFundsRequest(payeeFioAddress: self.requestorFioName, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee >= 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForRecordObtDataShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForRecordSendShouldReturnFee")

        FIOSDK.sharedInstance().getFeeForRecordObtData(payerFioAddress: self.requesteeFioName, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee >= 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForRenewAddressShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForRenewAddressShouldReturnFee")

        FIOSDK.sharedInstance().getFee(endPoint: FIOSDK.Params.FeeEndpoint.renewFIOAddress, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee >= 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetFeeForRenewDomainShouldReturnFee() {
        let expectation = XCTestExpectation(description: "testGetFeeForRenewDomainShouldReturnFee")

        FIOSDK.sharedInstance().getFee(endPoint: FIOSDK.Params.FeeEndpoint.renewFIODomain, onCompletion: { (response, error) in
            XCTAssert((error.kind == FIOError.ErrorKind.Success), "getFee failed: \(error.localizedDescription )")
            guard let fee = response?.fee else {
                XCTFail("Fee not returned")
                expectation.fulfill()
                return
            }
            XCTAssert(fee >= 0, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT * 3)
    }
    
    func testGetAbi() {
        let expectation = XCTestExpectation(description: "testGetABI")
        
        self.defaultSDKConfig()
        FIOSDK.sharedInstance().getABI(accountName:"fio.address", onCompletion: { (response, error) in
            XCTAssert(error.kind == .Success, "Something went wrong")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: TIMEOUT)
    }
    
}
