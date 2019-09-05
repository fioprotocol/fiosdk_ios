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
        return !_sharedInstance.accountName.isEmpty && !_sharedInstance.privateKey.isEmpty && !_sharedInstance.publicKey.isEmpty && !_sharedInstance.systemPrivateKey.isEmpty && !_sharedInstance.systemPublicKey.isEmpty && !Utilities.sharedInstance().URL.isEmpty
    }
    
    private static var _sharedInstance: FIOSDK = {
        let sharedInstance = FIOSDK()
        
        return sharedInstance
    }()
    
    public class func sharedInstance(accountName: String? = nil, privateKey:String? = nil, publicKey:String? = nil, systemPrivateKey:String?=nil, systemPublicKey:String? = nil, url:String? = nil, mockUrl: String? = nil) -> FIOSDK {        
        if (accountName == nil ){
            if (_sharedInstance.accountName.count < 2 ){
                //throw FIOError(kind:FIOError.ErrorKind.Failure, localizedDescription: "Account name hasn't been set yet, for the SDK Shared Instance, this needs to be passed in with the first usage")
                fatalError("Account name hasn't been set yet, for the FIOWalletSDK Shared Instance, this needs to be passed in with the first usage")
            }
        }
        else{
            _sharedInstance.accountName = accountName!
        }
        
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
        
        if (systemPrivateKey == nil){
            if (_sharedInstance.systemPrivateKey.count < 2){
                fatalError("System Private Key hasn't been set yet, for the FIOWalletSDK Shared Instance, this needs to be passed in with the first usage")
            }
        }
        else {
            _sharedInstance.systemPrivateKey = systemPrivateKey!
        }
        
        if (systemPublicKey == nil){
            if (_sharedInstance.systemPublicKey.count < 2){
                fatalError("System Public Key hasn't been set yet, for the FIOWalletSDK Shared Instance, this needs to be passed in with the first usage")
            }
        }
        else {
            _sharedInstance.systemPublicKey = systemPublicKey!
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
        if (abi == nil || abi.count < 2){
            _sharedInstance.populateABIs()
        }
        
        return _sharedInstance
    }
    
    //MARK: FIO Name validation
    
    public func isFioNameValid(fioName: String) -> Bool{
        if fioName.contains(".") {
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
    
    //MARK: - Register FIO Name request
    
    /**
     * This function should be called to register a new FIO Address.
     * - Parameter fioAddress: A string to register as FIO Address
     * - Parameter publicReceiveAddresses: A list of public addresses to add to the newly registered FIO address.
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func registerFioAddress(_ fioAddress: String, publicReceiveAddresses:Dictionary<String,String>, maxFee: Double, onCompletion: @escaping (_ response: FIOSDK.Responses.RegisterFIOAddressResponse?, _ error:FIOError?) -> ()) {
        self.registerFioAddress(fioAddress, maxFee: maxFee) { (response, error) in
            guard error == nil || error?.kind == .Success else {
                onCompletion(response, error)
                return
            }
            var addresses:Dictionary<String,String> = publicReceiveAddresses
            
            //TODO: THIS SHOULD BE REMOVED ONCE WE DEFINE HOW WE ARE GOING TO PROPERLY STORE/RETRIEVE PUBLIC KEY
            addresses["pubkey"] = FIOSDK.sharedInstance().getPublicKey()
            //
        
            var anyFail = false
        
            let group = DispatchGroup()
            var operations: [AddPublicAddressOperation] = []
            var index = 0
            for (chain, receiveAddress) in addresses {
                if self.pubAddressTokenFilter[chain.lowercased()] != nil { continue }
                group.enter()
                let operation = AddPublicAddressOperation(action: { operation in
                    self.addPublicAddress(fioAddress: fioAddress, chain: chain, publicAddress: receiveAddress, maxFee: 0, completion: { (error) in
                        anyFail = error?.kind == .Failure
                        group.leave()
                        operation.next()
                    })
                }, index: index)
                index+=1
                operations.append(operation)
            }
            
            for operation in operations {
                operation.operations = operations
            }
            
            operations.first?.run()
            
            group.notify(queue: .main){
                onCompletion(response, FIOError.init(kind: anyFail ? .Failure : .Success, localizedDescription: ""))
            }
        }
    }
    
    /**
     * Register a fioName for someone else using that user's public key. CURRENTLY A MOCK!!!!
     * - Parameter fioName: A string to register as FIO Address
     * - Parameter publicKey: User's public key to register FIO name for.
     * - Parameter publicReceiveAddresses: Public addresses for tokens. This is used to register pre-existing wallets to new user, i.e. BTC - 0xFF0CFB, ETH - 0x801CFB, etc.
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func registerFIONameOnBehalfOfUser(fioName:String, publicKey: String, publicReceiveAddresses:Dictionary<String,String>, onCompletion: @escaping (_ registeredName: RegisterNameForUserResponse?, _ error:FIOError?) -> ()) {
        self.registerFIONameOnBehalfOfUser(fioName: fioName, publicKey: publicKey) { (response, error) in
            guard error == nil || error?.kind == .Success else {
                onCompletion(nil, error)
                return
            }
            var addresses:Dictionary<String,String> = publicReceiveAddresses
            
            //TODO: THIS SHOULD BE REMOVED ONCE WE DEFINE HOW WE ARE GOING TO PROPERLY STORE/RETRIEVE PUBLIC KEY
            addresses["pubkey"] = FIOSDK.sharedInstance().getPublicKey()
            //
            
            var anyFail = false
            
            let group = DispatchGroup()
            var operations: [AddPublicAddressOperation] = []
            var index = 0
            for (chain, receiveAddress) in addresses {
                if self.pubAddressTokenFilter[chain.lowercased()] != nil { continue }
                group.enter()
                let operation = AddPublicAddressOperation(action: { operation in
                    self.addPublicAddress(fioAddress: fioName, chain: chain, publicAddress: receiveAddress, maxFee: 0, completion: { (error) in
                        anyFail = error?.kind == .Failure
                        group.leave()
                        operation.next()
                    })
                }, index: index)
                index+=1
                operations.append(operation)
            }
            
            for operation in operations {
                operation.operations = operations
            }
            
            operations.first?.run()
            
            group.notify(queue: .main){
                onCompletion(response, FIOError.init(kind: anyFail ? .Failure : .Success, localizedDescription: ""))
            }
        }
    }
    
    /**
     * Register a fioName for someone else using that user's public key. CURRENTLY A MOCK!!!!
     * - Parameter fioName: A string to register as FIO Address
     * - Parameter publicKey: User's public key to register FIO name for.
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    private func registerFIONameOnBehalfOfUser(fioName: String, publicKey: String, onCompletion: @escaping (_ registeredName: RegisterNameForUserResponse? , _ error:FIOError?) -> ()) {
        let registerName = RegisterNameForUserRequest(fioName: fioName, publicKey: publicKey)
        FIOHTTPHelper.postRequestTo(getMockURI() ?? "http://mock.dapix.io/mockd/DEV1/register_fio_name", withBody: registerName) { (result, error) in
            guard let result = result else {
                onCompletion(nil, error)
                return
            }
            do {
                let response = try JSONDecoder().decode(RegisterNameForUserResponse.self, from: result)
                onCompletion(response, FIOError.success())
            }catch let error {
                onCompletion(nil, FIOError.failure(localizedDescription: error.localizedDescription))
            }
        }
    }
    
    /**
     * This function should be called to register a new FIO Domain. [visit api](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/register_fio_domain-RegisterFIODomain)
     * - Parameter fioDomain: A string to register as FIO Domain
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    public func registerFioDomain(_ fioDomain: String, maxFee: Double, onCompletion: @escaping (_ response: FIOSDK.Responses.RegisterFIODomainResponse? , _ error:FIOError?) -> ()) {
        guard isFIODomainValid(fioDomain) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Domain."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let domain = RegisterFIODomainRequest(fioDomain: fioDomain, fioPublicKey: FIOSDK.sharedInstance().getPublicKey(), maxFee: SUFUtils.amountToSUF(amount: maxFee), actor: actor)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.registerFIODomain,
                            forAction: ChainActions.registerFIODomain,
                            withBody: domain,
                            code: "fio.system",
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
     * This function should be called to register a new FIO Address. [visit api](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/register_fio_address-RegisterFIOAddress)
     * - Parameter FIOAddress: A string to register as FIO Address
     * - Parameter maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    internal func registerFioAddress(_ fioAddress: String, maxFee: Double, onCompletion: @escaping (_ response: FIOSDK.Responses.RegisterFIOAddressResponse? , _ error:FIOError?) -> ()) {
        guard isFIOAddressValid(fioAddress) else {
            onCompletion(nil, FIOError.failure(localizedDescription: "Invalid FIO Address."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let address = RegisterFIOAddressRequest(fioAddress: fioAddress, fioPublicKey: FIOSDK.sharedInstance().getPublicKey(), maxFee: SUFUtils.amountToSUF(amount: maxFee), actor: actor)
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.registerFIOAddress,
                            forAction: ChainActions.registerFIOAddress,
                            withBody: address,
                            code: "fio.system",
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
    
    /// Register a public address for a tokenCode under a FIO Address.
    /// SDK method that calls the addpubaddrs from the fio
    /// to read further information about the API visit https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/add_pub_address-Addaddress
    ///
    /// - Parameters:
    ///   - fioAddress: A string name tag in the format of fioaddress.brd.
    ///   - chain: The token code of a coin, i.e. BTC, EOS, ETH, etc.
    ///   - publicAddress: A string representing the public address for that FIO Address and coin.
    ///   - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///   - completion: The completion handler, providing an optional error in case something goes wrong
    public func addPublicAddress(fioAddress: String, chain: String, publicAddress: String, maxFee: Double, completion: @escaping ( _ error:FIOError?) -> ()) {
        guard chain.lowercased() != "fio" else {
            completion(FIOError(kind: .Failure, localizedDescription: "[FIO SDK] FIO Token pub address should not be added manually."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getPublicKey())
        let data = AddPublicAddress(fioAddress: fioAddress, tokenCode: chain, publicAddress: publicAddress, actor: actor, maxFee: SUFUtils.amountToSUF(amount: maxFee))
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.addPublicAddress,
                            forAction: ChainActions.addPublicAddress,
                            withBody: data,
                            code: "fio.system",
                            account: actor) { (data, error) in
                                if data != nil {
                                    completion(FIOError.success())
                                } else {
                                    if let error = error {
                                        completion(error)
                                    }
                                    else {
                                        completion(FIOError.failure(localizedDescription: ChainActions.addPublicAddress.rawValue + " request failed."))
                                    }
                                }
        }
    }
    
    //MARK: FIO Name Availability
    
    internal func getCachedABI(accountName: String) -> String{
        return (self._abis[accountName] ?? "")
    }
    
    public func isAvailable(fioAddress:String, completion: @escaping (_ isAvailable: Bool, _ error:FIOError?) -> ()) {
        let request = AvailCheckRequest(fio_name: fioAddress)
        let url = ChainRouteBuilder.build(route: ChainRoutes.availCheck)
        FIOHTTPHelper.postRequestTo(url,
                                    withBody: request) { (data, error) in
                                        guard let data = data, error != nil else {
                                            completion(false, error ?? FIOError.failure(localizedDescription: "isAvailable failed."))
                                            return
                                        }
                                        do {
                                            let response = try JSONDecoder().decode(AvailCheckResponse.self, from: data)
                                            completion(!response.is_registered, FIOError.success())
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
    public func getPendingFioRequests(fioPublicKey: String, completion: @escaping (_ pendingRequests: FIOSDK.Responses.PendingFIORequestsResponse?, _ error:FIOError?) -> ()) {
        let body = PendingFIORequestsRequest(fioPublicKey: fioPublicKey)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getPendingFIORequests)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.PendingFIORequestsResponse.self, from: data)
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
        let url = ChainRouteBuilder.build(route: ChainRoutes.pubAddressLookup)
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
                    completion(nil, FIOError.failure(localizedDescription: ChainRoutes.pubAddressLookup.rawValue + " request failed."))
                }
            }
        }
    }
    
    //TODO: THIS SHOULD BE REMOVED ONCE WE DEFINE HOW WE ARE GOING TO PROPERLY STORE/RETRIEVE PUBLIC KEY
    public func getPublicKey(fioAddress: String, completion: @escaping (_ publicAddress: FIOSDK.Responses.PublicAddressResponse?, _ error: FIOError) -> ()){
        getPublicAddress(fioAddress: fioAddress, tokenCode: "pubkey", completion: completion)
    }
    //
    
    /// Returns a public address for the specified token registered under a FIO public address.
    /// - Parameters:
    ///   - forToken: Token code for which public address is to be returned, e.g. "ETH".
    ///   - withFIOPublicAddress: FIO public Address under which the token was registered.
    ///   - onCompletion: A TokenPublicAddressResponse containing FIO address and public address.
    public func getTokenPublicAddress(forToken token: String, withFIOPublicAddress publicAddress: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.TokenPublicAddressResponse?, _ error: FIOError) -> ()) {
        FIOSDK.sharedInstance().getFioNames(fioPublicKey: publicAddress) { (response, error) in
            guard error == nil || error?.kind == .Success, let fioAddress = response?.addresses.first?.address else {
                onCompletion(nil, error ?? FIOError.failure(localizedDescription: "Failed to retrieve token public address."))
                return
            }
            FIOSDK.sharedInstance().getPublicAddress(fioAddress: fioAddress, tokenCode: token) { (response, error) in
                guard error.kind == .Success, let tokenPubAddress = response?.publicAddress else {
                    onCompletion(nil, error)
                    return
                }
                onCompletion(FIOSDK.Responses.TokenPublicAddressResponse(fioAddress: fioAddress, tokenPublicAddress: tokenPubAddress) , FIOError.success())
            }
        }
    }
    
    //MARK: - Request Funds
    
    /// Creates a new funds request.
    /// To read further infomation about this [visit the API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/new_funds_request-Createnewfundsrequest)
    /// Note: requestor is sender, requestee is receiver
    ///
    /// - Parameters:
    ///   - payer: FIO Address of the payer. This address will receive the request and will initiate payment, i.e. requestor.brd
    ///   - payee: FIO Address of the payee. This address is sending the request and will receive payment, i.e. requestee.brd
    ///   - payeePublicAddress: Payee's public address where they want funds sent.
    ///   - amount: Amount requested.
    ///   - tokenCode: Code of the token represented in Amount requested, i.e. ETH
    ///   - metadata: Contains the: memo or hash or offlineUrl (they are mutually excludent, fill only one)
    ///   - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///   - completion: The completion handler containing the result
    public func requestFunds(payer payerFIOAddress:String, payee payeeFIOAddress: String, payeePublicAddress: String, amount: Float, tokenCode: String, metadata: RequestFundsRequest.MetaData, maxFee: Double, completion: @escaping ( _ response: RequestFundsResponse?, _ error:FIOError? ) -> ()) {
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let data = RequestFundsRequest(payerFIOAddress: payerFIOAddress, payeeFIOAddress: payeeFIOAddress, payeePublicAddress: payeePublicAddress, amount: String(amount), tokenCode: tokenCode, metadata: metadata.toJSONString(), actor: actor, maxFee: SUFUtils.amountToSUF(amount: maxFee))
        
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.newFundsRequest,
                            forAction: ChainActions.newFundsRequest,
                            withBody: data,
                            code: "fio.reqobt",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    completion(nil, error)
                                    return
                                }
                                let handledData: (response: RequestFundsResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                completion(handledData.response, handledData.error)
        }
    }
    
    //MARK: - Reject Funds
    
    /// Reject funds request.
    /// To read further infomation about this [visit the API specs] [1]
    ///
    ///    [1]: https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/reject_funds_request-Rejectfundsrequest        "api specs"
    ///
    /// - Parameters:
    ///   - fundsRequestId: ID of that fund request.
    ///   - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///   - completion: The completion handler containing the result or error.
    public func rejectFundsRequest(fundsRequestId: String, maxFee: Double, completion: @escaping(_ response: FIOSDK.Responses.RejectFundsRequestResponse?,_ :FIOError) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let data = RejectFundsRequest(fioReqID: fundsRequestId, actor: actor, maxFee: SUFUtils.amountToSUF(amount: maxFee))
        
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
    public func getSentFioRequests(fioPublicKey: String, completion: @escaping (_ response: FIOSDK.Responses.SentFIORequestsResponse?, _ error: FIOError) -> ()){
        let body = SentFIORequestsRequest(fioPublicKey: fioPublicKey)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getSentFIORequests)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.SentFIORequestsResponse.self, from: data)
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
    
    //MARK: Record Send
    
    /// Register a transaction on another blockhain (OBT: other block chain transaction), it does auto resolve from (requestor) FIO address and to (requestee) token public address. Must be called after any transaction if recordSend is not called. [visit api specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/record_send-Recordssendonanotherblockchain)
    ///
    /// - Parameters:
    ///     - payeeFIOAddress: FIO Address of the payer. This address initiated payment. (requestee)
    ///     - andPayerPublicAddress: Public address on other blockchain of user sending funds. (requestor)
    ///     - amountSent: The value being sent.
    ///     - forTokenCode: Token code being transactioned. BTC, ETH, etc.
    ///     - obtID: The transaction ID (OBT) representing the transaction from one blockchain to another one.
    ///     - fioReqID: The FIO request ID to register the transaction for. Only required when approving transaction request.
    ///     - memo: The note for that transaction.
    ///     - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///     - onCompletion: Once finished this callback returns optional response and error.
    public func recordSendAutoResolvingWith(payeeFIOAddress: String,
                                andPayerPublicAddress payerPublicAddress: String,
                                amountSent amount: Float,
                                forTokenCode tokenCode: String,
                                obtID: String,
                                fioReqID: String? = nil,
                                memo: String,
                                maxFee: Double,
                                onCompletion: @escaping (_ response: FIOSDK.Responses.RecordSendResponse?, _ error: FIOError?) -> ()) {
        FIOSDK.sharedInstance().getFioNames(fioPublicKey: FIOSDK.sharedInstance().getPublicKey()) { (response, error) in
            guard error == nil || error?.kind == .Success, let payerFIOAddress = response?.addresses.first?.address else {
                onCompletion(nil, error ?? FIOError.failure(localizedDescription: "Failed to send record."))
                    return
            }
            FIOSDK.sharedInstance().getPublicAddress(fioAddress: payeeFIOAddress, tokenCode: tokenCode) { (response, error) in
                guard error.kind == .Success, let payeePublicAddress = response?.publicAddress else {
                    onCompletion(nil, error)
                    return
                }
                FIOSDK.sharedInstance().recordSend(fioReqID: fioReqID, payerFIOAddress: payerFIOAddress, payeeFIOAddress: payeeFIOAddress, payerPublicAddress: payerPublicAddress, payeePublicAddress: payeePublicAddress, amount: amount, tokenCode: tokenCode, obtID: obtID, memo: memo, maxFee: maxFee, onCompletion: onCompletion)
            }
        }
    }
    
    /// Register a transation on another blockhain (OBT: other block chain transaction). Should be called after any transaction if recordSendAutoResolvingWith is not called. [visit api specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/record_send-Recordssendonanotherblockchain)
    ///
    /// - Parameters:
    ///     - fioReqID: The FIO request ID to register the transaction for. Only required when approving transaction request.
    ///     - payerFIOAddress: FIO Address of the payer. This address initiated payment. (requestor)
    ///     - payeeFIOAddress: FIO Address of the payee. This address is receiving payment. (requestee)
    ///     - payerPublicAddress: Public address on other blockchain of user sending funds. (requestor)
    ///     - payeePublicAddress: Public address on other blockchain of user receiving funds. (requestee)
    ///     - amount: The value being sent.
    ///     - fromTokenCode: Token code being sent. BTC, ETH, etc.
    ///     - toTokenCode: Token code being received. BTC, ETH, etc.
    ///     - obtID: The transaction ID (OBT) representing the transaction from one blockchain to another one.
    ///     - memo: A note for that transaction.
    ///     - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///     - onCompletion: Once finished this callback returns optional response and error.
    public func recordSend(fioReqID: String? = nil,
                           payerFIOAddress: String,
                           payeeFIOAddress: String,
                           payerPublicAddress: String,
                           payeePublicAddress: String,
                           amount: Float,
                           tokenCode: String,
                           obtID: String,
                           memo: String,
                           maxFee: Double,
                           onCompletion: @escaping (_ response: FIOSDK.Responses.RecordSendResponse?, _ error: FIOError?) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let request = RecordSendRequest(fioReqID: fioReqID, payerFIOAddress: payerFIOAddress, payeeFIOAddress: payeeFIOAddress, payerPublicAddress: payerPublicAddress, payeePublicAddress: payeePublicAddress, amount: amount, tokenCode: tokenCode, status: "sent_to_blockchain", obtID: obtID, memo: memo, actor: actor, maxFee: SUFUtils.amountToSUF(amount: maxFee))
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.recordSend,
                            forAction: ChainActions.recordSend,
                            withBody: request,
                            code: "fio.reqobt",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    onCompletion(nil, error ?? FIOError.failure(localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                let handledData: (response: FIOSDK.Responses.RecordSendResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                onCompletion(handledData.response, FIOError.success())
        }
    }
    
    //MARK: FIO Public Address
    /// Call this to get the FIO pub address.
    /// - Return: the FIO public address String value.
    public func getFIOPublicAddress() -> String {
        return AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
    }
    
    //MARK: Get FIO Balance
    
    /// Retrieves balance of FIO tokens. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/get_fio_balance-GetFIObalance)
    /// - Parameters:
    ///     - fioPublicAddress: The FIO public address to get FIO tokens balance for.
    ///     - completion: A function that is called once request is over with an optional response that should contain balance and error containing the status of the call.
    public func getFIOBalance(fioPublicAddress: String, completion: @escaping (_ response: FIOSDK.Responses.FIOBalanceResponse?, _ error: FIOError) -> ()){
        let body = FIOBalanceRequest(fioPubAddress: fioPublicAddress)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getFIOBalance)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    var result = try JSONDecoder().decode(FIOSDK.Responses.FIOBalanceResponse.self, from: data)
                    result.balance = SUFUtils.amountToSUFString(amount: Double(result.balance) as! Double)
//                     po (amount.tokenValue * 10000) / 1000000000.0
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
                    completion(nil, FIOError.failure(localizedDescription: ChainRoutes.getFIOBalance.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Transfer Tokens
    
    /// Transfers FIO tokens. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/transfer_tokens-TransferFIOtokens)
    /// - Parameters:
    ///     - payeePublicKey: The receiver public key.
    ///     - amount: The value that will be transfered from the calling account to the especified account.
    ///     - maxFee: Maximum amount of SUFs the user is willing to pay for fee. Should be preceded by /get_fee for correct value.
    ///     - completion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    public func transferFIOTokens(payeePublicKey: String, amount: Double, maxFee: Double, completion: @escaping (_ response: FIOSDK.Responses.TransferFIOTokensResponse?, _ error: FIOError) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let transferAmount = SUFUtils.amountToSUFString(amount: amount)
        let transfer = TransferFIOTokensRequest(amount: transferAmount, actor: actor, payeePublicKey: payeePublicKey, maxFee: SUFUtils.amountToSUF(amount: maxFee))
        signedPostRequestTo(privateKey: getPrivateKey(),
                            route: ChainRoutes.transferTokens,
                            forAction: ChainActions.transferTokens,
                            withBody: transfer,
                            code: "fio.token",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    completion(nil, error ?? FIOError.failure(localizedDescription: "\(ChainActions.transferTokens.rawValue) call failed."))
                                    return
                                }
                                let handledData: (response: FIOSDK.Responses.TransferFIOTokensResponse?, error: FIOError) = parseResponseFromTransactionResult(txResult: result)
                                completion(handledData.response, FIOError.success())
        }
    }
    
    //MARK: Get Fee
    
    /// Compute and return fee amount for specific call and specific user. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/get_fee-Computeandreturnfeeamountforspecificcallandspecificuser)
    /// - Parameters:
    ///     - endPoint: Name of API call end point, e.g. add_pub_address
    ///     - fio_address: FIO Address incurring the fee and owned by signer.
    ///     - completion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    public func getFee(endPoint: FIOSDK.Params.FeeEndpoint, fioAddress: String = "", onCompletion: @escaping (_ response: FIOSDK.Responses.FeeResponse?, _ error: FIOError) -> ()) {
        let body = FeeRequest(fioAddress: fioAddress, endPoint: endPoint.rawValue)
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
    
    func getSharedSecret(otherPublicKey: String) {
        
    }
    
}
