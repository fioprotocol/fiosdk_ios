//
//  FIOWalletSDK.swift
//  FIOWalletSDK
//
//  Created by shawn arney on 10/5/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import UIKit

public class FIOSDK: BaseFIOSDK {
    
    //MARK: Namespacing
    
    //Used as a namespace for response classes. Each model will be added with extension feature in its own file.
    public enum Responses {}
    //Used as a namespace for function params.
    public enum Params {}
    
    //MARK: - Initialization
    
    public static func isInitialized() -> Bool {
        return  !_sharedInstance.privateKey.isEmpty && !_sharedInstance.publicKey.isEmpty && !Utilities.sharedInstance().URL.isEmpty
    }
    
    private static var _sharedInstance: FIOSDK = {
        let sharedInstance = FIOSDK()
        
        return sharedInstance
    }()
    
    public class func sharedInstance(privateKey:String? = nil, publicKey:String? = nil, url:String? = nil, mockUrl: String? = nil) -> FIOSDK {
        
        if (privateKey == nil){
            if (_sharedInstance.privateKey.count < 2){
                fatalError("Private Key hasn't been set yet, for the FIOWalletSDK Shared Instance, this needs to be passed in with the first usage")
            }
        }
        else {
            _sharedInstance.privateKey = privateKey!
        }
        
        if (publicKey == nil){
            if (_sharedInstance.publicKey.count < 2){
                fatalError("Public Key hasn't been set yet, for the FIOWalletSDK Shared Instance, this needs to be passed in with the first usage")
            }
        }
        else {
            _sharedInstance.publicKey = publicKey!
        }
        
        if (url == nil){
            if (Utilities.sharedInstance().URL.count < 2){
                fatalError("URL hasn't been set yet, for the FIOWalletSDK Shared Instance, this needs to be passed in with the first usage")
            }
        }
        else {
            Utilities.sharedInstance().URL = url!
        }
        
        if let mockUrl = mockUrl{
            Utilities.sharedInstance().mockURL = mockUrl
        }
        
        // populate the abis
        let abi = _sharedInstance.getCachedABI(accountName: "fio.system")
        if (abi.count < 2){
            _sharedInstance.populateABIs()
        }
        
        return _sharedInstance
    }
    
    //MARK: FIO Name validation
    
    public func isFioNameValid(fioName: String) -> Bool{
        if fioName.contains("@") {
            return isFIOAddressValid(fioName)
        }
        return isFIODomainValid(fioName)
    }
    
    /// This method creates a private and public key based on a mnemonic, it does store both keys in keychain. Use it to setup FIOSDK properly.
    ///
    /// - Parameters:
    ///   - mnemonic: The text to use in key pair generation.
    /// - Return: A tuple containing both private and public keys to be used in FIOSDK setup.
    static public func privatePubKeyPair(forMnemonic mnemonic: String) -> (privateKey: String, publicKey: String) {
        return keyManager.privatePubKeyPair(mnemonic: mnemonic)
    }
    
