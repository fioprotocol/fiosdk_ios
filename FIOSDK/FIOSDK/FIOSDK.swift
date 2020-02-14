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
    
    /**
     * This is the Singleton for the FIOSDK.  Initialize it with these parameters.
     * - Parameter privateKey: the fio private key of the client sending requests to FIO API.
     * - Parameter publicKey: the fio public key of the client sending requests to FIO API.
     * - Parameter url: the url to the FIO API.
     * - Parameter mockUrl: This is the mock url used for the registerFioNameOnBehalfOfUser call.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.  Set to empty if not known.
     */
    public class func sharedInstance(privateKey:String? = nil, publicKey:String? = nil, url:String? = nil, mockUrl: String? = nil, walletFioAddress: String? = nil) -> FIOSDK {
        
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
        
        if (walletFioAddress != nil){
            _sharedInstance.walletFioAddress = walletFioAddress ?? ""
        }
        
        // populate the abis
        let abi = _sharedInstance.getCachedABI(accountName: "fio.address")
        if (abi.count < 2){
            _sharedInstance.populateABIs()
        }
        
        return _sharedInstance
    }
    
    //MARK: FIO Name validation
    // Is the fio name valid?
    public func isFioNameValid(fioName: String) -> Bool{
        if fioName.contains("@") {
            return isFIOAddressValid(fioName)
        }
        return isFIODomainValid(fioName)
    }
    
    //MARK: Private and Public Key Pairs
    /**
     * Generate a private and public key pair.
     * This method creates a private and public key based on a mnemonic, it does store both keys in keychain. To be used by the FIOSDK sharedInstance() Singleton
     * - Parameter mnemonic: The text to use in key pair generation.
     * - Return: A tuple containing both private and public keys to be used by the FIOSDK sharedInstance() Singleton.
     */
    static public func privatePublicKeyPair(forMnemonic mnemonic: String) -> (privateKey: String, publicKey: String) {
        return keyManager.privatePublicKeyPair(mnemonic: mnemonic)
    }
    
    /**
     * This method removes private and public keys from the keychain. It may throw keychain access errors while doing so.
     * - throws: throw keychain access errors
     */
    static public func wipePrivatePublicKeys() throws {
        try keyManager.wipeKeys()
    }
    
    //MARK: - Renew FIO address
    /**
     * This function should be called to renew a FIO Address.
     * - Parameter fioAddress: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func renewFioAddress(_ fioAddress: String, maxFee: Int, onCompletion: @escaping (_ response: FIOSDK.Responses.RenewFIOAddressResponse? , _ error:FIOError?) -> ()) {
        renewFioAddress(fioAddress, maxFee: maxFee, walletFioAddress: "", onCompletion: onCompletion)
    }
    
    /**
     * This function should be called to renew a FIO Address.
     * - Parameter fioAddress: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func renewFioAddress(_ fioAddress: String, maxFee: Int, walletFioAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.RenewFIOAddressResponse? , _ error:FIOError?) -> ()) {
        guard isFIOAddressValid(fioAddress) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Address."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let domain = RenewFIOAddressRequest(fioAddress: fioAddress, maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress), actor: actor)
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
    
    //MARK: - Register FIO Name On Behalf of User
    /**
     * Register a fioName for someone else using that user's public key. CURRENTLY A MOCK!!!!
     * - Parameter fioName: Name to register as FIO Address
     * - Parameter publicKey: User's public key to register FIO name for.
     * - Parameter onCompletion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func registerFIONameOnBehalfOfUser(fioName: String, publicKey: String, onCompletion: @escaping (_ registeredName: RegisterNameForUserResponse? , _ error:FIOError?) -> ()) {
        let registerName = RegisterNameForUserRequest(fioName: fioName, publicKey: publicKey)
        FIOHTTPHelper.postRequestTo(getMockURI() ?? "", withBody: registerName) { (result, error) in
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
    
    //MARK: Renew Fio Domain
    /**
     * This method should be called to renew a FIO Domain at any time, by any user.
     * - Parameter fioDomain: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func renewFioDomain(_ fioDomain: String, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.RenewFIODomainResponse? , _ error:FIOError?) -> ()) {
        guard isFIODomainValid(fioDomain) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Domain."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let domain = RenewFIODomainRequest(fioDomain: fioDomain, maxFee: maxFee, walletFioAddress:self.getWalletFioAddress(walletFioAddress), actor: actor)
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
     * This method should be called to register a new FIO Domain.
     * - Parameter fioDomain: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func registerFioDomain(_ fioDomain: String, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.RegisterFIODomainResponse? , _ error:FIOError?) -> ()) {
        guard isFIODomainValid(fioDomain) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Domain."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let domain = RegisterFIODomainRequest(fioDomain: fioDomain, fioPublicKey: "", maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress), actor: actor)
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
    
    //MARK: Fio Domain Visibility
    /**
     * This method should be called to change the visibility of a domain.
     * By default all FIO Domains are non-public, meaning only the owner can register FIO Addresses on that domain. Setting them to public allows anyone to register a FIO Address on that domain.
     * - Parameter fioDomain: The fio domain to set visibility of public or private on
     * - Parameter isPublic: If set to true, anyone can register fio addresses on the domain.  If set to false, only the owner can
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func setFioDomainVisibility(_ fioDomain: String, isPublic: Bool, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.SetFIODomainVisibilityResponse? , _ error:FIOError?) -> ()) {
        guard isFIODomainValid(fioDomain) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Domain."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let body = SetFIODomainVisibilityRequest(fioDomain: fioDomain, isPublic: (isPublic ? 1 : 0), maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress), actor: actor)
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
    
    //MARK: Register FIO Address
    /**
     * This method should be called to register a new FIO Address.
     * - Parameter fioAddress: A string to register as FIO Address
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func registerFioAddress(_ fioAddress: String, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.RegisterFIOAddressResponse? , _ error:FIOError?) -> ()) {
        guard isFIOAddressValid(fioAddress) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Address."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let body = RegisterFIOAddressRequest(fioAddress: fioAddress, fioPublicKey: "", maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress), actor: actor)
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
    
    /** Adds a public address of the specific token to the FIO Address.
    *
    * - Parameter fioAddress: FIO Address to add the public address to.
    * - Parameter chainCode: Blockchain code for blockchain hosting this token.
    * - Parameter tokenCode: The token code of a coin, i.e. BTC, EOS, ETH, etc.
    * - Parameter publicAddress: The public address for the specified token.
    * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
    * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
    + Set to empty if not known.
    + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
    * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
    **/
    public func addPublicAddress(fioAddress: String, chainCode: String, tokenCode: String, publicAddress: String, maxFee: Int, walletFioAddress:String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.AddPublicAddressResponse? , _ error:FIOError?) -> ()) {
        
        // validation
        guard chainCode.lowercased() != "fio" else {
            onCompletion(nil, FIOError(kind: .Failure, localizedDescription: "The FIO TokenCode should not be added using this method.  It is associated with the FIO Public Address at fio address registration."))
            return
        }
        if (!self.isChainCodeValid(chainCode)){
            onCompletion(nil, FIOError(kind: .Failure, localizedDescription: "The chainCode is not valid.  Needs to have 1 character or a maximum of 10 characters.  Must be a-z0-9"))
            return
        }
        if (!self.isTokenCodeValid(tokenCode)){
            onCompletion(nil, FIOError(kind: .Failure, localizedDescription:  "The tokenCode is not valid.  Needs to have 1 character or a maximum of 10 characters.  Must be a-z0-9"))
            return
        }
        if (!self.isPublicAddressValid(publicAddress)){
            onCompletion(nil, FIOError(kind: .Failure, localizedDescription:  "The publicAddress is not valid.  Needs to have 1 character or a maximum of 128 characters."))
            return
        }
        
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let data = AddPublicAddressRequest(fioAddress: fioAddress, publicAddresses: [PublicAddress(chainCode: chainCode, tokenCode: tokenCode, publicAddress: publicAddress)], actor: actor, maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress))
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
    
    /** Adds public addressess for specific tokens to the FIO Address.
    *
    * - Parameter fioAddress: A string name tag in the format of fioaddress.brd.
    * - Parameter publicAddresses: An array of PublicAddress (tokenCode and token's public address) for that FIO Address
    * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
    * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
    + Set to empty if not known.
    + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
    * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
    **/
    public func addPublicAddresses(fioAddress: String, publicAddresses:[PublicAddress], maxFee: Int, walletFioAddress:String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.AddPublicAddressResponse? , _ error:FIOError?) -> ()) {
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let data = AddPublicAddressRequest(fioAddress: fioAddress, publicAddresses: publicAddresses, actor: actor, maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress))
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
    
    //MARK: getCachedABI
    internal func getCachedABI(accountName: String) -> String{
        return (self._abis[accountName] ?? "")
    }
    
    //MARK: isAvailable?
    
    /** Is the Fio Name Available?
     *
     * - Parameter fioName: Is the fio address or fio domain available?
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func isAvailable(fioName:String, onCompletion: @escaping (_ isAvailable: Bool, _ error:FIOError?) -> ()) {
        let request = AvailCheckRequest(fio_name: fioName)
        let url = ChainRouteBuilder.build(route: ChainRoutes.availCheck)
        FIOHTTPHelper.postRequestTo(url,
            withBody: request) { (data, error) in
                guard let data = data, error != nil else {
                    onCompletion(false, error ?? FIOError.failure(localizedDescription: "isAvailable failed."))
                    return
                }
                do {
                    let response = try JSONDecoder().decode(AvailCheckResponse.self, from: data)
                    onCompletion(!response.isRegistered, FIOError.success())
                }catch let error {
                    onCompletion(false, FIOError.failure(localizedDescription: error.localizedDescription))
                }
        }
    }
    
    //MARK: Get Pending FIO Requests
    
    /** Get Pending FIO Requests for the payer
     *
     * - Parameter limit: Number of request to return. If omitted, all requests will be returned.
     * - Parameter offset: First request from list to return. If omitted, 0 is assumed.
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getPendingFioRequests(limit:Int?=nil, offset:Int?=0, onCompletion: @escaping (_ pendingRequests: FIOSDK.Responses.PendingFIORequestsResponse?, _ error:FIOError) -> ()) {
        let body = PendingFIORequestsRequest(fioPublicKey: self.publicKey, limit: limit, offset: offset ?? 0)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getPendingFIORequests)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    var result = try JSONDecoder().decode(FIOSDK.Responses.PendingFIORequestsResponse.self, from: data)
                    
                    // filter the dead records
                    result.requests = result.requests.filter { $0.fioRequestId >= 0 }
                    
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
                    onCompletion(nil, FIOError.failure(localizedDescription: ChainRoutes.getPendingFIORequests.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: GetObtData
    
    /** Get ObtData associated with the public key of this FIO SDK instance.
     *
     * - Parameter tokenCode: Filter the ObtData returned, by the tokenCode (i.e. BTC, ETH)
     * - Parameter limit: Number of obtData records to return. If omitted, all records will be returned.
     * - Parameter offset: First record from list to return. If omitted, 0 is assumed.
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getObtDataByTokenCode(tokenCode:String, limit:Int?=nil, offset:Int?=0, onCompletion: @escaping (_ obtDataResponse: FIOSDK.Responses.GetObtDataResponse?, _ error:FIOError) -> ()) {
        
        self.getObtData(limit:limit, offset:offset , onCompletion: { (response, error) in
        
            if (error.kind == FIOError.ErrorKind.Success) {

                if (response != nil){
                    var result = response
                    result?.obtData = response!.obtData.filter { ($0.content.tokenCode.lowercased() == tokenCode.lowercased()) }
                    
                    onCompletion(result, error)
                }
                
            }
            else{
                onCompletion(nil, error)
            }
            
        })
    }
    
    /** Returns ObtData associated with the public key of this FIO SDK instance.
     *
     * - Parameter limit: Number of obtData records to return. If omitted, all records will be returned.
     * - Parameter offset: First record from list to return. If omitted, 0 is assumed.
     * - Parameter onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getObtData(limit:Int?=nil, offset:Int?=0, onCompletion: @escaping (_ obtDataResponse: FIOSDK.Responses.GetObtDataResponse?, _ error:FIOError) -> ()) {
        let body = GetObtDataRequest(fioPublicKey: self.publicKey, limit: limit, offset: offset ?? 0)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getObtData)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    var result = try JSONDecoder().decode(FIOSDK.Responses.GetObtDataResponse.self, from: data)
                    
                    result.obtData = result.obtData.filter { ($0.fioRequestId ?? -1) >= 0 }
                    
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
                    onCompletion(nil, FIOError.failure(localizedDescription: ChainRoutes.getObtData.rawValue + " request failed."))
                }
            }
        }
    }

    //MARK: Get FIO Names
    
    /** Returns FIO Addresses and FIO Domains owned by given FIO public key.
     *
     * - Parameter fioPublicKey: FIO public key of owner.
     * - Parameter onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFioNames(fioPublicKey: String, onCompletion: @escaping (_ names: FIOSDK.Responses.FIONamesResponse?, _ error: FIOError?) -> ()){
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
                    onCompletion(newResult, FIOError.success())
                }
                catch {
                    onCompletion(nil, FIOError.failure(localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    onCompletion(nil, error)
                }
                else {
                    onCompletion(nil, FIOError.failure(localizedDescription: ChainRoutes.getFIONames.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Get FIO Address Details
    
    /** Returns details about the FIO address.
     *
     * - Parameter fioPublicKey: FIO public key of owner.
     * - Parameter fioAddress: FIO Address for which to get details to, e.g. "alice@brd"
     * - Parameter onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFioAddressDetails(_ fioPublicKey:String, fioAddress: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.FIOAddressResponse?, _ error: FIOError) -> ()) {
        FIOSDK.sharedInstance().getFioNames(fioPublicKey: fioPublicKey, onCompletion: { (response, error) in
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
    
    /** Returns details about the FIO address.  For the address associated with the FIO public key of the FIOSDK sharedInstance (Singleton).
     *
     * - Parameter fioAddress: FIO Address for which to get details to, e.g. "alice@brd"
     * - Parameter onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFioAddressDetails(_ fioAddress: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.FIOAddressResponse?, _ error: FIOError) -> ()) {
        FIOSDK.sharedInstance().getFioAddressDetails(FIOSDK.sharedInstance().publicKey, fioAddress:fioAddress) { (response, error) in
            onCompletion(response, error)
        }
    }
    
    //MARK: Get Public Address
    
    /** Returns a public address for the specified token registered under a FIO public key.
     *
     * - Parameter fioPublicKey: FIO public key of owner.
     * - Parameter chainCode: Blockchain code for blockchain hosting this token.
     * - Parameter tokenCode: tokenCode of the public address to, (i.e. BTC, ETH)
     * - Parameter onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getPublicAddress(fioPublicKey: String, chainCode: String, tokenCode: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.TokenPublicAddressResponse?, _ error: FIOError) -> ()) {
        FIOSDK.sharedInstance().getFioNames(fioPublicKey: fioPublicKey) { (response, error) in
            guard error == nil || error?.kind == .Success, let fioAddress = response?.addresses.first?.address else {
                onCompletion(nil, error ?? FIOError.failure(localizedDescription: "Failed to retrieve token public address."))
                return
            }
            FIOSDK.sharedInstance().getPublicAddress(fioAddress: fioAddress, chainCode: chainCode, tokenCode: tokenCode) { (response, error) in
                guard error.kind == .Success, let tokenPubAddress = response?.publicAddress else {
                    onCompletion(nil, error)
                    return
                }
                onCompletion(FIOSDK.Responses.TokenPublicAddressResponse(fioAddress: fioAddress, tokenPublicAddress: tokenPubAddress) , FIOError.success())
            }
        }
    }
    
    /** Returns a public address for a specified FIO Address, for a given token (i.e. BTC, ETH)
     *
     * - Parameter fioAddress: FIO Address associated with the public address being retrieved, e.g. "alice@brd"
     * - Parameter chainCode: Blockchain code for blockchain hosting this token.
     * - Parameter tokenCode: tokenCode of the public address to, (i.e. BTC, ETH)
     * - Parameter onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getPublicAddress(fioAddress: String, chainCode: String, tokenCode: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.PublicAddressResponse?, _ error: FIOError) -> ()){
        let body = PublicAddressRequest(fioAddress: fioAddress, chainCode: chainCode, tokenCode: tokenCode)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getPublicAddress)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.PublicAddressResponse.self, from: data)
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
                    onCompletion(nil, FIOError.failure(localizedDescription: ChainRoutes.getPublicAddress.rawValue + " request failed."))
                }
            }
        }
    }
    
    /** Returns the FIO PublicKey, associated with the FIO address.
     *
     * - Parameter fioAddress: FIO Address for which to get details to, e.g. "alice@brd"
     * - Parameter onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFioPublicKey(fioAddress: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.PublicAddressResponse?, _ error: FIOError) -> ()){
        getPublicAddress(fioAddress: fioAddress, chainCode: "FIO", tokenCode: "FIO", onCompletion: onCompletion)
    }
    
    //MARK: Encrypt/Decrypt
    
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
        
        return  encrypted.base64EncodedString()
    }
    
    internal func decrypt(publicKey: String, contentType: FIOAbiContentType, encryptedContent: String) -> String{
        guard let myKey = try! PrivateKey(keyString: self.privateKey) else {
           return ""
        }
        
        if let decodedContentData = Data(base64Encoded: encryptedContent) {
            
            let sharedSecret = myKey.getSharedSecret(publicKey: publicKey)

            var possibleDecrypted: Data?
            do {
                possibleDecrypted = try Cryptography().decrypt(secret: sharedSecret!, message: decodedContentData)
            }
            catch {
                return ""
            }
            guard let decrypted = possibleDecrypted  else {
                return ""
            }

            let serializer = abiSerializer()
            let contentJSON = try? serializer.deserializeContent(contentType: contentType, hexString: decrypted.hexEncodedString().uppercased())

            return contentJSON ?? ""

        } else {
            return ""
        }
        
    }
    
    //MARK: - Request Funds
    
    /** Creates a new funds request
     *
     * - Parameter payerFIOAddress: FIO Address of the payer. This address will receive the request and will initiate payment, i.e. requestee:brd
     * - Parameter payeeFIOAddress: FIO Address of the payee. This address is sending the request and will receive payment, i.e. requestor:brd
     * - Parameter payeePublicAddress: Payee's public address where they want funds sent.
     * - Parameter amount: Amount requested.
     * - Parameter chainCode: Blockchain code for blockchain hosting this token.
     * - Parameter tokenCode: Code of the token represented in Amount requested, i.e. ETH
     * - Parameter metadata: Contains the: memo or hash or offlineUrl
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func requestFunds(payer payerFIOAddress:String, payee payeeFIOAddress: String, payeePublicAddress: String, amount: Float, chainCode: String, tokenCode: String, metadata: RequestFundsRequest.MetaData, maxFee: Int, walletFioAddress:String = "", onCompletion: @escaping ( _ response: RequestFundsResponse?, _ error:FIOError? ) -> ()) {
       
        self.getFioPublicKey(fioAddress: payerFIOAddress) { (response, error) in

            if (error.kind == FIOError.ErrorKind.Success) {
                
                let contentJson = RequestFundsContent(payeePublicAddress: payeePublicAddress, amount: String(amount), chainCode: chainCode, tokenCode: tokenCode, memo:metadata.memo ?? "", hash: metadata.hash ?? "", offlineUrl: metadata.offlineUrl ?? "")
                
                let encryptedContent = self.encrypt(publicKey: response?.publicAddress ?? "", contentType: FIOAbiContentType.newFundsContent, contentJson: contentJson.toJSONString())
                
                let actor = AccountNameGenerator.run(withPublicKey: self.getPublicKey())
                let data = RequestFundsRequest(payerFIOAddress: payerFIOAddress, payeeFIOAddress: payeeFIOAddress, content:encryptedContent, maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress), actor: actor)
                
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
    
    /** Reject funds request.
     *
     * - Parameter fioRequestId: fio request Id of the funds request record to reject
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func rejectFundsRequest(fioRequestId: Int, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping(_ response: FIOSDK.Responses.RejectFundsRequestResponse?,_ :FIOError) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey:getPublicKey())
        let data = RejectFundsRequest(fioRequestId: fioRequestId, maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress), actor: actor)
        
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.rejectFundsRequest,
                            forAction: ChainActions.rejectFundsRequest,
                            withBody: data,
                            code: "fio.reqobt",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    onCompletion(nil, error ?? FIOError.init(kind: .Failure, localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                let handledData: (response: FIOSDK.Responses.RejectFundsRequestResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                guard handledData.response?.status == .rejected else {
                                    onCompletion(nil, FIOError.failure(localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                onCompletion(handledData.response, FIOError.success())
        }
    }
    
    //MARK: Get Sent FIO Requests
    
    /** Get Sent FIO Requests for the SDK sharedInstance(singleton) associated with the fio public key
     *
     * - Parameter limit: Number of obtData records to return. If omitted, all records will be returned.
     * - Parameter offset: First record from list to return. If omitted, 0 is assumed.
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getSentFioRequests(limit:Int?=nil, offset:Int?=0, onCompletion: @escaping (_ response: FIOSDK.Responses.SentFIORequestsResponse?, _ error: FIOError) -> ()){
        let body = SentFIORequestsRequest(fioPublicKey: self.publicKey, limit: limit, offset: offset ?? 0)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getSentFIORequests)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    var result = try JSONDecoder().decode(FIOSDK.Responses.SentFIORequestsResponse.self, from: data)
                    
                    // filter the dead records
                    result.requests = result.requests.filter { $0.fioRequestId >= 0 }
                    
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
                    onCompletion(nil, FIOError.failure(localizedDescription: ChainRoutes.getSentFIORequests.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Record ObtData

    /** Record a transaction on another blockhain (OBT: other block chain transaction).
     *
     * - Parameter fioRequestId: The fio request Id to record data against.  Set to nil if there is no associated fio request
     * - Parameter payerFIOAddress: FIO Address of the payer. This address will receive the request and will initiate payment, i.e. requestee:brd
     * - Parameter payeeFIOAddress: FIO Address of the payee. This address is sending the request and will receive payment, i.e. requestor:brd
     * - Parameter payerTokenPublicAddress: Payee's public address where they want funds sent.
     * - Parameter payeeTokenPublicAddress: Payee's public address where they want funds sent.
     * - Parameter amount: Amount requested.
     * - Parameter chainCode: Blockchain code for blockchain hosting this token.
     * - Parameter tokenCode: Code of the token represented in Amount requested, i.e. ETH
     * - Parameter obtId: Other Blockchain Transaction Id i.e. 0x3234222...
     * - Parameter metadata: Contains the: memo or hash or offlineUrl
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func recordObtData(fioRequestId: Int? = nil,
                           payerFIOAddress: String,
                           payeeFIOAddress: String,
                           payerTokenPublicAddress: String,
                           payeeTokenPublicAddress: String,
                           amount: Double,
                           chainCode: String,
                           tokenCode: String,
                           obtId: String,
                           maxFee: Int,
                           metaData: RecordObtDataRequest.MetaData,
                           walletFioAddress: String = "",
                           onCompletion: @escaping (_ response: FIOSDK.Responses.RecordObtDataResponse?, _ error: FIOError?) -> ()){
        
        let contentJson = RecordObtDataContent(payerPublicAddress: payerTokenPublicAddress, payeePublicAddress: payeeTokenPublicAddress, amount: String(amount), chainCode: chainCode, tokenCode: tokenCode, status:"sent_to_blockchain", obtId: obtId, memo: metaData.memo ?? "", hash: metaData.hash ?? "", offlineUrl: metaData.offlineUrl ?? "")
        
        FIOSDK.sharedInstance().getFioPublicKey(fioAddress: payeeFIOAddress) { (response, error) in
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
            
            let request = RecordObtDataRequest(payerFIOAddress: payerFIOAddress, payeeFIOAddress: payeeFIOAddress, content: encryptedContent, fioRequestId: fioReqId, maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress), actor: actor)
            
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
    
    /** Returns balance of the FIO Token.  For the public key of the FIOSDK sharedInstance (Singleton).
     *
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFioBalance(onCompletion: @escaping (_ response: FIOSDK.Responses.FIOBalanceResponse?, _ error: FIOError) -> ()){
        FIOSDK.sharedInstance().getFioBalance(fioPublicKey: FIOSDK.sharedInstance().getPrivateKey(), onCompletion: { (resp, err) in
            onCompletion(resp, err)
            return
        })
    }
    
    /** Returns balance of the FIO Token.
     * - Parameter - fioPublicKey: The FIO public key to get the FIO token balance for.
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFioBalance(fioPublicKey: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FIOBalanceResponse?, _ error: FIOError) -> ()){
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
    
    //MARK: Transfer FIO Tokens
    
    /**
     * Transfers FIO tokens.
     * - Parameter payeePublicKey: The receiver public key.
     * - Parameter amount: The value in SUFs that will be transfered from the calling account to the especified account.
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by calling the getFee() method for the correct value.
     * - Parameter walletFioAddress: FIO Address of the wallet which generates this transaction.
     + Set to empty if not known.
     + This can be passed into the sharedInstance (Singleton) initializer to be used for all method calls OR overridden here
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func transferTokens(payeePublicKey: String, amount: Int, maxFee: Int, walletFioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.TransferFIOTokensResponse?, _ error: FIOError) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let transfer = TransferFIOTokensRequest (payeePublicKey: payeePublicKey, amount: amount, maxFee: maxFee, walletFioAddress: self.getWalletFioAddress(walletFioAddress), actor: actor)
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
    
    //MARK: Get Fees

    /** Returns Fee for the selected API endpoint
     *
     * - Parameter endPoint: Name of API call end point, e.g. registerFIODomain
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFee(endPoint: FIOSDK.Params.FeeEndpoint, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: "", endPoint: endPoint.rawValue, onCompletion: onCompletion)
    }
    
    /** Returns FeeResponse for the selected API endpoint
     *
     * - Parameter fioAddress: FIO Address
     * - Parameter endPoint: Name of API call end point, e.g. registerFIODomain
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
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
    
    /** Returns Fee for the Add Public Address API endpoint
     *
     * - Parameter fioAddress: FIO Address
     * - Parameter endPoint: Name of API call end point, e.g. registerFIODomain
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFeeForAddPublicAddress(fioAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: fioAddress, endPoint: "add_pub_address", onCompletion: onCompletion)
    }
    
    /** Returns Fee for the Funds Request API endpoint
     *
     * - Parameter payeeFioAddress: payee FIO Address
     * - Parameter endPoint: Name of API call end point, e.g. registerFIODomain
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFeeForNewFundsRequest(payeeFioAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: payeeFioAddress, endPoint: "new_funds_request", onCompletion: onCompletion)
    }
    
    /** Returns Fee for the Request Funds API endpoint
     *
     * - Parameter payeeFioAddress: Payee FIO Address
     * - Parameter endPoint: Name of API call end point, e.g. registerFIODomain
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFeeForRejectFundsRequest(payeeFioAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: payeeFioAddress, endPoint: "reject_funds_request", onCompletion: onCompletion)
    }
    
    /** Returns Fee for the Record ObtData API endpoint
     *
     * - Parameter payerFioAddress: The Payer FIO Address
     * - Parameter endPoint: Name of API call end point, e.g. registerFIODomain
     * - Parameter - onCompletion: The completion handler, providing an optional error in case something goes wrong
     **/
    public func getFeeForRecordObtData(payerFioAddress: String, onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        self.getFeeResponse(fioAddress: payerFioAddress, endPoint: "record_obt_data", onCompletion: onCompletion)
    }
}

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

