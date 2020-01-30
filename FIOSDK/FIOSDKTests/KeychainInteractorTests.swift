//
//  KeychainInteractorTests.swift
//  FIOSDKTests
//
//  Created by Vitor Navarro on 2019-04-05.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//


import XCTest
@testable import FIOSDK

class KeychainInteractorTests: XCTestCase {
    
    let service = "io.dapix.tests"
    
    override func setUp() {
        let keychainInteractor = KeychainInteractor(walletSecAttrService: service)
        try? keychainInteractor.setKeychainItem(key: "Value", item: nil as String?)
    }

    func testKeychainItemWithoutValueShouldBeNil() {
        let keychainInteractor = KeychainInteractor(walletSecAttrService: service)
        do {
            let item: String? = try keychainInteractor.keychainItem(key: "Nil")
            XCTAssertNil(item, "Keychain item not present should be nil")
        }
        catch let error {
            XCTFail("Should not throw error \(error)")
        }
    }
    
    func testKeychainItemWithValueShouldBeTheValue() {
        let keychainInteractor = KeychainInteractor(walletSecAttrService: service)
        do {
            try keychainInteractor.setKeychainItem(key: "Value", item: "Secure item")
            let item: String? = try keychainInteractor.keychainItem(key: "Value")
            XCTAssert(item == "Secure item", "Keychain item not present should be nil")
        }
        catch let error {
            XCTFail("Should not throw error \(error)")
        }
    }
    
}
