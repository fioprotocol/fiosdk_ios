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
    internal var _abis: [String: String] = ["fio.system":"", "fio.reqobt":"", "fio.token":""]
    
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
        return self.publicKey.replacingOccurrences(of: "EOS", with: "FIO")
    }
    
    //MARK: - Chain Info
    
    internal func chainInfo(completion: @escaping (_ result: ChainInfo?, _ error: Error?) -> ()) {
        FIOHTTPHelper.rpcPostRequestTo(ChainRouteBuilder.build(route: ChainRoutes.getInfo), withBody: nil as String?,  onCompletion: completion)
    }
    
    internal func getBlock(blockNumOrId: AnyObject, completion: @escaping (_ result: BlockInfo?, _ error: Error?) -> ()) {
        let body = ["block_num_or_id": "\(blockNumOrId)"]
        FIOHTTPHelper.rpcPostRequestTo(ChainRouteBuilder.build(route: ChainRoutes.getBlock), withBody: body, onCompletion: completion)
    }
    
    internal func populateABIs() {
        for accountName in self._abis.keys {
            self.getABI(accountName: accountName) { (response, error) in
                
                if (error.kind == FIOError.ErrorKind.Success){
                    if (response?.abi != nil){
                        self._abis.updateValue(response?.abi ?? "", forKey: accountName)
                    }
                }
            }
        }
    }
    
    /// Retrieves ABI. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/get_raw_abi-GetABIforspecificaccountname)
    /// - Parameters:
    ///     - account name: this can be: "fio.system","fio.reqobt","fio.token"
    ///     - completion: A function that is called once request is over with an optional response that should contain abi results and error containing the status of the call.
    internal func getABI(accountName: String, onCompletion: @escaping (_ response: FIOSDK.Responses.GetABIResponse?, _ error: FIOError) -> ()){
        let body = GetABIRequest(accountName: accountName)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getABI)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    var result = try JSONDecoder().decode(FIOSDK.Responses.GetABIResponse.self, from: data)
                    
                    let serializer:abiSerializer = abiSerializer()
                    var abi:String = result.abi
                    
                    abi = abi.padding(toLength: ((abi.count+3)/4)*4,
                                      withPad: "=",
                                      startingAt: 0)
                    let abiData = Data(base64Encoded: abi)
                    if (abiData != nil){
                        let abiHexData = abiData!.hexEncodedString()
                        let binaryToJsonTransaction = try? serializer.deserializeAbi(hex: String(abiHexData.dropLast(2)))
                        result.abi = binaryToJsonTransaction!
                        
                        onCompletion(result, FIOError.success())
                    }
                    else{
                        onCompletion(nil, FIOError.failure(localizedDescription: "Parsing abi data failed."))
                    }
                }
                catch {
                    onCompletion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    onCompletion(nil, error)
                }
                else {
                    onCompletion(nil, FIOError.failure(localizedDescription: ChainRoutes.getABI.rawValue + " request failed."))
                }
            }
        }
    }
    
}
