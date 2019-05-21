//
//  BaseFIOSDK.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-18.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public class BaseFIOSDK: NSObject {
    
    internal var accountName:String = ""
    internal var privateKey:String = ""
    internal var publicKey:String = ""
    internal var systemPrivateKey:String = ""
    internal var systemPublicKey:String = ""
    internal static let keyManager = FIOKeyManager()
    internal let pubAddressTokenFilter: [String: UInt8] = ["fio": 1]
    
    internal override init() {}
    
    internal func isFIOAddressValid(_ address: String) -> Bool {
        let fullNameArr = address.components(separatedBy: ".")
        
        if (fullNameArr.count != 2) {
            return false
        }
        
        for namepart in fullNameArr {
            if (namepart.range(of:"[^A-Za-z0-9]",options: .regularExpression) != nil) {
                return false
            }
        }
        
        if fullNameArr[0].count < 3 || fullNameArr[0].count > 100 {
            return false
        }
        
        return true
    }
    
    internal func isFIODomainValid(_ domain: String) -> Bool {
        if domain.isEmpty || domain.count > 50 { return false }
        
        if domain.range(of:"^(\\w)+(-\\w+)*$", options: .regularExpression) == nil {
            return false
        }
        
        return true
    }
    
    internal func getAccountName() -> String{
        return self.accountName
    }
    
    
    internal func getPrivateKey() -> String {
        return self.privateKey
    }
    
    internal func getSystemPrivateKey() -> String {
        return self.systemPrivateKey
    }
    
    internal func getSystemPublicKey() -> String {
        return self.systemPublicKey
    }
    
    internal func getURI() -> String {
        return Utilities.sharedInstance().URL
    }
    
    /// The mock URL of the mock http server
    internal func getMockURI() -> String?{
        return Utilities.sharedInstance().mockURL
    }
    
    public func getPublicKey() -> String {
        return self.publicKey
    }
    
    //MARK: - Chain Info
    
    internal func chainInfo(completion: @escaping (_ result: ChainInfo?, _ error: Error?) -> ()) {
        FIOHTTPHelper.rpcPostRequestTo(ChainRouteBuilder.build(route: ChainRoutes.getInfo), withBody: nil as String?,  onCompletion: completion)
    }
    
    internal func getBlock(blockNumOrId: AnyObject, completion: @escaping (_ result: BlockInfo?, _ error: Error?) -> ()) {
        let body = ["block_num_or_id": "\(blockNumOrId)"]
        FIOHTTPHelper.rpcPostRequestTo(ChainRouteBuilder.build(route: ChainRoutes.getBlock), withBody: body, onCompletion: completion)
    }
    
}
