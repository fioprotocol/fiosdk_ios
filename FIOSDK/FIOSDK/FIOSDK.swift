//
//  FIOWalletSDK.swift
//  FIOWalletSDK
//
//  Created by shawn arney on 10/5/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

/*
 internals:
     getFioTranslatedAddress
        getFioname(string name, currency)
            fio_name_lookup - returns the BC address to use
 */

import UIKit

public class FIOSDK: NSObject {
    
    private let ERROR_DOMAIN = "FIO Wallet SDK"
    private var accountName:String = ""
    private var privateKey:String = ""
    private var publicKey:String = ""
    private var systemPrivateKey:String = ""
    private var systemPublicKey:String = ""
    private let requestFunds = RequestFunds()
    
    
    //MARK: - Chain routes
    enum ChainRoutes: String {
        case serializeJSON      = "/chain/serialize_json"
        case registerFIOName    = "/chain/register_fio_name"
        case newFundsRequest    = "/chain/new_funds_request"
        case rejectFundsRequest = "/chain/reject_funds_request"
        case addPublicAddress   = "/chain/add_pub_address"
    }
    
    struct ChainRouteBuilder {
        
        static func build(route: ChainRoutes) -> String {
            return ChainRouteBuilder.getBaseURL() + route.rawValue
        }
        
        private static func getBaseURL() -> String {
            return Utilities.sharedInstance().URL
        }
        
    }
    
    //MARK: - Chain Actions
    
    enum ChainActions: String {
        case registerFIOName    = "registername"
        case newFundsRequest    = "newfundsreq"
        case rejectFundsRequest = "rejectfndreq"
        case addPublicAddress   = "addaddress"
    }
    
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
    
