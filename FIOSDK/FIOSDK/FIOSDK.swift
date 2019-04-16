//
//  FIOWalletSDK.swift
//  FIOWalletSDK
//
//  Created by shawn arney on 10/5/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import UIKit

private let decimalsFIO: Int = 4

public class FIOSDK: NSObject {
    
    //Used as a namespace for response classes. Each model will be added with extension feature in its own file.
    public enum Responses {}
    
    private let ERROR_DOMAIN = "FIO Wallet SDK"
    private var accountName:String = ""
    private var privateKey:String = ""
    private var publicKey:String = ""
    private var systemPrivateKey:String = ""
    private var systemPublicKey:String = ""
    private static let keyManager = FIOKeyManager()
    private let pubAddressTokenFilter: [String: UInt8] = ["fio": 1]
    
    //MARK: -
    
    public struct Request{
        public let amount:Float
        public let currencyCode:String
        public var status:RequestStatus
        public let requestTimeStamp:Int
        public let requestDate:Date
        public let requestDateFormatted:String
        public let fromFioName:String
        public let toFioName:String
        public let requestorAccountName:String
        public let requesteeAccountName:String
        public let memo:String
        public let fioappid:Int
        public let requestid:Int
        public let statusDescription:String
    }
    
    public enum RequestStatus:String, Codable {
        case Requested = "Requested"
        case Rejected = "Rejected"
        case Approved = "Approved"
    }
    
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
        
        
        return _sharedInstance
    }
    
    public func isFioNameValid(fioName: String) -> Bool{
        if fioName.contains(".") {
            return isFIOAddressValid(fioName)
        }
        return isFIODomainValid(fioName)
    }
    
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
    
    private func getAccountName() -> String{
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
    
    internal func getPublicKey() -> String {
        return self.publicKey
    }

    //MARK: - Signed Post Request
    
    /**
     * This function does a signed post request to our API. It uses TransactionUtil.packAndSignTransaction to pack and sign body before doing the POST request to the required route.
     * - Parameters:
     *      - route: The route to be requested. Look at ChainRoutes for possible values
     *      - action: The API action for the given request. Look at ChainActions for possible values
     *      - body: The request body parameters to be serialized and sent as a data string
     *      - code: The code required for packing and signing a transaction, for more info look at TransactionUtil.packAndSignTransaction
     *      - account: The account required for packing and signing a transaction, for more info look at TransactionUtil.packAndSignTransaction
     *      - onCompletion: A callback function that is called when request is finished with is Data value and either with success or failure, both values are optional. Check FIOError.kind to determine if is a success or a failure.
     */
    private func signedPostRequestTo<T: Codable>(route: ChainRoutes, forAction action: ChainActions, withBody body: T, code: String, account: String, onCompletion: @escaping (_ result: TxResult?, FIOError?) -> Void) {
        guard let privateKey = try! PrivateKey(keyString: getSystemPrivateKey()) else {
            onCompletion(nil, FIOError(kind: .FailedToUsePrivKey, localizedDescription: "Failed to retrieve private key."))
            return
        }
        serializeJsonToData(body, forAction: action) { (result, error) in
            if let result = result {
                PackedTransactionUtil.packAndSignTransaction(code: code, action: action.rawValue, data: result.json, account: account, privateKey: privateKey, completion: { (signedTx, error) in
                    if let error = self.translateErrorToFIOError(error: error) {
                        onCompletion(nil, error)
                    }
                    else {
                        print("Called FIOSDK action: " + action.rawValue)
                        let url = ChainRouteBuilder.build(route: route)
                        FIOHTTPHelper.postRequestTo(url, withBody: signedTx, onCompletion: { (data, error) in
                            if data == nil, let error = error {
                                onCompletion(nil, error)
                                return
                            }
                            let handledResults = self.parseResponseDataToTransactionResult(data: data)
                            onCompletion(handledResults.response, handledResults.error)
                        })
                    }
                })
            }
            else {
                onCompletion(nil, error)
            }
        }
    }
    
    /**
     * Try transforming data into a TxResult object. Data is expected to be a json object.
     * - Parameters:
     *      - data: The Data object containing a json or nil.
     * - Return: A tuple containing the parsed response object or error.
     */
    private func parseResponseDataToTransactionResult(data: Data?) -> (response: TxResult?, error: FIOError?) {
        guard let data = data else {
            return (nil, FIOError(kind: .NoDataReturned, localizedDescription: "Server response was empty"))
        }
        let decoder = JSONDecoder()
        var responseObject: TxResult? = nil
        do {
            responseObject = try decoder.decode(TxResult.self, from: data)
        } catch let error {
            return (nil, FIOError(kind: .Failure, localizedDescription: error.localizedDescription))
        }
        return (responseObject, nil)
    }
    
    /**
     * Decode whichever JSON object that is inside transaction result (TxResult) to expected response. That response must implement Codable.
     * - Parameters:
     *      - txResult: The transaction result to parse response from.
     * - Return: A tuple containing the parsed response object and error. The error is either a FIOError.ErrorKind.Failure or a FIOError.ErrorKind.Success.
     */
    private func parseResponseFromTransactionResult<T: Codable>(txResult: TxResult) -> (response: T?, error: FIOError) {
        guard let responseString = txResult.processed?.actionTraces.first?.receipt.response.value as? String, let responseData = responseString.data(using: .utf8), let response = try? JSONDecoder().decode(T.self, from: responseData) else {
            return (nil, FIOError.init(kind: .Failure, localizedDescription: "Error parsing the response"))
        }
        return (response, FIOError(kind: .Success, localizedDescription: ""))
    }
    
    private func translateErrorToFIOError(error: Error?) -> FIOError? {
        guard error != nil else { return nil }
        if (error! as NSError).code == RPCErrorResponse.ErrorCode {
            let errDescription = "error"
            print (errDescription)
            return FIOError.init(kind: .Failure, localizedDescription: errDescription)
        } else {
            let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
            print (errDescription)
            return FIOError.init(kind: .Failure, localizedDescription: errDescription)
        }
    }
    
    //MARK: Private/Public Key
    
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
    
    
    //MARK: - Chain Info
    
    internal func chainInfo(completion: @escaping (_ result: ChainInfo?, _ error: Error?) -> ()) {
        FIOHTTPHelper.rpcPostRequestTo(ChainRouteBuilder.build(route: ChainRoutes.getInfo), withBody: nil as String?,  onCompletion: completion)
    }
    
    internal func getBlock(blockNumOrId: AnyObject, completion: @escaping (_ result: BlockInfo?, _ error: Error?) -> ()) {
        let body = ["block_num_or_id": "\(blockNumOrId)"]
        FIOHTTPHelper.rpcPostRequestTo(ChainRouteBuilder.build(route: ChainRoutes.getBlock), withBody: body, onCompletion: completion)
    }
    
    //MARK: - Register FIO Name request
    
    /**
     * This function should be called to register a new FIO Address (name)
     * - Parameter fioName: A string to register as FIO Address
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    private func register(fioName:String, actor: String, completion: @escaping ( _ error:FIOError?) -> ()) {
        let registerName = RegisterName(fioName: fioName, actor: actor)
        signedPostRequestTo(route: ChainRoutes.registerFIOName,
                            forAction: ChainActions.registerFIOName,
                            withBody: registerName,
                            code: "fio.system",
                            account: actor) { (data, error) in
            if data != nil {
                completion(FIOError(kind: .Success, localizedDescription: ""))
            } else {
                if let error = error {
                    completion(error)
                }
                else {
                    completion(FIOError(kind:.Failure, localizedDescription: "register_fio_name request failed."))
                }
            }
        }
    }
    
    public func registerFioName(fioName:String, publicReceiveAddresses:Dictionary<String,String>, completion: @escaping ( _ error:FIOError?) -> ()) {
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        self.register(fioName: fioName, actor: actor, completion: { (error) in
            guard error == nil || error?.kind == .Success else {
                completion(error)
                return
            }
            let addresses:Dictionary<String,String> = publicReceiveAddresses
        
            var anyFail = false
        
            let group = DispatchGroup()
            var operations: [AddPubAddressOperation] = []
            var index = 0
            for (chain, receiveAddress) in addresses {
                if self.pubAddressTokenFilter[chain.lowercased()] != nil { continue }
                group.enter()
                let operation = AddPubAddressOperation(action: { operation in
                    self.addPublicAddress(fioAddress: fioName, chain: chain, publicAddress: receiveAddress, completion: { (error) in
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
                completion(FIOError.init(kind: anyFail ? .Failure : .Success, localizedDescription: ""))
            }
        })
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
    ///   - completion: The completion handler, providing an optional error in case something goes wrong
    public func addPublicAddress(fioAddress: String, chain: String, publicAddress: String, completion: @escaping ( _ error:FIOError?) -> ()) {
        guard chain.lowercased() != "fio" else {
            completion(FIOError(kind: .Failure, localizedDescription: "[FIO SDK] FIO Token pub address should not be added manually."))
            return
        }
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let data = AddPublicAddress(fioAddress: fioAddress, tokenCode: chain, publicAddress: publicAddress, actor: actor)
        signedPostRequestTo(route: ChainRoutes.addPublicAddress,
                            forAction: ChainActions.addPublicAddress,
                            withBody: data,
                            code: "fio.system",
                            account: actor) { (data, error) in
                                if data != nil {
                                    completion(FIOError(kind: .Success, localizedDescription: ""))
                                } else {
                                    if let error = error {
                                        completion(error)
                                    }
                                    else {
                                        completion(FIOError(kind:.Failure, localizedDescription: ChainActions.addPublicAddress.rawValue + " request failed."))
                                    }
                                }
        }
    }
    
    //MARK: FIO Name Availability
    
    public func isAvailable(fioAddress:String, completion: @escaping (_ isAvailable: Bool, _ error:FIOError?) -> ()) {
        var fioRsvp : AvailCheckResponse = AvailCheckResponse(fio_name: "", is_registered: false)
        
        let fioRequest = AvailCheckRequest(fio_name: fioAddress)
        var jsonData: Data
        do{
            jsonData = try JSONEncoder().encode(fioRequest)
        }catch {
            completion (false, FIOError(kind: .NoDataReturned, localizedDescription: ""))
            return
        }
        
        // create post request
        let url = URL(string: getURI() + "/chain/avail_check")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion(false, FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
                var result = String(data: data, encoding: String.Encoding.utf8) as String!
                print(result)
                
               // result = result?.replacingOccurrences(of: "\"true\"", with: "true")
               // result = result?.replacingOccurrences(of: "\"false\"", with: "false")
                // print (result)

                fioRsvp = try JSONDecoder().decode(AvailCheckResponse.self, from: result!.data(using: String.Encoding.utf8)!)
                print(fioRsvp)

                completion(!fioRsvp.is_registered, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)///TODO:create this correctly with ERROR results
                completion(false, err)
            }
        }
        
        task.resume()
    }
    
    //MARK: Get Pending FIO Requests
    
    /// Pending requests call polls for any pending requests sent to a receiver. [visit api specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/get_pending_fio_requests-GetpendingFIORequests)
    ///
    /// - Parameters:
    ///   - fioPublicAddress: FIO public address of new owner. Has to match signature
    ///   - completion: Completion hanlder
    public func getPendingFioRequests(fioPublicAddress: String, completion: @escaping (_ pendingRequests: FIOSDK.Responses.PendingFioRequestsResponse?, _ error:FIOError?) -> ()) {
        let body = GetPendingFIORequestsRequest(address: fioPublicAddress)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getPendingFIORequests)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.PendingFioRequestsResponse.self, from: data)
                    completion(result, FIOError(kind: .Success, localizedDescription: ""))
                }
                catch {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: ChainRoutes.getPendingFIORequests.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Get FIO Names
    
    /// Returns FIO Addresses and FIO Domains owned by this public address.
    ///
    /// - Parameters:
    ///   - publicAddress: FIO public address of new owner. Has to match signature
    ///   - completion: Completion handler
    public func getFioNames(publicAddress: String, completion: @escaping (_ names: FIOSDK.Responses.FioNamesResponse?, _ error: FIOError?) -> ()){
        let body = GetFIONamesRequest(fioPubAddress: publicAddress)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getFIONames)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.FioNamesResponse.self, from: data)
                    let newestAddresses = result.addresses.sorted(by: { (address, nextAddress) -> Bool in
                        address.expiration > nextAddress.expiration
                    })
                    let newResult = FIOSDK.Responses.FioNamesResponse(publicAddress: result.publicAddress, domains: result.domains, addresses: newestAddresses)
                    completion(newResult, FIOError(kind: .Success, localizedDescription: ""))
                }
                catch {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: ChainRoutes.getFIONames.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Single FIO Name
    
    /// Returns details about the FIO address.
    /// - Parameters:
    ///   - fioAddress: FIO Address for which to get details to, e.g. "alice.brd"
    ///   - onCompletion: A FioAddressResponse object containing details.
    public func getFIONameDetails(_ fioAddress: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.FioAddressResponse?, _ error: FIOError) -> ()) {
        FIOSDK.sharedInstance().getPublicAddress(fioAddress: fioAddress, tokenCode: "FIO") { (response, error) in
            guard error.kind == .Success, let fioPublicAddress = response?.publicAddress else{
                onCompletion(nil, error)
                return
            }
            FIOSDK.sharedInstance().getFioNames(publicAddress: fioPublicAddress, completion: { (response, error) in
                guard error?.kind == .Success, let result = response?.addresses.first else {
                    onCompletion(nil, error ?? FIOError.failure(localizedDescription: "FIO details not found"))
                    return
                }
                onCompletion(result, error ?? FIOError.success())
            })
        }
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
        let body = PublicAddressLookupRequest(fioAddress: fioAddress, tokenCode: tokenCode)
        let url = ChainRouteBuilder.build(route: ChainRoutes.pubAddressLookup)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.PublicAddressResponse.self, from: data)
                    completion(result, FIOError(kind: .Success, localizedDescription: ""))
                }
                catch {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: ChainRoutes.pubAddressLookup.rawValue + " request failed."))
                }
            }
        }
    }
    
    /// Returns a public address for the specified token registered under a FIO public address.
    /// - Parameters:
    ///   - forToken: Token code for which public address is to be returned, e.g. "ETH".
    ///   - withFIOPublicAddress: FIO public Address under which the token was registered.
    ///   - onCompletion: A TokenPublicAddressResponse containing FIO address and public address.
    public func getTokenPublicAddress(forToken token: String, withFIOPublicAddress publicAddress: String, onCompletion: @escaping (_ publicAddress: FIOSDK.Responses.TokenPublicAddressResponse?, _ error: FIOError) -> ()) {
        FIOSDK.sharedInstance().getFioNames(publicAddress: publicAddress) { (response, error) in
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
    ///   - fromFioAddress: FIO Address of user sending funds, i.e. requestor.brd
    ///   - toFioAddress: FIO Address of user receiving funds, i.e. requestee.brd
    ///   - publicAddress: Public address on other blockchain of user receiving funds.
    ///   - amount: Amount requested.
    ///   - tokenCode: Code of the token represented in Amount requested, i.e. ETH
    ///   - metadata: Contains the: memo or hash or offlineUrl (they are mutually excludent, fill only one)
    ///   - completion: The completion handler containing the result
    public func requestFunds(from fromFioAddress:String, to toFioAddress: String, toPublicAddress publicAddress: String, amount: Float, tokenCode: String, metadata: RequestFundsRequest.MetaData, completion: @escaping ( _ response: RequestFundsResponse?, _ error:FIOError? ) -> ()) {
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let data = RequestFundsRequest(from: fromFioAddress, to: toFioAddress, toPublicAddress: publicAddress, amount: String(amount), tokenCode: tokenCode, metadata: metadata.toJSONString(), actor: actor)
        
        signedPostRequestTo(route: ChainRoutes.newFundsRequest,
                            forAction: ChainActions.newFundsRequest,
                            withBody: data,
                            code: "fio.reqobt",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    completion(nil, error)
                                    return
                                }
                                let handledData: (response: RequestFundsResponse?, error: FIOError) = self.parseResponseFromTransactionResult(txResult: result)
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
    ///   - completion: The completion handler containing the result or error.
    public func rejectFundsRequest(fundsRequestId: String, completion: @escaping(_ response: FIOSDK.Responses.RejectFundsRequestResponse?,_ :FIOError) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let data = RejectFundsRequest(fioReqID: fundsRequestId, actor: actor)
        
        signedPostRequestTo(route: ChainRoutes.rejectFundsRequest,
                            forAction: ChainActions.rejectFundsRequest,
                            withBody: data,
                            code: "fio.reqobt",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    completion(nil, error ?? FIOError.init(kind: .Failure, localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                let handledData: (response: FIOSDK.Responses.RejectFundsRequestResponse?, error: FIOError) = self.parseResponseFromTransactionResult(txResult: result)
                                guard handledData.response?.status == .rejected else {
                                    completion(nil, FIOError.init(kind: .Failure, localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                completion(handledData.response, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
        }
    }
    
    //MARK: Get Sent FIO Requests
    
    /// Get all requests sent by the given public address. Usually made with requestFunds.
    /// To read further infomation about this [visit the API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/get_sent_fio_requests-GetFIORequestssentout)
    /// - Parameters:
    ///   - publicAddress: FIO public address of owner.
    ///   - completion: The completion result
    public func getSentFioRequests(publicAddress: String, completion: @escaping (_ response: FIOSDK.Responses.SentFioRequestResponse?, _ error: FIOError) -> ()){
        let body = GetSentFIORequestsRequest(address: publicAddress)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getSentFIORequests)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.SentFioRequestResponse.self, from: data)
                    completion(result, FIOError(kind: .Success, localizedDescription: ""))
                }
                catch {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: ChainRoutes.getPendingFIORequests.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Record Send
    
    /// Register a transaction on another blockhain (OBT: other block chain transaction), it does auto resolve from (requestor) FIO address and to (requestee) token public address. Must be called after any transaction if recordSend is not called. [visit api specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/record_send-Recordssendonanotherblockchain)
    ///
    /// - Parameters:
    ///     - toFIOAdd: FIO address that is receiving currency. (requestee)
    ///     - fromPubAdd: FIO public address related to the token code being sent by from user (requestor)
    ///     - amount: The value being sent.
    ///     - tokenCode: Token code being transactioned. BTC, ETH, etc.
    ///     - obtID: The transaction ID (OBT) representing the transaction from one blockchain to another one.
    ///     - fioReqID: The FIO request ID to register the transaction for. Only required when approving transaction request.
    ///     - memo: The note for that transaction.
    ///     - onCompletion: Once finished this callback returns optional response and error.
    public func recordSendAutoResolvingWith(toFIOAdd: String,
                                andFromPubAdd fromPubAdd: String,
                                amountSent amount: Float,
                                forTokenCode tokenCode: String,
                                obtID: String,
                                fioReqID: String? = nil,
                                memo: String,
                                onCompletion: @escaping (_ response: FIOSDK.Responses.RecordSendResponse?, _ error: FIOError?) -> ()) {
        FIOSDK.sharedInstance().getFioNames(publicAddress: fromPubAdd) { (response, error) in
            guard error == nil || error?.kind == .Success, let fromAdd = response?.addresses.first?.address else {
                onCompletion(nil, error ?? FIOError.failure(localizedDescription: "[FIO SDK] Failed to send record."))
                    return
            }
            FIOSDK.sharedInstance().getPublicAddress(fioAddress: toFIOAdd, tokenCode: tokenCode) { (response, error) in
                guard error.kind == .Success, let toPubAdd = response?.publicAddress else {
                    onCompletion(nil, error)
                    return
                }
                FIOSDK.sharedInstance().recordSend(fioReqID: fioReqID, fromFIOAdd: fromAdd, toFIOAdd: toFIOAdd, fromPubAdd: fromPubAdd, toPubAdd: toPubAdd, amount: amount, fromTokenCode: tokenCode, toTokenCode: tokenCode, obtID: obtID, memo: memo, onCompletion: onCompletion)
            }
        }
    }
    
    /// Register a transation on another blockhain (OBT: other block chain transaction). Should be called after any transaction if recordSendAutoResolvingWith is not called. [visit api specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/record_send-Recordssendonanotherblockchain)
    ///
    /// - Parameters:
    ///     - fioReqID: The FIO request ID to register the transaction for. Only required when approving transaction request.
    ///     - fromFIOAdd: FIO address that is sending currency. (requestor)
    ///     - toFIOAdd: FIO address that is receiving currency. (requestee)
    ///     - fromPubAdd: FIO public address related to the token code being sent by from user (requestor)
    ///     - toPubAdd: FIO public address related to the token code being received by to user (requestee)
    ///     - amount: The value being sent.
    ///     - fromTokenCode: Token code being sent. BTC, ETH, etc.
    ///     - toTokenCode: Token code being received. BTC, ETH, etc.
    ///     - obtID: The transaction ID (OBT) representing the transaction from one blockchain to another one.
    ///     - memo: A note for that transaction.
    ///     - onCompletion: Once finished this callback returns optional response and error.
    public func recordSend(fioReqID: String? = nil,
                           fromFIOAdd: String,
                           toFIOAdd: String,
                           fromPubAdd: String,
                           toPubAdd: String,
                           amount: Float,
                           fromTokenCode: String,
                           toTokenCode: String,
                           obtID: String,
                           memo: String,
                           onCompletion: @escaping (_ response: FIOSDK.Responses.RecordSendResponse?, _ error: FIOError?) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let recordSend = RecordSend(fioReqID: fioReqID, fromFIOAdd: fromFIOAdd, toFIOAdd: toFIOAdd, fromPubAdd: fromPubAdd, toPubAdd: toPubAdd, amount: amount, tokenCode: fromTokenCode, chainCode: toTokenCode, status: "sent_to_blockchain", obtID: obtID, memo: memo)
        let request = RecordSendRequest(recordSend: recordSend.toJSONString(), actor: actor)
        signedPostRequestTo(route: ChainRoutes.recordSend,
                            forAction: ChainActions.recordSend,
                            withBody: request,
                            code: "fio.reqobt",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    onCompletion(nil, error ?? FIOError.init(kind: .Failure, localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                let handledData: (response: FIOSDK.Responses.RecordSendResponse?, error: FIOError) = self.parseResponseFromTransactionResult(txResult: result)
                                onCompletion(handledData.response, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
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
    public func getFIOBalance(fioPublicAddress: String, completion: @escaping (_ response: FIOSDK.Responses.GetFIOBalanceResponse?, _ error: FIOError) -> ()){
        let body = GetFIOBalanceRequest(fioPubAddress: fioPublicAddress)
        let url = ChainRouteBuilder.build(route: ChainRoutes.getFIOBalance)
        FIOHTTPHelper.postRequestTo(url, withBody: body) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(FIOSDK.Responses.GetFIOBalanceResponse.self, from: data)
                    completion(result, FIOError(kind: .Success, localizedDescription: ""))
                }
                catch {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: "Parsing json failed."))
                }
            } else {
                if let error = error {
                    completion(nil, error)
                }
                else {
                    completion(nil, FIOError(kind:.Failure, localizedDescription: ChainRoutes.getFIOBalance.rawValue + " request failed."))
                }
            }
        }
    }
    
    //MARK: Transfer Tokens
    
    /// Transfers FIO tokens. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/transfer_tokens-TransferFIOtokens)
    /// - Parameters:
    ///     - toFIOPublicAddress: The FIO public address that will receive funds.
    ///     - amount: The value that will be transfered from the calling account to the especified account.
    ///     - completion: A function that is called once request is over with an optional response with results and error containing the status of the call.
    public func transferFIOTokens(toFIOPublicAddress: String, amount: Float, completion: @escaping (_ response: FIOSDK.Responses.TransferFIOTokensResponse?, _ error: FIOError) -> ()){
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        var transferAmount = String(amount)
        var places = decimalsFIO - transferAmount.split(separator: ".")[1].count
        for _ in 0..<places { transferAmount.append("0") }
        let transfer = TransferFIOTokensRequest(amount: transferAmount, actor: actor, toFIOPubAdd: toFIOPublicAddress)
        signedPostRequestTo(route: ChainRoutes.transferTokens,
                            forAction: ChainActions.transferTokens,
                            withBody: transfer,
                            code: "fio.token",
                            account: actor) { (result, error) in
                                guard let result = result else {
                                    completion(nil, error ?? FIOError.init(kind: .Failure, localizedDescription: "\(ChainActions.transferTokens.rawValue) call failed."))
                                    return
                                }
                                let handledData: (response: FIOSDK.Responses.TransferFIOTokensResponse?, error: FIOError) = self.parseResponseFromTransactionResult(txResult: result)
                                completion(handledData.response, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
        }
    }
    
}
