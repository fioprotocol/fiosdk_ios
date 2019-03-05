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
        case serializeJSON   = "/chain/serialize_json"
        case registerFIOName = "/chain/register_fio_name"
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
        case registerFIOName = "registername"
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
    
    private struct SerializeJsonRequest: Codable {
        let action: String
        let json: [String:String]
        
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

    //MARK: - Signed Post Request
    
    /**
     * This function does a signed post request to our API. It uses TransactionUtil.packAndSignTransaction to pack and sign body before doing the POST request to the required route.
     * - Parameters:
     *      - route: The route to be requested. Look at ChainRoutes for possible values
     *      - action: The API action for the given request. Look at ChainActions for possible values
     *      - body: The request body parameters to be serialized and sent as a data string
     *      - privateKey: A PrivateKey to sign the post request
     *      - code: The code required for packing and signing a transaction, for more info look at TransactionUtil.packAndSignTransaction
     *      - account: The account required for packing and signing a transaction, for more info look at TransactionUtil.packAndSignTransaction
     *      - onCompletion: A callback function that is called when request is finished with is Data value and either with success or failure, both values are optional. Check FIOError.kind to determine if is a success or a failure.
     */
    private func signedPostRequestTo(route: ChainRoutes, forAction action: ChainActions, withBody body: [String:String], privateKey: PrivateKey, code: String, account: String, onCompletion: @escaping (_ result: Data?, FIOError?) -> Void) {
        let toSerialize = SerializeJsonRequest(action: action.rawValue, json: body)
        let url = ChainRouteBuilder.build(route: ChainRoutes.serializeJSON)
        FIOHTTPHelper.postRequestTo(url, withBody: toSerialize) { (data, error) in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(SerializeJsonResponse.self, from: data)
                    print(result)
                    TransactionUtil.packAndSignTransaction(code: code, action: action.rawValue, data: result.json, account: account, privateKey: privateKey, completion: { (signedTx, error) in
                        if let error = self.translateErrorToFIOError(error: error) {
                            onCompletion(nil, error)
                        }
                        else {
                            print("Called FIOSDK action: " + action.rawValue)
                            let url = ChainRouteBuilder.build(route: route)
                            FIOHTTPHelper.postRequestTo(url, withBody: signedTx, onCompletion: { (data, error) in
                                onCompletion(data, error)
                            })
                        }
                    })
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
        
        func toDictionary() -> [String: String] {
            return [CodingKeys.fioName.rawValue:fioName, CodingKeys.actor.rawValue:actor]
        }
        
    }
    
    //MARK: - Register FIO Name request
    
    /**
     * This function should be called to register a new FIO Address (name)
     * - Parameter fioName: A string to register as FIO Address
     * - Parameter completion: A callback function that is called when request is finished either with success or failure. Check FIOError.kind to determine if is a success or a failure.
     */
    private func register(fioName:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        guard let importedPk = try! PrivateKey(keyString: getSystemPrivateKey()) else {
            completion(FIOError(kind: .FailedToUsePrivKey, localizedDescription: "Failed to retrieve private key."))
            return
        }
        
        let actor = AccountNameGenerator.run(withPublicKey: getSystemPublicKey())
        let registerName = RegisterName(fioName: fioName, actor: actor).toDictionary()
        signedPostRequestTo(route: ChainRoutes.registerFIOName,
                            forAction: ChainActions.registerFIOName,
                            withBody: registerName,
                            privateKey: importedPk,
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
            addresses["FIO"] = ""//newAccountName was generated by createAccountAddPermissions
            
            let dispatchGroup = DispatchGroup()
            var anyFail = false
            for (chain, receiveAddress) in addresses{
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

    /// Struct to use as DTO for the addpublic address method
    public struct AddPublicAddress: Codable{
        let fioAddress: String
        let chain: String
        let publicAddress: String
        
        enum CodingKeys: String, CodingKey {
            case fioAddress =  "fio_address"
            case chain
            case publicAddress = "pub_address"
        }
    }
    
    
    /// SDK method that calls the addpubaddrs from the fio
    /// to read further information about the API visit https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/add_pub_address-Addaddress
    ///
    /// - Parameters:
    ///   - fioAddress:
    ///   - chain:
    ///   - publicAddress:
    ///   - completion: The completion handler, providing an optional error in case something goes wrong
    public func addPublicAddress(fioAddress:String, chain:String, publicAddress: String, completion: @escaping ( _ error:FIOError? ) -> ()) {
        let importedPk = try! PrivateKey(keyString: getSystemPrivateKey())
        let data = AddPublicAddress(fioAddress: fioAddress, chain: chain, publicAddress: publicAddress)
        
        var jsonString: String
        do{
            let jsonData:Data = try JSONEncoder().encode(data)
            jsonString = String(data: jsonData, encoding: .utf8)!
            print(jsonString)
        }catch {
            completion (FIOError(kind: .Failure, localizedDescription: "Json for input data not wrapping correctly"))
            return
        }
        
        let abi = try! AbiJson(code: "fio.system", action: "addpubaddrs", json: jsonString)
        
        TransactionUtil.pushTransaction(abi: abi, account: "fio.system", privateKey: importedPk!, completion: { (result, error) in
            
            guard let result = result, error == nil else {
                if (error! as NSError).code == RPCErrorResponse.ErrorCode {
                    let errDescription = "error"
                    print (errDescription)
                    completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                } else {
                    let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
                    print (errDescription)
                    completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                }
                return
            }
            
            print("Ok. add public address, Txid: \(result.transactionId)")
            completion(FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
        })
    }
    
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
    
    
    public struct RequestFundsRequest: Codable{
        public let from: String
        public let to: String
        public let toPublicAddress: String
        public let amount: String
        public let tokenCode: String
        public let metadata: String //TODO: changes this type to -> MetaData
        
        enum CodingKeys: String, CodingKey{
            case from = "from_fio_address"
            case to = "to_fio_address"
            case toPublicAddress = "to_pub_address"
            case amount
            case tokenCode = "token_code"
            case metadata
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
        }
    }
    
    public struct RequestFundsResponse: Codable{
        public var fundsRequestId: String
        
        enum CodingKeys: String, CodingKey {
            case fundsRequestId = "fio_funds_request_id"
        }
    }
    
    
    /// Creates a new funds request.
    /// To read further infomation about this [visit the API specs] [1]
    ///
    ///    [1]: https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/new_funds_request-Createnewfundsrequest        "api specs"
    ///
    /// - Parameters:
    ///   - fromFioAddress: FIO Address of user sending funds, i.e. requestee
    ///   - toFioAddress: FIO Address of user receiving funds, i.e. requestor
    ///   - publicAddress: Public address on other blockchain of user receiving funds.
    ///   - amount: Amount requested.
    ///   - tokenCode: Code of the token represented in Amount requested, i.e. ETH
    ///   - metadata: Contains the: memo, hash, offlineUrl
    ///   - completion: The completion handler containing the result
    public func requestFunds(from fromFioAddress:String, to toFioAddress: String, toPublicAddress publicAddress: String, amount: String, tokenCode: String, metadata: RequestFundsRequest.MetaData, completion: @escaping ( _ response: RequestFundsResponse?, _ error:FIOError? ) -> ()) {
        let importedPk = try! PrivateKey(keyString: getSystemPrivateKey())
        let data = RequestFundsRequest(from: fromFioAddress, to: toFioAddress, toPublicAddress: publicAddress, amount: amount, tokenCode: tokenCode, metadata: "")
        
        
        var jsonString: String
        do{
            let jsonData:Data = try JSONEncoder().encode(data)
            jsonString = String(data: jsonData, encoding: .utf8)!
            print(jsonString)
        }catch {
            completion (nil, FIOError(kind: .Failure, localizedDescription: "Json for input data not wrapping correctly"))
            return
        }
        
        let abi = try! AbiJson(code: "fio.system", action: "newfndsreq", json: jsonString)
        
        TransactionUtil.pushTransaction(abi: abi, account: "fio.system", privateKey: importedPk!, completion: { (result, error) in
            
            guard let result = result, error == nil else {
                if (error! as NSError).code == RPCErrorResponse.ErrorCode {
                    let errDescription = "error"
                    print (errDescription)
                    completion(nil, FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                } else {
                    let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
                    print (errDescription)
                    completion(nil, FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                }
                return
            }
            print("Ok. newfndsreq, Txid: \(result.transactionId)")
            guard let responseString = result.processed?.actionTraces.first?.receipt.response.value as? String, let responseData = responseString.data(using: .utf8), let response = try? JSONDecoder().decode(RequestFundsResponse.self, from: responseData) else{
                completion(nil, FIOError.init(kind: .Failure, localizedDescription: "Error parsing the response"))
                return
            }
            completion(response, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
        })
    }
    
    public struct RejectFundsRequestResponse: Codable{
        
        public var status: Status
        
        public enum Status: String, Codable{
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
    ///   - completion: The completion handler containing the result
    public func rejectFundsRequest(fundsRequestId: String, completion: @escaping(_ response: RejectFundsRequestResponse?,_ :FIOError) -> ()){
        let importedPk = try! PrivateKey(keyString: getSystemPrivateKey())
        
        var jsonString: String
        do{
            let jsonData:Data = try JSONEncoder().encode(["fio_funds_request_id": fundsRequestId])
            jsonString = String(data: jsonData, encoding: .utf8)!
        }catch {
            completion (nil, FIOError(kind: .Failure, localizedDescription: "Json for input data not wrapping correctly"))
            return
        }
        
        let abi = try! AbiJson(code: "fio.system", action: "rejctfndsreq", json: jsonString)
        
        TransactionUtil.pushTransaction(abi: abi, account: "fio.system", privateKey: importedPk!, completion: { (result, error) in
            
            guard let result = result, error == nil else {
                if (error! as NSError).code == RPCErrorResponse.ErrorCode {
                    let errDescription = "error"
                    print (errDescription)
                    completion(nil, FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                } else {
                    let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
                    print (errDescription)
                    completion(nil, FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                }
                return
            }
            print("Ok. newfndsreq, Txid: \(result.transactionId)")
            guard let responseString = result.processed?.actionTraces.first?.receipt.response.value as? String, let responseData = responseString.data(using: .utf8), let response = try? JSONDecoder().decode(RejectFundsRequestResponse.self, from: responseData) else{
                completion(nil, FIOError.init(kind: .Failure, localizedDescription: "Error parsing the response"))
                return
            }
            
            guard response.status == .rejected else {
                completion(nil, FIOError.init(kind: .Failure, localizedDescription: "The request couldn't rejected"))
                return
            }
            
            completion(response, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
        })
    }
    
    
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