    public func isFioNameValid(fioName:String) -> Bool{
        let fullNameArr = fioName.components(separatedBy: ".")
        
        if (fullNameArr.count != 2) {
            return false
        }
        
        for namepart in fullNameArr {
            if (namepart.range(of:"[^A-Za-z0-9]",options: .regularExpression) != nil) {
                return false
            }
        }
        
        if (fullNameArr[0].count > 20){
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
    
    private struct SerializeJsonRequest<T: Codable>: Codable {
        let action: String
        let json: T
        
        enum CodingKeys: String, CodingKey {
            case action
            case json
        }
    }
    
    private struct SerializeJsonResponse: Codable {
        let json: String
        
        enum CodingKeys: String, CodingKey {
            case json = "serialized_json"
        }
    }
    
    //MARK: - Serialize JSON
    
    /**
     * Call serialize_json (POST) in order to serialize the given json object for an API action (ChainAction).
     * - Parameters:
     *      - json: A json object to serialize. Must implement Codable.
     *      - forAction: The API action (ChainActions) that will use the serialized json
     *      - onCompletion: A callback with either SerializeJsonResponse or FIOError as serialization result.
     */
    private func serializeJsonToData<T: Codable>(_ json: T, forAction action: ChainActions, onCompletion: @escaping (SerializeJsonResponse?, FIOError?) -> Void) {
        let toSerialize = SerializeJsonRequest(action: action.rawValue, json: json)
        let url = ChainRouteBuilder.build(route: ChainRoutes.serializeJSON)
        FIOHTTPHelper.postRequestTo(url, withBody: toSerialize) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(SerializeJsonResponse.self, from: data)
                    onCompletion(result, nil)
                }
                catch {
                    onCompletion(nil, FIOError(kind:.Failure, localizedDescription: "Parsing json serialize_json failed."))
                }
            } else {
                if let error = error {
                    onCompletion(nil, error)
                }
                else {
                    onCompletion(nil, FIOError(kind:.Failure, localizedDescription: "serialize_json request failed."))
                }
            }
        }
    }

    //MARK: - Signed Post Request
    
    private struct TxResult: Codable {
        var processed: TxResultProcessed?
    }
    
    private struct TxResultProcessed: Codable {
        var actionTraces: [TxResultActionTrace]
        
        enum CodingKeys: String, CodingKey {
            case actionTraces = "action_traces"
        }
    }
    
    private struct TxResultActionTrace: Codable{
        var receipt: TxResultReceipt
    }
    
    private struct TxResultReceipt: Codable{
        var response: AnyCodable
    }
    
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
                TransactionUtil.packAndSignTransaction(code: code, action: action.rawValue, data: result.json, account: account, privateKey: privateKey, completion: { (signedTx, error) in
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
    
    //MARK: - Register FIO Name Models
    private struct RegisterName: Codable {
        
        let fioName:String
        let actor:String
        
        enum CodingKeys: String, CodingKey {
            case fioName = "fioname"
            case actor = "actor"
        }
        
    }
    
    //MARK: - Register FIO Name request
    
    /**
     * This function should be called to register a new FIO Address (name)
     * - Parameter fioName: A string to register as FIO Address
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    private func register(fioName:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
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
        self.register(fioName: fioName, completion: { (error) in
            guard error == nil || error?.kind == .Success else {
                completion(error)
                return
            }
            #warning ("register fio name needs to be completed")
            //TODO: This must be reviwed by task MAS-137 when its unblocked
            var addresses:Dictionary<String,String> = publicReceiveAddresses
//            addresses["FIO"] = ""//newAccountName was generated by createAccountAddPermissions
            
            let dispatchGroup = DispatchGroup()
            var anyFail = false
            for (chain, receiveAddress) in addresses {
                dispatchGroup.enter()
                self.addPublicAddress(fioAddress: fioName, chain: chain, publicAddress: receiveAddress, completion: { (error) in
                    anyFail = error?.kind == .Failure
                    dispatchGroup.leave()
                })
            }
            
            dispatchGroup.notify(queue: .main){
                completion(FIOError.init(kind: anyFail ? .Failure : .Success, localizedDescription: ""))
            }
            //
        })
    }

    //MARK: -
    
    public func cancelRequestFunds (requestorAccountName:String, requestId:Int, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
       self.requestFunds.cancelFundsRequest(requestorAccountName: requestorAccountName, requestId: requestId, memo: memo) { (error) in
            completion(error)
        }
    }
    
    public func approveRequestFunds (requesteeAccountName:String, fioAppId:Int, obtId:String, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        self.requestFunds.approveFundsRequest(requesteeAccountName: requesteeAccountName, fioAppId: fioAppId, obtid:obtId, memo: memo) { (err) in
            completion(err)
        }
    }
    
    private func transfer(newAccountName:String){
        let account = getAccountName()
        let importedPk = try! PrivateKey(keyString: getPrivateKey())
        let transfer = Transfer()
        transfer.from = account
        transfer.to = newAccountName
        transfer.quantity = "200.0000 FIO"
        transfer.memo = "for register"
        
        Currency.transferCurrency(transfer: transfer, code: account, privateKey: importedPk!, completion: { (result, error) in
            if error != nil {
                if (error! as NSError).code == RPCErrorResponse.ErrorCode {
                    print("\(((error! as NSError).userInfo[RPCErrorResponse.ErrorKey] as! RPCErrorResponse).errorDescription())")
                } else {
                    print("other error: \(String(describing: error?.localizedDescription))")
                }
                
            } else {
                print("Ok.  Transfer Currency. Txid: \(result!.transactionId)")
                
            }
        })
    }
    
    //MARK: - Add Public Address

    /// Struct to use as DTO for the addpublic address method
    public struct AddPublicAddress: Codable {
        
        let fioAddress: String
        let tokenCode: String
        let publicAddress: String
        let actor: String
        
        enum CodingKeys: String, CodingKey {
            case fioAddress    = "fioaddress"
            case tokenCode     = "tokencode"
            case publicAddress = "pubaddress"
            case actor
        }
        
    }
    
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
    
    //MARK: -
    
    struct AvailCheckRequest: Codable {
        let fio_name: String
    }
    
    struct AvailCheckResponse: Codable {
        let fio_name: String
        let is_registered: Bool
    }
    
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
    
    
    
    /// getPendingFioRequest DTO response
    public struct PendingFioRequestsResponse: Codable {
       public let address: String
       public let requests: [PendingFioRequest]
        
        enum CodingKeys: String, CodingKey{
            case address = "fio_pub_address"
            case requests
        }
        
        /// PendingFioRequestsResponse.request DTO
        public struct PendingFioRequest: Codable{
            public let fundsRequestId: String
            public let fromFioAddress: String
            public let toFioAddress: String
            public let toPublicAddress: String
            public let amount: String
            public let tokenCode: String
            public let chainCode: String
            public let metadata: MetaData
            public let timeStamp: Date
            
            enum CodingKeys: String, CodingKey{
                case fundsRequestId = "fio_funds_request_id"
                case fromFioAddress = "from_fio_address"
                case toFioAddress = "to_fio_address"
                case toPublicAddress = "to_pub_address"
                case amount
                case tokenCode = "token_code"
                case chainCode = "chain_code"
                case metadata
                case timeStamp = "time_stamp"
            }
            
            public struct MetaData: Codable{
                public let memo: String
            }
        }
    }
    
    /// Pending requests call polls for any pending requests sent to a receiver.
    ///
    /// - Parameters:
    ///   - fioPublicAddress: FIO public address of new owner. Has to match signature
    ///   - completion: Completion hanlder
    public func getPendingFioRequests(fioPublicAddress: String, completion: @escaping (_ pendingRequests: PendingFioRequestsResponse?, _ error:FIOError?) -> ()) {
        

        var jsonData: Data
        do{
            jsonData = try JSONEncoder().encode(["fio_pub_address": fioPublicAddress])
        }catch {
            completion (nil, FIOError(kind: .Failure, localizedDescription: ""))
            return
        }
        
        let url = URL(string: "\(getMockURI() != nil ? getMockURI()! : getURI())/chain/get_pending_fio_requests")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion(nil, FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let result = try decoder.decode(PendingFioRequestsResponse.self, from: data)
                completion(result, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)
                completion(nil, err)
            }
        }
        
        task.resume()
    }
    
    
    /// DTO to represent the response of /get_fio_names
    public struct FioNamesResponse: Codable{
        public let publicAddress: String
        public let domains: [FioDomainResponse]
        public let addresses: [FioAddressResponse]
        
        enum CodingKeys: String, CodingKey {
            case publicAddress = "fio_pub_address"
            case domains = "fio_domains"
            case addresses = "fio_addresses"
        }
        
        public struct FioDomainResponse: Codable{
            public let domain: String
            private let _expiration: String
            
            public var expiration: Date{
                return Date(timeIntervalSince1970: (Double(_expiration) ?? 0))
            }
            
            enum CodingKeys: String, CodingKey{
                case domain = "fio_domain"
                case _expiration = "expiration"
            }
        }
        
        public struct FioAddressResponse: Codable{
            public let address: String
            private let _expiration: String
            
            public var expiration: Date{
                return Date(timeIntervalSince1970: (Double(_expiration) ?? 0))
            }
            
            enum CodingKeys: String, CodingKey{
                case address = "fio_address"
                case _expiration = "expiration"
            }
        }
    }
    
    /// Returns FIO Addresses and FIO Domains owned by this public address.
    ///
    /// - Parameters:
    ///   - publicAddress: FIO public address of new owner. Has to match signature
    ///   - completion: Completion handler
    public func getFioNames(publicAddress: String, completion: @escaping (_ names: FioNamesResponse?, _ error: FIOError?) -> ()){
        
        var jsonData: Data
        do{
            jsonData = try JSONEncoder().encode(["fio_pub_address": publicAddress])
        }catch {
            completion (nil, FIOError(kind: .Failure, localizedDescription: ""))
            return
        }
        
        let url = URL(string: "\(getMockURI() != nil ? getMockURI()! : getURI())/chain/get_fio_names")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion(nil, FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let result = try decoder.decode(FioNamesResponse.self, from: data)
                completion(result, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)
                completion(nil, err)
            }
        }
        
        task.resume()
    }
    
    
    /// Structure used as response body for getPublicAddress
    public struct PublicAddressResponse: Codable {
        
        /// FIO Address for which public address is returned.
        public let fioAddress: String
        
        /// Token code for which public address is returned.
        public let tokenCode: String
        
        /// public address for the specified FIO Address.
        public let publicAddress: String
        
        enum CodingKeys: String, CodingKey{
            case fioAddress = "fio_address"
            case tokenCode = "token_code"
            case publicAddress = "fio_pub_address"
        }
        
    }
    
    
    /// Returns a public address for a specified FIO Address, based on a given token for example ETH.
    /// example response:
    /// ```
    /// // example response
    /// let result: [String: String] =  ["fio_pub_address": "0xab5801a7d398351b8be11c439e05c5b3259aec9b", "token_code": "ETH", "fio_address": "purse.alice"]
    /// ```
    ///
    /// - Parameters:
    ///   - fioAddress: FIO Address for which public address is to be returned, e.g. "alice.brd"
    ///   - tokenCode: Token code for which public address is to be returned, e.g. "ETH".
    ///   - completion: result based on DTO PublicAddressResponse
    public func getPublicAddress(fioAddress: String, tokenCode: String, completion: @escaping (_ publicAddress: PublicAddressResponse?, _ error: FIOError) -> ()){
       
        var jsonData: Data
        
        do{
            jsonData = try JSONEncoder().encode(["fio_address": fioAddress, "token_code": tokenCode])
        }catch {
            completion (nil, FIOError(kind: .Failure, localizedDescription: ""))
            return
        }
        
        let url = URL(string: "\(getMockURI() != nil ? getMockURI()! : getURI())/chain/pub_address_lookup")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion(nil, FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(PublicAddressResponse.self, from: data)
                completion(result, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)
                completion(nil, err)
            }
        }
        
        task.resume()
    }
    
    //MARK: - Request Funds
    
    public struct RequestFundsRequest: Codable {
        
        public let from: String
        public let to: String
        public let toPublicAddress: String
        public let amount: String
        public let tokenCode: String
        public let metadata: String
        public let actor: String

        enum CodingKeys: String, CodingKey{
            case from = "fromfioadd"
            case to = "tofioadd"
            case toPublicAddress = "topubadd"
            case amount
            case tokenCode = "tokencode"
            case metadata
            case actor
        }
        
        public struct MetaData: Codable{
            public var memo: String?
            public var hash: String?
            public var offlineUrl: String?
            
            public init(memo: String?, hash: String?, offlineUrl: String?){
                self.memo = memo
                self.hash = hash
                self.offlineUrl = offlineUrl
            }
            
            enum CodingKeys: String, CodingKey {
                case memo
                case hash
                case offlineUrl = "offline_url"
            }
            
            func toJSONString() -> String {
                guard let json = try? JSONEncoder().encode(self) else {
                    return ""
                }
                return String(data: json, encoding: .utf8) ?? ""
            }
        }
        
    }
    
    public struct RequestFundsResponse: Codable {
        
        public var fundsRequestId: String {
            return String(fioreqid)
        }
        var fioreqid: Int //TODO: Change it back to String if Ed confirm it should be String
        
        enum CodingKeys: String, CodingKey {
            case fioreqid
        }
        
        init(fioreqid: Int) {
            self.fioreqid = fioreqid
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let fioreqid: Int = try container.decodeIfPresent(Int.self, forKey: .fioreqid) ?? 0
            
            self.init(fioreqid: fioreqid)
        }
        
    }
    
    /// Creates a new funds request.
    /// To read further infomation about this [visit the API specs] [1]
    ///
    ///    [1]: https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/new_funds_request-Createnewfundsrequest        "api specs"
    ///
    /// - Parameters:
    ///   - fromFioAddress: FIO Address of user sending funds, i.e. requestee.brd
    ///   - toFioAddress: FIO Address of user receiving funds, i.e. requestor.brd
    ///   - publicAddress: Public address on other blockchain of user receiving funds.
    ///   - amount: Amount requested.
    ///   - tokenCode: Code of the token represented in Amount requested, i.e. ETH
    ///   - metadata: Contains the: memo or hash or offlineUrl (they are mutually excludent, fill only one)
    ///   - completion: The completion handler containing the result
    public func requestFunds(from fromFioAddress:String, to toFioAddress: String, toPublicAddress publicAddress: String, amount: String, tokenCode: String, metadata: RequestFundsRequest.MetaData, completion: @escaping ( _ response: RequestFundsResponse?, _ error:FIOError? ) -> ()) {
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let data = RequestFundsRequest(from: fromFioAddress, to: toFioAddress, toPublicAddress: publicAddress, amount: amount, tokenCode: tokenCode, metadata: metadata.toJSONString(), actor: actor)
        
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
    
    private struct RejectFundsRequest: Codable {
        var fioReqID: String
        var actor: String
            
        enum CodingKeys: String, CodingKey {
            case fioReqID = "fioreqid"
            case actor
        }
    }

    public struct RejectFundsRequestResponse: Codable{
        
        var fioReqID: String
        var status: Status
        
        enum CodingKeys: String, CodingKey {
            case fioReqID = "fioreqid"
            case status
        }
        
        enum Status: String, Codable{
            case rejected = "request_rejected", unknown
        }
        
        
    }
    
    /// Reject funds request.
    /// To read further infomation about this [visit the API specs] [1]
    ///
    ///    [1]: https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/reject_funds_request-Rejectfundsrequest        "api specs"
    ///
    /// - Parameters:
    ///   - fundsRequestId: ID of that fund request.
    ///   - completion: The completion handler containing the result or error.
    public func rejectFundsRequest(fundsRequestId: String, completion: @escaping(_ response: RejectFundsRequestResponse?,_ :FIOError) -> ()){
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
                                let handledData: (response: RejectFundsRequestResponse?, error: FIOError) = self.parseResponseFromTransactionResult(txResult: result)
                                guard handledData.response?.status == .rejected else {
                                    completion(nil, FIOError.init(kind: .Failure, localizedDescription: "The request couldn't rejected"))
                                    return
                                }
                                completion(handledData.response, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
        }
    }
    
    //MARK: -
    
    public struct SentFioRequestResponse: Codable{
        public let publicAddress: String
        public let requests: [SentFioRequest]
        
        enum CodingKeys: String, CodingKey{
            case publicAddress = "fio_pub_address"
            case requests
        }
        
        /// PendingFioRequestsResponse.request DTO
        public struct SentFioRequest: Codable{
            public let fundsRequestId: String
            public let fromFioAddress: String
            public let toFioAddress: String
            public let toPublicAddress: String
            public let amount: String
            public let tokenCode: String
            public let chainCode: String
            public let metadata: MetaData
            public let timeStamp: Date
            public let status: String
            
            enum CodingKeys: String, CodingKey{
                case fundsRequestId = "fio_funds_request_id"
                case fromFioAddress = "from_fio_address"
                case toFioAddress = "to_fio_address"
                case toPublicAddress = "to_pub_address"
                case amount
                case tokenCode = "token_code"
                case chainCode = "chain_code"
                case metadata
                case timeStamp = "time_stamp"
                case status
            }
            
            public struct MetaData: Codable{
                public let memo: String
            }
        }
    }
    
    
    /// Sent requests call polls for any requests sent be sender.
    /// To read further infomation about this [visit the API specs] [1]
    ///
    ///    [1]: https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/get_sent_fio_requests-GetFIORequestssentout        "api specs"
    /// - Parameters:
    ///   - publicAddress: FIO public address of owner.
    ///   - completion: The completion result
    public func getSentFioRequest(publicAddress: String, completion: @escaping (_ response: SentFioRequestResponse?, _ error: FIOError) -> ()){
        
        var jsonData: Data
        
        do{
            jsonData = try JSONEncoder().encode(["fio_pub_address": publicAddress])
        }catch {
            completion (nil, FIOError(kind: .Failure, localizedDescription: ""))
            return
        }
        
        let url = URL(string: "\(getMockURI() != nil ? getMockURI()! : getURI())/chain/get_sent_fio_requests")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion(nil, FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let result = try decoder.decode(SentFioRequestResponse.self, from: data)
                completion(result, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)
                completion(nil, err)
            }
        }
        
        task.resume()
    }
}

extension FIOSDK.RejectFundsRequestResponse.Status{
    public init(from decoder: Decoder) throws {
        self = try FIOSDK.RejectFundsRequestResponse.Status(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}
