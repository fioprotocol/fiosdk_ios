//
//  AccountUtil.swift
//  SwiftyEOS
//
//  Created by liu nian on 2018/9/7.
//  Copyright © 2018 ProChain. All rights reserved.
//

import Foundation

//@objcMembers class NewAccountParam: NSObject, Codable {
//    var creator: String = ""
//    var name: String = ""
//    var owner: RequiredAuth?
//    var active: RequiredAuth?
//}
//@objcMembers class AccountUtil: NSObject {
//    
//    static private func newAccountAbiJson(code:String, creator: String, account: String, ownerKey: String, activeKey: String) -> AbiJson {
//        
//        let ownerAuthKey = AuthKey()
//        ownerAuthKey.key = ownerKey
//        ownerAuthKey.weight = 1
//        
//        let activeAuthKey = AuthKey()
//        activeAuthKey.key = activeKey
//        activeAuthKey.weight = 1
//        
//        let ownerRequiredAuth = RequiredAuth()
//        ownerRequiredAuth.keys = [ownerAuthKey]
//        ownerRequiredAuth.threshold = 1
//        
//        let activeRequiredAuth = RequiredAuth()
//        activeRequiredAuth.keys = [activeAuthKey]
//        activeRequiredAuth.threshold = 1
//        
//        let param = NewAccountParam()
//        param.creator = creator
//        param.name = account
//        param.owner = ownerRequiredAuth
//        param.active = activeRequiredAuth
//        
//        let encoder = JSONEncoder()
//        encoder.keyEncodingStrategy = .convertToSnakeCase
//        let jsonData = try! encoder.encode(param)
//        let jsonString = String(data: jsonData, encoding: .utf8)
//        print("********")
//        print(jsonString)
//        return try! AbiJson(code: code, action: "newaccount", json: jsonString!)
//    }
//    
//    /// creator help someone create an account
//    ///
//    /// - Parameters:
//    ///   - account: account that need to be created
//    ///   - ownerKey: ownerKey(privatekey) for account
//    ///   - activeKey: activeKey(privatekey) for account
//    ///   - creator: creator
//    ///   - pkString: privatekey
//    ///   - ramEos: ram resource
//    ///   - netEos: net resource
//    ///   - cpuEos: cpu resource
//    ///   - transfer: Whether to transfer creator's resources(ram,cpu,net) to account
//    ///   - completion: callback
//    
//    static func createAccount(account: String, ownerKey: String, activeKey: String, creator: String, pkString: String, completion: @escaping (_ result: TransactionResult?, _ error: Error?) -> ()) {
//        
//        print (account)
//
//        let newaccountAbiJson = newAccountAbiJson(code: "eosio", creator: creator, account: account, ownerKey: ownerKey, activeKey: activeKey)
//        let buyRamAbiJson = ResourceUtil.buyRamAbiJson(payer: creator, receiver: account, ramEos: 100.0000)
//        let delegatebwAbiJson = ResourceUtil.stakeResourceAbiJson(from: creator, receiver: account, transfer: 1, net: 100.0000, cpu: 100.0000)
//        
//        guard let privateKey = try? PrivateKey(keyString: pkString) else {
//            completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "invalid private key"]))
//            return
//        }
//        
//        TransactionUtil.pushTransaction(abis: [newaccountAbiJson, buyRamAbiJson, delegatebwAbiJson], account: creator, privateKey: privateKey!, completion: completion)
//    }
//    
//}
