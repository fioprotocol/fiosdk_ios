//
//  BaseFIOSDK.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-18.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

/**
*  BaseFIOSDK providing validation methods. [visit API specs](https://developers.fioprotocol.io)
**/
public class BaseFIOSDK: NSObject {
    
    internal var privateKey:String = ""
    internal var publicKey:String = ""
    internal static let keyManager = FIOKeyManager()
    internal let pubAddressTokenFilter: [String: UInt8] = ["fio": 1]
    internal var _abis: [String: String] = ["fio.address":"", "fio.reqobt":"", "fio.token":"", "eosio":""]
    internal var technologyProviderId = ""
    
    internal override init() {}
    
    //MARK: Validation
    
    /** Returns Is the token code valid?
     *
     * - Parameter tokenCode: token code to evaluate
     **/
    public func isTokenCodeValid(_ tokenCode:String) -> Bool {
        if (tokenCode.count > 0 && tokenCode.count < 11){
            if (tokenCode.range(of:"[a-zA-Z0-9]",options: .regularExpression) != nil) {
                return true
            }
        }
        return false
    }
    
    /** Returns Is the chain code valid?
     *
     * - Parameter chainCode: chain code to evaluate
     **/
    public func isChainCodeValid(_ chainCode:String) -> Bool {
        if (chainCode.count > 0 && chainCode.count < 11){
            if (chainCode.range(of:"[a-zA-Z0-9]",options: .regularExpression) != nil) {
                return true
            }
        }
        return false
    }
    
    /** Returns Is the fio public key valid?
     *
     * - Parameter fioPublicKey: fio public key to evaluate
     **/
    public func isFioPublicKeyValid(_ fioPublicKey: String) -> Bool {
        if (fioPublicKey.count < 4){
            return false
        }
        if (fioPublicKey.lowercased().hasPrefix("fio")){
            return true
        }
        return false
    }
    
    /** Returns Is the public address valid?
     *
     * - Parameter publicAddress: public address to evaluate
     **/
    public func isPublicAddressValid(_ publicAddress:String) -> Bool {
        return (publicAddress.count > 0 && publicAddress.count < 129)
    }
    
    /** Returns Is the fio address valid?
     *
     * - Parameter address: fio address to evaluate
     **/
    public func isFioAddressValid(_ address: String) -> Bool {
        let fullNameArr = address.components(separatedBy: "@")
        
        if (fullNameArr.count != 2) {
            return false
        }
        
        if (address.range(of:"^(?:(?=.{3,64}$)[a-zA-Z0-9]{1}(?:(?!-{2,}))[a-zA-Z0-9-]*(?:(?<!-))@[a-zA-Z0-9]{1}(?:(?!-{2,}))[a-zA-Z0-9-]*(?:(?<!-))$)",options: .regularExpression) != nil) {
            return true
        }

        return false
    }
    
    /** Returns Is the fio domain valid?
     *
     * - Parameter domain: fio domain to evaluate
     **/
    public func isFioDomainValid(_ domain: String) -> Bool {
        if domain.isEmpty || domain.count > 62 || domain.count < 1 { return false }
        
        if domain.range(of:"^(\\w)+(-\\w+)*$", options: .regularExpression) == nil {
            return false
        }
        
        return true
    }
    
    internal func getPrivateKey() -> String {
        return self.privateKey
    }

    internal func getURI() -> String {
        return Utilities.sharedInstance().URL
    }
    
    /// The mock URL of the mock http server
    internal func getMockURI() -> String?{
        return Utilities.sharedInstance().mockURL
    }
    
    //MARK: Get Public Key
    /** Returns the public key, as previously set at initialization of the FIOSDK singleton
     **/
    public func getPublicKey() -> String {
        return self.publicKey.replacingOccurrences(of: "EOS", with: "FIO")
    }
    
    internal func getTechnologyProviderId(_ technologyProviderId: String) -> String {
        return (technologyProviderId.count > 2 ? technologyProviderId : self.technologyProviderId)
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
    
    /// Retrieves ABI. [visit API specs](https://developers.fioprotocol.io)
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