    /// This method remove private and public keys from keychain. It may throw keychain access errors while doing so.
    static public func wipePrivPubKeys() throws {
        try keyManager.wipeKeys()
    }
    
    
    //MARK: - Renew FIO address request
    /**
     * This function should be called to renew a FIO Address. [visit api](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/renew_fio_address-RenewFIOAddress)
     * - Parameter fioAddress: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter onCompletion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func renewFioAddress(_ fioAddress: String, maxFee: Int, onCompletion: @escaping (_ response: FIOSDK.Responses.RenewFIOAddressResponse? , _ error:FIOError?) -> ()) {
        renewFioAddress(fioAddress, maxFee: maxFee, walletFioAddress: "", onCompletion: onCompletion)
    }
    
    /**
     * This function should be called to renew a FIO Address. [visit api](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/renew_fio_address-RenewFIOAddress)
     * - Parameter fioAddress: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction. 
     * - Parameter onCompletion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func renewFioAddress(_ fioAddress: String, maxFee: Int, walletFioAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.RenewFIOAddressResponse? , _ error:FIOError?) -> ()) {
        guard isFIOAddressValid(fioAddress) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Address."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let domain = RenewFIOAddressRequest(fioAddress: fioAddress, maxFee: maxFee, walletFioAddress: walletFioAddress, actor: actor)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.renewFIOAddress,
                            forAction: ChainActions.renewFIOAddress,
                            withBody: domain,
                            code: "fio.address",
                            account: actor) { (data, error) in
                                if let result = data {
                                    let handledData: (response: FIOSDK.Responses.RenewFIOAddressResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                    onCompletion(handledData.response, handledData.error)
                                } else {
                                    if let error = error {
                                        onCompletion(nil, error)
                                    }
                                    else {
                                        onCompletion(nil, FIOError.failure(localizedDescription: "renew_fio_address request failed."))
                                    }
                                }
        }
    }
    
    //MARK: - Register FIO Name request
    
    /**
     * Register a fioName for someone else using that user's public key. CURRENTLY A MOCK!!!!
     * - Parameter fioName: A string to register as FIO Address
     * - Parameter publicKey: User's public key to register FIO name for.
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func registerFIONameOnBehalfOfUser(fioName: String, publicKey: String, onCompletion: @escaping (_ registeredName: RegisterNameForUserResponse? , _ error:FIOError?) -> ()) {
        let registerName = RegisterNameForUserRequest(fioName: fioName, publicKey: publicKey)
        FIOHTTPHelper.postRequestTo(getMockURI() ?? "http://mock.dapix.io/mockd/DEV1/register_fio_name", withBody: registerName) { (result, error) in
            guard let result = result else {
                onCompletion(nil, error)
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(Formatter.iso8601)
                let response = try decoder.decode(RegisterNameForUserResponse.self, from: result)
                onCompletion(response, FIOError.success())
            }catch let error {
                onCompletion(nil, FIOError.failure(localizedDescription: error.localizedDescription))
            }
        }
    }
    
    /**
     * This function should be called to renew a FIO Domain at any time by any user. [visit api](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/renew_fio_domain-RenewFIODomain)
     * - Parameter fioDomain: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     * - Parameter onCompletion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func renewFioDomain(_ fioDomain: String, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.RenewFIODomainResponse? , _ error:FIOError?) -> ()) {
        guard isFIODomainValid(fioDomain) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Domain."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let domain = RenewFIODomainRequest(fioDomain: fioDomain, maxFee: maxFee, walletFioAddress:walletFioAddress, actor: actor)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.renewFIODomain,
                            forAction: ChainActions.renewFIODomain,
                            withBody: domain,
                            code: "fio.address",
                            account: actor) { (data, error) in
                                if let result = data {
                                    let handledData: (response: FIOSDK.Responses.RenewFIODomainResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                    onCompletion(handledData.response, handledData.error)
                                } else {
                                    if let error = error {
                                        onCompletion(nil, error)
                                    }
                                    else {
                                        onCompletion(nil, FIOError.failure(localizedDescription: "renew_fio_domain request failed."))
                                    }
                                }
        }
    }
    
    /**
     * This function should be called to register a new FIO Domain. [visit api](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/register_fio_domain-RegisterFIODomain)
     * - Parameter fioDomain: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter walletFioAddress:
     + FIO Address of the wallet which generates this transaction.
     + This FIO Address will be paid 10% of the fee.
     + See FIO Protocol#TPIDs for details.
     + Set to empty if not known.
     * - Parameter onCompletion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func registerFioDomain(_ fioDomain: String, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.RegisterFIODomainResponse? , _ error:FIOError?) -> ()) {
        guard isFIODomainValid(fioDomain) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Domain."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let domain = RegisterFIODomainRequest(fioDomain: fioDomain, fioPublicKey: "", maxFee: maxFee, walletFioAddress: walletFioAddress, actor: actor)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.registerFIODomain,
                            forAction: ChainActions.registerFIODomain,
                            withBody: domain,
                            code: "fio.address",
                            account: actor) { (data, error) in
                                if let result = data {
                                    let handledData: (response: FIOSDK.Responses.RegisterFIODomainResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                    onCompletion(handledData.response, handledData.error)
                                } else {
                                    if let error = error {
                                        onCompletion(nil, error)
                                    }
                                    else {
                                        onCompletion(nil, FIOError.failure(localizedDescription: "register_fio_domain request failed."))
                                    }
                                }
        }
    }
    
    /**
     * This function should be called to change the visibility of a domain [visit api](https://stealth.atlassian.net/wiki/spaces/DEV/pages/268009622/API+v0.5#APIv0.5-/set_fio_domain_public-SetFIODomain'spublicflag)
     * By default all FIO Domains are non-public, meaning only the owner can register FIO Addresses on that domain. Setting them to public allows anyone to register a FIO Address on that domain.
     * - Parameter fioDomain: The fio domain to set visibility of public or private on
     * - Parameter isPublic: If set to true, anyone can register fio addresses on the domain.  If set to false, only the owner can
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter walletFioAddress:
     + FIO Address of the wallet which generates this transaction.
     + This FIO Address will be paid 10% of the fee.
     + See FIO Protocol#TPIDs for details.
     + Set to empty if not known.
     * - Parameter onCompletion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func setFioDomainVisibility(_ fioDomain: String, isPublic: Bool, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.SetFIODomainVisibilityResponse? , _ error:FIOError?) -> ()) {
        guard isFIODomainValid(fioDomain) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Domain."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let body = SetFIODomainVisibilityRequest(fioDomain: fioDomain, isPublic: (isPublic ? 1 : 0), maxFee: maxFee, tpid: walletFioAddress, actor: actor)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.setFIODomainVisibility,
                            forAction: ChainActions.setFIODomainVisibility,
                            withBody: body,
                            code: "fio.address",
                            account: actor) { (data, error) in
                                if let result = data {
                                    let handledData: (response: FIOSDK.Responses.SetFIODomainVisibilityResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                    onCompletion(handledData.response, handledData.error)
                                } else {
                                    if let error = error {
                                        onCompletion(nil, error)
                                    }
                                    else {
                                        onCompletion(nil, FIOError.failure(localizedDescription: "setFioDomainVisibility request failed."))
                                    }
                                }
        }
    }
    
    /**
     * This function should be called to register a new FIO Address. [visit api](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/register_fio_address-RegisterFIOAddress)
     * - Parameter fioAddress: A string to register as FIO Address
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter walletFioAddress:
     + FIO Address of the wallet which generates this transaction.
     + This FIO Address will be paid 10% of the fee.
     + See FIO Protocol#TPIDs for details.
     + Set to empty if not known.
     * - Parameter onCompletion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func registerFioAddress(_ fioAddress: String, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.RegisterFIOAddressResponse? , _ error:FIOError?) -> ()) {
        guard isFIOAddressValid(fioAddress) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Address."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let body = RegisterFIOAddressRequest(fioAddress: fioAddress, fioPublicKey: "", maxFee: maxFee, tpid: walletFioAddress, actor: actor)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.registerFIOAddress,
                            forAction: ChainActions.registerFIOAddress,
                            withBody: body,
                            code: "fio.address",
                            account: actor) { (data, error) in
                                if let result = data {
                                    let handledData: (response: FIOSDK.Responses.RegisterFIOAddressResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                    onCompletion(handledData.response, handledData.error)
                                } else {
                                    if let error = error {
                                        onCompletion(nil, error)
                                    }
                                    else {
                                        onCompletion(nil, FIOError.failure(localizedDescription: "register_fio_address request failed."))
                                    }
                                }
        }
    }
    
    //MARK: - Add Public Address
    
    /** Register a public address for a tokenCode under a FIO Address.
    * SDK method that calls the addpubaddrs from the fio
    * to read further information about the API visit https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/add_pub_address-Addaddress
    *
    * - Parameter fioAddress: A string name tag in the format of fioaddress.brd.
    * - Parameter tokenCode: The token code of a coin, i.e. BTC, EOS, ETH, etc.
    * - Parameter publicAddress: A string representing the public address for that FIO Address and coin.
    * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    * - Parameter walletFioAddress:
    + FIO Address of the wallet which generates this transaction.
    + This FIO Address will be paid 10% of the fee.
    + See FIO Protocol#TPIDs for details.
    + Set to empty if not known.
    * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
    **/
    public func addPublicAddress(fioAddress: String, tokenCode: String, publicAddress: String, maxFee: Int, walletFioAddress:String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.AddPublicAddressResponse? , _ error:FIOError?) -> ()) {
        guard tokenCode.lowercased() != "fio" else {
            onCompletion(nil, FIOError(kind: .Failure, localizedDescription: "[FIO SDK] FIO Token pub address should not be added manually."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let data = AddPublicAddressRequest(fioAddress: fioAddress, publicAddresses: [PublicAddress(tokenCode: tokenCode, publicAddress: publicAddress)], actor: actor, maxFee: maxFee, walletFioAddress: walletFioAddress)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.addPublicAddress,
                            forAction: ChainActions.addPublicAddress,
                            withBody: data,
                            code: "fio.address",
                            account: actor) { (data, error) in
                                if let result = data {
                                    let handledData: (response: FIOSDK.Responses.AddPublicAddressResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                    onCompletion(handledData.response, handledData.error)
                                } else {
                                    if let error = error {
                                        onCompletion(nil, error)
                                    }
                                    else {
                                        onCompletion(nil, FIOError.failure(localizedDescription: "addpublicaddress request failed."))
                                    }
                                }
        }
    }
    
    //MARK: - Add Public Addresses
    
    /** Register public addresses and tokenCodes under a FIO Address.
    * SDK method that calls the addpubaddrs from the fio
    * to read further information about the API visit https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/add_pub_address-Addaddress
    *
    * - Parameter fioAddress: A string name tag in the format of fioaddress.brd.
    * - Parameter publicAddresses: An array of PublicAddress (tokenCode and token's public address) for that FIO Address
    * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    * - Parameter walletFioAddress:
    + FIO Address of the wallet which generates this transaction.
    + Set to empty if not known.
    * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
    **/
    public func addPublicAddresses(fioAddress: String, publicAddresses:[PublicAddress], maxFee: Int, walletFioAddress:String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.AddPublicAddressResponse? , _ error:FIOError?) -> ()) {
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let data = AddPublicAddressRequest(fioAddress: fioAddress, publicAddresses: publicAddresses, actor: actor, maxFee: maxFee, walletFioAddress: walletFioAddress)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.addPublicAddress,
                            forAction: ChainActions.addPublicAddress,
                            withBody: data,
                            code: "fio.address",
                            account: actor) { (data, error) in
                                if let result = data {
                                    let handledData: (response: FIOSDK.Responses.AddPublicAddressResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                    onCompletion(handledData.response, handledData.error)
                                } else {
                                    if let error = error {
                                        onCompletion(nil, error)
                                    }
                                    else {
                                        onCompletion(nil, FIOError.failure(localizedDescription: "addpublicaddress request failed."))
                                    }
                                }
        }
    }
    
    internal func getCachedABI(accountName: String) -> String{
        return (self._abis[accountName] ?? "")
    }
    
    //MARK: FIO Name Availability
    public func isAvailable(fioName:String, completion: @escaping (_ isAvailable: Bool, _ error:FIOError?) -> ()) {
        let request = AvailCheckRequest(fio_name: fioName)
        let url = ChainRouteBuilder.build(route: ChainRoutes.availCheck)
        FIOHTTPHelper.postRequestTo(url,
            withBody: request) { (data, error) in
                guard let data = data, error != nil else {
                    completion(false, error ?? FIOError.failure(localizedDescription: "isAvailable failed."))
                    return
                }
                do {
                    let response = try JSONDecoder().decode(AvailCheckResponse.self, from: data)
                    completion(!response.isRegistered, FIOError.success())
                }catch let error {
                    completion(false, FIOError.failure(localizedDescription: error.localizedDescription))
                }
        }
    }
    
    //MARK: Get Pending FIO Requests
    
    /// Pending requests call polls for any pending requests sent to a receiver. [visit api specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/get_pending_fio_requests-GetpendingFIORequests)
    ///
    /// - Parameters:
    ///   - fioPublicKey: FIO public key to get pending requests for. (requestee)
    ///   - completion: Completion hanlder
    
    public func getPendingFioRequests(limit:Int?=nil, offset:Int?=0, completion: @escaping (_ pendingRequests: FIOSDK.Responses.PendingFIORequestsResponse?, _ error:FIOError) -> ()) {
        let body = PendingFIORequestsRequest(fioPublicKey: self.publicKey, limit: limit, offset: offset ?? 0)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getPendingFIORequests)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    var result = try JSONDecoder().decode(FIOSDK.Responses.PendingFIORequestsResponse.self, from: data)
                    
                    // filter the dead records
                    result.requests = result.requests.filter { $0.fioRequestId >= 0 }
                    
                    completion(result, FIOError.success())
                }
                catch {
                    completion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError.failure(localizedDescription: ChainRoutes.getPendingFIORequests.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: GetObtDataByTokenCode
    
    /// Gets for any Obt Data sent using public key associated with the FIO SDK instance.
    /// - Parameters:
    ///   - tokenCode Only return Obt Data with this tokenCode (i.e. BTC, ETH, etc..)
    ///   - limit Number of records to return. If omitted, all records will be returned.
    ///   - offset First record from list to return. If omitted, 0 is assumed.
    ///   - completion: Completion handler
    public func getObtDataByTokenCode(tokenCode:String, limit:Int?=nil, offset:Int?=0, completion: @escaping (_ obtDataResponse: FIOSDK.Responses.GetObtDataResponse?, _ error:FIOError) -> ()) {
        
        self.getObtData(limit:limit, offset:offset , completion: { (response, error) in
        
            if (error.kind == FIOError.ErrorKind.Success) {

                if (response != nil){
                    var result = response
                    result?.obtData = response!.obtData.filter { ($0.content.tokenCode.lowercased() == tokenCode.lowercased()) }
                    
                    completion(result, error)
                }
                
            }
            else{
                completion(nil, error)
            }
            
        })
    }
    
    //MARK: GetObtData
    
    /// Gets for any Obt Data sent using public key associated with the FIO SDK instance.
    /// - Parameters:
    ///   - limit Number of records to return. If omitted, all records will be returned.
    ///   - offset First record from list to return. If omitted, 0 is assumed.
    ///   - completion: Completion handler
    public func getObtData(limit:Int?=nil, offset:Int?=0, completion: @escaping (_ obtDataResponse: FIOSDK.Responses.GetObtDataResponse?, _ error:FIOError) -> ()) {
        let body = GetObtDataRequest(fioPublicKey: self.publicKey, limit: limit, offset: offset ?? 0)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getObtData)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    var result = try JSONDecoder().decode(FIOSDK.Responses.GetObtDataResponse.self, from: data)
                    
                    result.obtData = result.obtData.filter { ($0.fioRequestId ?? -1) >= 0 }
                    
                    completion(result, FIOError.success())
                }
                catch {
                    completion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError.failure(localizedDescription: ChainRoutes.getObtData.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Get FIO Names
    
    /// Returns FIO Addresses and FIO Domains owned by given FIO public key.
    ///
    /// - Parameters:
    ///   - FIOPublicKey: FIO public key from which to recover FIO names, if any.
    ///   - completion: Completion handler
    public func getFioNames(fioPublicKey: String, completion: @escaping (_ names: FIOSDK.Responses.FIONamesResponse?, _ error: FIOError?) -> ()){
        let body = FIONamesRequest(fioPublicKey: fioPublicKey)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getFIONames)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.FIONamesResponse.self, from: data)
                    let newestAddresses = result.addresses.sorted(by: { (address, nextAddress) -> Bool in
                        address.expiration > nextAddress.expiration
                    })
                    let newResult = FIOSDK.Responses.FIONamesResponse(domains: result.domains, addresses: newestAddresses)
                    completion(newResult, FIOError.success())
                }
                catch {
                    completion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError.failure(localizedDescription: ChainRoutes.getFIONames.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Single FIO Name
    
    /// Returns details about the FIO address.
    /// - Parameters:
    ///   - fioAddress: FIO Address for which to get details to, e.g. "alice.brd"
    ///   - onCompletion: A FioAddressResponse object containing details.
    public func getFIONameDetails(_ fioAddress: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.FIOAddressResponse?, _ error: FIOError) -> ()) {
        FIOSDK.sharedInstance().getFioNames(fioPublicKey: FIOSDK.sharedInstance().getPublicKey(), completion: { (response, error) in
            guard error?.kind == .Success, let addresses = response?.addresses else {
                onCompletion(nil, error ?? FIOError.failure(localizedDescription: "FIO details not found"))
                return
            }
            guard let result = addresses.first(where: { $0.address == fioAddress }) else {
                onCompletion(nil, FIOError.failure(localizedDescription: "FIO details not found"))
                return
            }
            onCompletion(result, error ?? FIOError.success())
        })
    }    
    
    //MARK: Public Address Lookup
    
    /// Returns a public address for a specified FIO Address, based on a given token for example ETH. [visit the API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/pub_address_lookup-FIOAddresslookup)
    /// example response:
    /// ```
    /// // example response
    /// let result: [String: String] =  ["pub_address": "0xab5801a7d398351b8be11c439e05c5b3259aec9b", "token_code": "ETH", "fio_address": "purse.alice"]
    /// ```
    ///
    /// - Parameters:
    ///   - fioAddress: FIO Address for which public address is to be returned, e.g. "alice.brd"
    ///   - tokenCode: Token code for which public address is to be returned, e.g. "ETH".
    ///   - completion: result based on DTO PublicAddressResponse
    public func getPublicAddress(fioAddress: String, tokenCode: String, completion: @escaping (_ publicAddress: FIOSDK.Responses.PublicAddressResponse?, _ error: FIOError) -> ()){
        let body = PublicAddressRequest(fioAddress: fioAddress, tokenCode: tokenCode)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getPublicAddress)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.PublicAddressResponse.self, from: data)
                    completion(result, FIOError.success())
                }
                catch {
                    completion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError.failure(localizedDescription: ChainRoutes.getPublicAddress.rawValue + " request failed."))
                }
            }
        }
    }
    
    public func getFIOPublicKey(fioAddress: String, completion: @escaping (_ publicAddress: FIOSDK.Responses.PublicAddressResponse?, _ error: FIOError) -> ()){
        getPublicAddress(fioAddress: fioAddress, tokenCode: "FIO", completion: completion)
    }
    //
    
    /// Returns a public address for the specified token registered under a FIO public key.
    /// - Parameters:
    ///   - forToken: Token code for which public address is to be returned, e.g. "ETH".
    ///   - fioPublicKey: FIO public Key under which the token was registered.
    ///   - onCompletion: A TokenPublicAddressResponse containing FIO address and public address.
    public func getPublicAddress(fioPublicKey: String, tokenCode: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.TokenPublicAddressResponse?, _ error: FIOError) -> ()) {
        FIOSDK.sharedInstance().getFioNames(fioPublicKey: fioPublicKey) { (response, error) in
            guard error == nil || error?.kind == .Success, let fioAddress = response?.addresses.first?.address else {
                onCompletion(nil, error ?? FIOError.failure(localizedDescription: "Failed to retrieve token public address."))
                return
            }
            FIOSDK.sharedInstance().getPublicAddress(fioAddress: fioAddress, tokenCode: tokenCode) { (response, error) in
                guard error.kind == .Success, let tokenPubAddress = response?.publicAddress else {
                    onCompletion(nil, error)
                    return
                }
                onCompletion(FIOSDK.Responses.TokenPublicAddressResponse(fioAddress: fioAddress, tokenPublicAddress: tokenPubAddress) , FIOError.success())
            }
        }
    }
    
    internal func encrypt(publicKey: String, contentType: FIOAbiContentType, contentJson: String) -> String{
        guard let privateKey = try! PrivateKey(keyString: self.privateKey) else {
            return ""
        }
        
        let sharedSecret = privateKey.getSharedSecret(publicKey: publicKey)
               
        let serializer = abiSerializer()
        let packed = try? serializer.serializeContent(contentType: contentType, json: contentJson)

        guard let encrypted = Cryptography().encrypt(secret: sharedSecret ?? "", message: packed ?? "", iv: nil) else {
           return ""
        }
               
        return encrypted.hexEncodedString().uppercased()
    }
    
    internal func decrypt(publicKey: String, contentType: FIOAbiContentType, encryptedContent: String) -> String{
        guard let myKey = try! PrivateKey(keyString: self.privateKey) else {
           return ""
        }
        
        if (encryptedContent.isValidHex() ==  false) {
            return ""
        }
        
        let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)

        var possibleDecrypted: Data?
        do {
            possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: encryptedContent.toHexData())
        }
        catch {
            return ""
        }
        guard let decrypted = possibleDecrypted  else {
            return ""
        }

        let serializer = abiSerializer()
        let contentJSON = try? serializer.deserializeContent(contentType: contentType, hexString: decrypted.hexEncodedString().uppercased() ?? "")

        return contentJSON ?? ""
    }
    
    //MARK: - Request Funds
    
    /// Creates a new funds request.
    /// To read further infomation about this [visit the API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/new_funds_request-Createnewfundsrequest)
    /// Note: requestor is sender, requestee is receiver
    ///
    /// - Parameters:
    ///   - payerFIOAddress: FIO Address of the payer. This address will receive the request and will initiate payment, i.e. requestee:brd
    ///   - payeeFIOAddress: FIO Address of the payee. This address is sending the request and will receive payment, i.e. requestor:brd
    ///   - payeePublicAddress: Payee's public address where they want funds sent.
    ///   - amount: Amount requested.
    ///   - tokenCode: Code of the token represented in Amount requested, i.e. ETH
    ///   - metadata: Contains the: memo or hash or offlineUrl
    ///   - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///   - onCompletion: The completion handler containing the result
    public func requestFunds(payer payerFIOAddress:String, payee payeeFIOAddress: String, payeePublicAddress: String, amount: Float, tokenCode: String, metadata: RequestFundsRequest.MetaData, maxFee: Int, walletFioAddress:String = "", onCompletion: @escaping ( _ response: RequestFundsResponse?, _ error:FIOError? ) -> ()) {
       
        self.getFIOPublicKey(fioAddress: payerFIOAddress) { (response, error) in

            if (error.kind == FIOError.ErrorKind.Success) {
                
                let contentJson = RequestFundsContent(payeePublicAddress: payeePublicAddress, amount: String(amount), tokenCode: tokenCode, memo:metadata.memo ?? "", hash: metadata.hash ?? "", offlineUrl: metadata.offlineUrl ?? "")
                
                let encryptedContent = self.encrypt(publicKey: response?.publicAddress ?? "", contentType: FIOAbiContentType.newFundsContent, contentJson: contentJson.toJSONString())
                
                let actor = AccountNameGenerator.run(withPublicKey: self.getPublicKey())
                let data = RequestFundsRequest(payerFIOAddress: payerFIOAddress, payeeFIOAddress: payeeFIOAddress, content:encryptedContent, maxFee: maxFee, tpid: walletFioAddress, actor: actor)
                
                signedPostRequestTo(privateKey: self.getPrivateKey(),
                                   route: ChainRoutes.newFundsRequest,
                                   forAction: ChainActions.newFundsRequest,
                                   withBody: data,
                                   code: "fio.reqobt",
                                   account: actor) { (result, error) in
                                       guard let result = result else {
                                           onCompletion(nil, error)
                                           return
                                       }
                                       let handledData: (response: RequestFundsResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                       onCompletion(handledData.response, handledData.error)
                       }
            }
            else {
                onCompletion(nil, FIOError.init(kind: .Failure, localizedDescription: "Payer FIO Public Address not found"))
            }
        }

    }
    
    //MARK: - Reject Funds
    
    /// Reject funds request.
    /// To read further infomation about this [visit the API specs] [1]
    ///
    ///    [1]: https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/reject_funds_request-Rejectfundsrequest "api specs"
    ///
    /// - Parameters:
    ///   - fioRequestId: ID of that fund request.
    ///   - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///   - walletFioAddress: FIO Address of the wallet which generates this transaction.
    ///   - completion: The completion handler containing the result or error.
    public func rejectFundsRequest(fioRequestId: Int, maxFee: Int, walletFioAddress: String = "", completion: @escaping(_ response: FIOSDK.Responses.RejectFundsRequestResponse?,_ :FIOError) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey:getPublicKey())
        let data = RejectFundsRequest(fioRequestId: fioRequestId, maxFee: maxFee, walletFioAddress: walletFioAddress, actor: actor)
        
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.rejectFundsRequest,
                            forAction: ChainActions.rejectFundsRequest,
                            withBody: data,
                            code: "fio.reqobt",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    completion(nil, error ?? FIOError.init(kind: .Failure, localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                let handledData: (response: FIOSDK.Responses.RejectFundsRequestResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                guard handledData.response?.status == .rejected else {
                                    completion(nil, FIOError.failure(localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                completion(handledData.response, FIOError.success())
        }
    }
    
    //MARK: Get Sent FIO Requests
    
    /// Get all requests sent by the given FIO public key. Usually made with requestFunds.
    /// To read further infomation about this [visit the API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/get_sent_fio_requests-GetFIORequestssentout)
    /// - Parameters:
    ///   - fioPublicKey: FIO public key to retrieve sent requests.
    ///   - completion: The completion result
    public func getSentFioRequests(limit:Int?=nil, offset:Int?=0, completion: @escaping (_ response: FIOSDK.Responses.SentFIORequestsResponse?, _ error: FIOError) -> ()){
        let body = SentFIORequestsRequest(fioPublicKey: self.publicKey, limit: limit, offset: offset ?? 0)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getSentFIORequests)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    var result = try JSONDecoder().decode(FIOSDK.Responses.SentFIORequestsResponse.self, from: data)
                    
                    // filter the dead records
                    result.requests = result.requests.filter { $0.fioRequestId >= 0 }
                    
                    completion(result, FIOError.success())
                }
                catch {
                    completion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError.failure(localizedDescription: ChainRoutes.getSentFIORequests.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Record Send

    /// Record a transation on another blockhain (OBT: other block chain transaction). Should be called after any transaction if recordSendAutoResolvingWith is not called. [visit api specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/record_send-Recordssendonanotherblockchain)
    ///
    /// - Parameters:
    ///     - fioRequestId: The FIO request ID to register the transaction for. Only required when approving transaction request.
    ///     - payerFIOAddress: FIO Address of the payer. This address initiated payment. (requestor)
    ///     - payeeFIOAddress: FIO Address of the payee. This address is receiving payment. (requestee)
    ///     - payerTokenPublicAddress: Public address on other blockchain of user sending funds. (requestor)
    ///     - payeeTokenPublicAddress: Public address on other blockchain of user receiving funds. (requestee)
    ///     - amount: The value being sent.
    ///     - tokenCode: Token code i.e. BTC, ETH, etc.
    ///     - obtId: The transaction ID (OBT) representing the transaction from one blockchain to another one.
    ///     - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///     - metaData: memo, hash, offlineURL options
    ///     - walletFioAddress: FIO Address of the wallet which generates this transaction.
    ///     - onCompletion: Once finished this callback returns optional response and error.
    public func recordObtData(fioRequestId: Int? = nil,
                           payerFIOAddress: String,
                           payeeFIOAddress: String,
                           payerTokenPublicAddress: String,
                           payeeTokenPublicAddress: String,
                           amount: Double,
                           tokenCode: String,
                           obtId: String,
                           maxFee: Int,
                           metaData: RecordObtDataRequest.MetaData,
                           walletFioAddress: String = "",
                           onCompletion: @escaping (_ response: FIOSDK.Responses.RecordObtDataResponse?, _ error: FIOError?) -> ()){
        
        let contentJson = RecordObtDataContent(payerPublicAddress: payerTokenPublicAddress, payeePublicAddress: payeeTokenPublicAddress, amount: String(amount), tokenCode: tokenCode, status:"sent_to_blockchain", obtId: obtId, memo: metaData.memo ?? "", hash: metaData.hash ?? "", offlineUrl: metaData.offlineUrl ?? "")
        
        FIOSDK.sharedInstance().getFIOPublicKey(fioAddress: payeeFIOAddress) { (response, error) in
            guard error.kind == .Success, let payeeFIOPublicKey = response?.publicAddress else {
                onCompletion(nil, error)
                return
            }
        
            let encryptedContent = self.encrypt(publicKey: payeeFIOPublicKey, contentType: FIOAbiContentType.recordObtDataContent, contentJson: contentJson.toJSONString())
            
            let actor = AccountNameGenerator.run(withPublicKey: self.getPublicKey())
            var fioReqId = ""
            if (fioRequestId != nil){
                fioReqId = String(fioRequestId ?? 0)
            }
            
            let request = RecordObtDataRequest(payerFIOAddress: payerFIOAddress, payeeFIOAddress: payeeFIOAddress, content: encryptedContent, fioRequestId: fioReqId, maxFee: maxFee, walletFioAddress: walletFioAddress, actor: actor)
            
            signedPostRequestTo(privateKey: self.getPrivateKey(),
                                route: ChainRoutes.recordObtData,
                                forAction: ChainActions.recordObtData,
                                withBody: request,
                                code: "fio.reqobt",
                                account: actor) { (result, error) in
                                    guard let result = result else {
                                        onCompletion(nil, error ?? FIOError.failure(localizedDescription: "recordObtData send failed"))
                                        return
                                    }
                                    let handledData: (response: FIOSDK.Responses.RecordObtDataResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                    onCompletion(handledData.response, FIOError.success())
            }
        }
    }
    
    //MARK: Get FIO Balance
    
    /// Retrieves balance of FIO tokens. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/get_fio_balance-GetFIObalance)
    /// - Parameters:
    ///     - onCompletion: A function that is called once request is over with an optional response that should contain balance and error containing the status of the call.
    public func getFIOBalance(onCompletion: @escaping (_ response: FIOSDK.Responses.FIOBalanceResponse?, _ error: FIOError) -> ()){
        FIOSDK.sharedInstance().getFIOBalance(fioPublicKey: FIOSDK.sharedInstance().getPrivateKey(), onCompletion: { (resp, err) in
            onCompletion(resp, err)
            return
        })
    }
    
    /// Retrieves balance of FIO tokens. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/get_fio_balance-GetFIObalance)
    /// - Parameters:
    ///     - fioPublicKey: The FIO public key to get FIO tokens balance for.
    ///     - onCompletion: A function that is called once request is over with an optional response that should contain balance and error containing the status of the call.
    public func getFIOBalance(fioPublicKey: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FIOBalanceResponse?, _ error: FIOError) -> ()){
        let body = FIOBalanceRequest(fioPublicKey: fioPublicKey)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getFIOBalance)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.FIOBalanceResponse.self, from: data)
                    onCompletion(result, FIOError.success())
                }
                catch {
                    onCompletion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    onCompletion(nil, error)
                }
                else {
                    onCompletion(nil, FIOError.failure(localizedDescription: ChainRoutes.getFIOBalance.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Transfer Tokens
    
    /**
     * Transfers FIO tokens. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/transfer_tokens_pub_key-TransferFIOtokens)
     * - Parameter payeePublicKey: The receiver public key.
     * - Parameter amount: The value in SUFs that will be transfered from the calling account to the especified account.
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     * - Parameter onCompletion: A function that is called once request is over with an optional response with results and error containing the status of the call.
     */
    public func transferFIOTokens(payeePublicKey: String, amount: Int, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.TransferFIOTokensResponse?, _ error: FIOError) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let transfer = TransferFIOTokensRequest (payeePublicKey: payeePublicKey, amount: amount, maxFee: maxFee, walletFioAddress: walletFioAddress, actor: actor)
        signedPostRequestTo(privateKey: getPrivateKey(),
            route: ChainRoutes.transferTokens,
            forAction: ChainActions.transferTokens,
            withBody: transfer,
            code: "fio.token",
            account: actor) { (result, error) in
                guard let result = result else {
                    onCompletion(nil, error ?? FIOError.failure(localizedDescription: "\(ChainActions.transferTokens.rawValue) call failed."))
                    return
                }
                let handledData: (response: FIOSDK.Responses.TransferFIOTokensResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                onCompletion(handledData.response, FIOError.success())
        }
    }
    
    //MARK: Get Fee
    /// Compute and return fee amount for specific call and specific user. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/get_fee-Computeandreturnfeeamountforspecificcallandspecificuser)
    /// - Parameters:
    ///     - endPoint: Name of API call end point, e.g. register_fio_domain
    ///     - onCompletion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    public func getFee(endPoint: FIOSDK.Params.FeeEndpoint, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: "", endPoint: endPoint.rawValue, onCompletion: onCompletion)
    }
    
    /// Compute and return fee amount for specific call and specific user. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/get_fee-Computeandreturnfeeamountforspecificcallandspecificuser)
    /// - Parameters:
    ///     - body: FeeRequest Object
    ///     - onCompletion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    internal func getFeeResponse(fioAddress: String, endPoint: String,  onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        let body = FeeRequest(fioAddress: fioAddress, endPoint: endPoint)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getFee)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.FeeResponse.self, from: data)
                    onCompletion(result, FIOError.success())
                }
                catch {
                    onCompletion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    onCompletion(nil, error)
                }
                else {
                    onCompletion(nil, FIOError.failure(localizedDescription: ChainRoutes.getFee.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: getFeeForAddPublicAddress
    
    /// Compute and return fee amount for specific call and specific user. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/get_fee-Computeandreturnfeeamountforspecificcallandspecificuser)
    /// - Parameters:
    ///     - fioAddress: FIO Address incurring the fee and owned by signer.
    ///     - onCompletion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    public func getFeeForAddPublicAddress(fioAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: fioAddress, endPoint: "add_pub_address", onCompletion: onCompletion)
    }
    
    //MARK: getFeeForNewFundsRequest
    
    /// Compute and return fee amount for specific call and specific user. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/get_fee-Computeandreturnfeeamountforspecificcallandspecificuser)
    /// - Parameters:
    ///     - payeePublicAddress: Payee Public Address
    ///     - onCompletion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    public func getFeeForNewFundsRequest(payeePublicAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: payeePublicAddress, endPoint: "new_funds_request", onCompletion: onCompletion)
    }
    
    //MARK: getFeeForRejectFundsRequest
    
    /// Compute and return fee amount for specific call and specific user. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/get_fee-Computeandreturnfeeamountforspecificcallandspecificuser)
    /// - Parameters:
    ///     - payeePublicAddress: Payee Public Address from corresponding FIO Request
    ///     - onCompletion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    public func getFeeForRejectFundsRequest(payeePublicAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: payeePublicAddress, endPoint: "reject_funds_request", onCompletion: onCompletion)
    }
    
    //MARK: getFeeForRecordSend
    
    /// Compute and return fee amount for specific call and specific user. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/265977939/API+v0.3#APIv0.3-/get_fee-Computeandreturnfeeamountforspecificcallandspecificuser)
    /// - Parameters:
    ///     - payerFioAddress: Payer Fio Address
    ///     - onCompletion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    public func getFeeForRecordObtData(payerFioAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: payerFioAddress, endPoint: "record_obt_data", onCompletion: onCompletion)
    }

}

#warning("does this do anything, valid?")
extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}
