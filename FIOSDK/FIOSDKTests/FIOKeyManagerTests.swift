//
//  FIOKeyManagerTests.swift
//  FIOSDKTests
//
//  Created by Vitor Navarro on 2019-04-05.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import XCTest
@testable import FIOSDK

class KeychainInteractorMock: KeychainInteractor {
    
    var storage: [String:Any] = [:]
    
    convenience init() {
        self.init(walletSecAttrService: "")
    }
    
    override func keychainItem<T>(key: String) throws -> T? {
        return storage[key] as? T
    }
    
    override func setKeychainItem<T>(key: String, item: T?, authenticated: Bool = false) throws {
        guard let item = item else { return }
        storage[key] = item
    }
    
    func setItem(key: String, item: String) {
        storage[key] = item
    }
    
    func item(key: String) -> String? {
        return storage[key] as? String
    }
    
    func clean() {
        storage.removeAll()
    }
    
}

class FIOKeyManagerTests: XCTestCase {
    
    let keychainInteractor = KeychainInteractorMock()
    var fioKeyManager: FIOKeyManager!
    let mnemonic = "return buddy frown mind cupboard forest project permit taste season kingdom island"
    
    override func setUp() {
        keychainInteractor.clean()
        fioKeyManager = FIOKeyManager(keychainInteractor: keychainInteractor)
    }
    
    func testPrivatePubKeyPairWithoutPhraseShouldBeEmptyTuple() {
        let keys = fioKeyManager.privatePubKeyPair(mnemonic: nil)
        
        XCTAssert(keys.privateKey == "", "Private key should not be generated without phrase")
        XCTAssert(keys.publicKey == "", "Public key should not be generated without phrase")
    }
    
    func testPrivatePubKeyPairWithPhraseShouldBeGenerated() {
        let keys = fioKeyManager.privatePubKeyPair(mnemonic: mnemonic)
        XCTAssert(!keys.privateKey.isEmpty, "Private key should be generated")
        XCTAssert(!keys.publicKey.isEmpty, "Public key should be generated")
    }

    func testGeneratePrivPubKeyPairTwoTimesShouldReturnStoredKeys() {
        let keys = fioKeyManager.privatePubKeyPair(mnemonic: mnemonic)
        let storedPrivKey = keychainInteractor.item(key: KeychainKeys.fioPrivKey)
        XCTAssert(keys.privateKey == storedPrivKey && storedPrivKey == fioKeyManager.privatePubKeyPair(mnemonic: mnemonic).privateKey, "Subsequent requests to generate key should not generate new key")
    }
    
    func testWipeKeysShouldSucceed() {
        try? fioKeyManager.wipeKeys()
        XCTAssertNil(keychainInteractor.item(key: KeychainKeys.fioPrivKey), "Private key must be empty when wiped")
        XCTAssertNil(keychainInteractor.item(key: KeychainKeys.fioPubKey), "Public key must be empty when wiped")
    }
    
}
