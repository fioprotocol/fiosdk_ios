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
    
    public func requestFundsByAddress (requestorAddress:String, requestorCurrencyCode:String, requesteeFioName:String, chain:String, asset:String, amount:Float, memo:String, completion: @escaping (_ error:FIOError?) -> ()) {

        self.getFioNames(publicAddress: requestorAddress) { (response, error) in
            guard error?.kind == .Success, let responseAddress = response?.addresses.first?.address else{
                completion(error)
                return
            }
            
            self.requestFundsByFioName(requestorFioName: responseAddress
                , requesteeFioName: requesteeFioName
                , chain: chain
                , asset: asset
                , amount: amount
                , memo: memo
                , completion: { (err) in
                    completion(err)
            })
        }
    }
    
    public func requestFundsByFioName (requestorFioName:String, requesteeFioName:String, chain:String, asset:String, amount:Float, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        self.getPublicAddress(fioAddress: requestorFioName, tokenCode: "FIO") { (response, error) in
            guard error.kind == .Success, let requestorPublicAddress = response?.publicAddress else{
                completion(error)
                return
            }
            self.getPublicAddress(fioAddress: requesteeFioName, tokenCode: "FIO", completion: { (response, error) in
                guard error.kind == .Success, let requesteePublicAddress = response?.publicAddress else{
                    completion(error)
                    return
                }
                self.requestFunds(requestorAccountName: requestorPublicAddress, requesteeAccountName: requesteePublicAddress, chain: "FIO", asset: asset, amount: amount, memo: memo
                    , completion: { (errRequestFunds) in
                        completion(errRequestFunds)
                })
            })
        }
    }
    
    private func requestFunds (requestorAccountName:String, requesteeAccountName:String, chain:String, asset:String, amount:Float, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        let timestamp = NSDate().timeIntervalSince1970
        self.requestFunds.requestFunds(requestorAccountName: requestorAccountName, requestId: Int(timestamp.rounded()) ,requesteeAccountName: requesteeAccountName, chain: chain, asset: asset, amount: amount, memo: memo) { (error) in
            completion(error)
        }
    }

    private struct RegisterName: Codable {
        let fioName:String
        
        enum CodingKeys: String, CodingKey {
            case fioName = "fio_name"
        }
    }
    
    private func register(fioName:String, newAccountName:String, publicReceiveAddresses:Dictionary<String,String>, completion: @escaping ( _ error:FIOError?) -> ()) {
        let importedPk = try! PrivateKey(keyString: getSystemPrivateKey())
        let data = RegisterName(fioName: fioName)
        
        var jsonString: String
        do{
            let jsonData:Data = try JSONEncoder().encode(data)
            jsonString = String(data: jsonData, encoding: .utf8)!
            print(jsonString)
        }catch {
            completion (FIOError(kind: .Failure, localizedDescription: "Json for input data not wrapping correctly"))
            return
        }
        
        let abi = try! AbiJson(code: "fio.system", action: "rgstrfioname", json: jsonString)
        print("Called FIOSDK action rgstrfioname")
        TransactionUtil.pushTransaction(abi: abi, account: "fio.system", privateKey: importedPk!, completion: { (result, error) in
            if error != nil {
                if (error! as NSError).code == RPCErrorResponse.ErrorCode {
                    let errDescription = "error"
                    print (errDescription)
                    completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                } else {
                    let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
                    print (errDescription)
                    completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                }
            } else {
                print("Ok. RegisterName, Txid: \(result!.transactionId)")
                
                var addresses:Dictionary<String,String> = publicReceiveAddresses
                addresses["FIO"] = newAccountName
                
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
            }
        })
    }
    
    public func registerFioName (fioName:String, publicReceiveAddresses:Dictionary<String,String>, completion: @escaping ( _ error:FIOError?) -> ()) {
        self.createAccountAddPermissions(completion: { (newAccountName, error) in
            if (error?.kind == FIOError.ErrorKind.Success){
                
                self.register(fioName: fioName,newAccountName: newAccountName, publicReceiveAddresses: publicReceiveAddresses, completion: { (error) in
                    completion(error)
                })

            }
            else{
                completion(error)
            }
        })
    }

    public func rejectRequestFunds (requesteeAccountName:String, fioAppId:Int, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        self.requestFunds.rejectFundsRequest(requesteeAccountName: requesteeAccountName, fioAppId: fioAppId, memo: memo) { (err) in
            completion(err)
        }
    }

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
    
    public func getRequestorHistoryByAddress (address:String, currencyCode:String, maxItemsReturned:Int, completion: @escaping ( _ requests:[FIOSDK.Request] , _ error:FIOError?) -> ()) {
        self.getFioNames(publicAddress: address) { (response, error) in
            guard error?.kind == .Success, let responseAddress = response?.addresses.first?.address else{
                completion([FIOSDK.Request](), error)
                return
            }
            self.getRequestorHistoryByFioName(fioName: responseAddress, currencyCode: currencyCode
                , maxItemsReturned: maxItemsReturned
                , completion: { (responses, err) in
                    completion(responses,err)
            })
        }
    }
    
    public func getRequestorHistoryByFioName (fioName:String, currencyCode:String, maxItemsReturned:Int, completion: @escaping ( _ requests:[FIOSDK.Request] , _ error:FIOError?) -> ()) {
        self.getPublicAddress(fioAddress: fioName, tokenCode: "FIO") { (response, error) in
            guard error.kind == .Success, let publicAddress = response?.publicAddress else{
                completion([FIOSDK.Request](), error)
                return
            }
            self.requestFunds.getRequestorHistory(requestorAccountName: publicAddress, currencyCode: currencyCode, maxItemsReturned: maxItemsReturned
                , completion: { (response, error) in
                    
                    guard error?.kind == .Success else{
                        completion([FIOSDK.Request](),error)
                        return
                    }
                    
                    completion(response, error)
            })
        }
    }
    
    private func createAccountAddPermissions(completion: @escaping ( _ newAccountName:String, _ error:FIOError?) -> ()) {
        getValidNewAccountName { (newAccountName, error) in
            if (newAccountName != nil && newAccountName!.count > 0){
                self.createAccount(newAccountName: newAccountName!, completion: { (error) in
                    if (error?.kind == FIOError.ErrorKind.Success){
                        self.addAccountPermissions(accountName: newAccountName!, completion: { (error) in
                            completion(newAccountName!, error)
                        })
                    }
                    else{
                        completion("", error)
                    }
                })
            }
            else{
                completion("", error)
            }
        }
    }
    
    // try 4 times.
    private func getValidNewAccountName(completion: @escaping (_ newAccountName: String?, _ error:FIOError?) -> ()) {
        
        var accountName = createRandomAccountName()
        self.getAccount(accountName: accountName ) { (account, error) in
            if (account == nil){
                completion(accountName, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
            }
            else {
                accountName = self.createRandomAccountName()
                self.getAccount(accountName: accountName) { (account, error) in
                    if (account == nil){
                        completion(accountName, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
                    }
                    else {
                        accountName = self.createRandomAccountName()
                        self.getAccount(accountName: accountName) { (account, error) in
                            if (account == nil){
                                completion(account?.accountName, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
                            }
                            else {
                                accountName = self.createRandomAccountName()
                                self.getAccount(accountName: accountName) { (account, error) in
                                    if (account == nil){
                                        completion(account?.accountName, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
                                    }
                                    else {
                                        completion(nil, FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: "Unable to find a new random account for register name"))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    struct KeyValues : Codable {
        let key:String
        let weight: Int
    }
    
    struct PermissionValues: Codable {
        let actor: String
        let permission: String
    }
    
    struct AccountValues : Codable {
        let permission:PermissionValues
        let weight:Int
    }
    
    struct AuthValue : Codable{
        let threshold:Int
        let keys:[KeyValues]
        let accounts:[AccountValues]
        let waits:[String]
    }
    
    struct PermissionAccount: Codable{
        let account: String
        let permission: String
        let parent: String
        let auth:AuthValue
    }
 
    // so, the public key of fio.system needs to go into permission... permission then register name
    
    public func addAccountPermissions(accountName : String, completion: @escaping ( _ error:FIOError?) -> ()) {
        // try fio.system as well
        let importedPk = try! PrivateKey(keyString: getPrivateKey())
        
        let data = PermissionAccount(account: getAccountName(), permission: "active", parent: "owner"
                        , auth:AuthValue(threshold: 1, keys: [KeyValues(key: getPublicKey() , weight: 1)]
                                                    , accounts:[AccountValues(permission: FIOSDK.PermissionValues(actor: "fio.system", permission: "eosio.code"), weight: 1)]
                                                    , waits:[]))
        
        var jsonString: String = ""
        do{
            let jsonData:Data = try JSONEncoder().encode(data)
            jsonString = String(data: jsonData, encoding: .utf8)!
            print(jsonString)
        }catch {
           completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: "Unable to serialize JSON for addaccountpermissions"))
        }
        
        let abi = try! AbiJson(code: "eosio", action: "updateauth", json: jsonString)
        
        print ("***")
        print(abi.code)
        print(abi.action)
        print(data)
        print ("***")
        TransactionUtil.pushTransaction(abi: abi, account: getAccountName(), privateKey: importedPk!, completion: { (result, error) in
            if error != nil {
                if (error! as NSError).code == RPCErrorResponse.ErrorCode {
                    let errDescription = "error"
                    print (errDescription)
                    completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                } else {
                    let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
                    print (errDescription)
                    completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                }
            } else {
                print("Ok. Add account permissions worked, Txid: \(result!.transactionId)")
                completion(FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
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
    
    private func createAccount(newAccountName:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        print(newAccountName)
        
        AccountUtil.createAccount(account: newAccountName, ownerKey:getSystemPublicKey() , activeKey: getSystemPublicKey(), creator: "fio.system", pkString: getSystemPrivateKey()) { (result, error) in
            if error != nil {
                if (error! as NSError).code == RPCErrorResponse.ErrorCode {
                    let errDescription = "error"
                    print (errDescription)
                    completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                } else {
                    let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
                    print (errDescription)
                    completion(FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
                }
            } else {
                print("Ok. new account, Txid: \(result!.transactionId)")
                completion(FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: "Successfully created the new account"))
            }
        }
        
    }
    
    public func getAccount(accountName:String, completion: @escaping (_ account: Account?, _ error:FIOError?) -> ()) {
        EOSRPC.sharedInstance.getAccount(account: accountName) { (account, error) in
            if (account != nil){
               completion(account, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: "Successfully got the new account"))
            }
            else {
                let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
                print (errDescription)
                completion(nil, FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: errDescription))
            }
        }
    }
    
    public func createRandomAccountName() -> String{
        return Utilities.sharedInstance().randomStringCharsOnly(length: 1) +      Utilities.sharedInstance().randomString(length:11)
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
            public let fioObtId: String
            public let fromFioAddress: String
            public let toFioAddress: String
            public let toPublicAddress: String
            public let amount: String
            public let chain: String
            public let metadata: String
            public let status: RequestStatus
            public let timeStamp: Date
            
            enum CodingKeys: String, CodingKey{
                case fioObtId = "fio_obt_id"
                case fromFioAddress = "from_fio_address"
                case toFioAddress = "to_fio_address"
                case toPublicAddress = "to_pub_address"
                case amount
                case chain
                case metadata
                case status
                case timeStamp = "time_stamp"
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
            
            enum CodingKeys: String, CodingKey {
                case memo
                case hash
                case offlineUrl = "offline_url"
            }
        }
    }
    
    
    /// Creates a new funds request.
    /// to read further information about the API visit https://stealth.atlassian.net/wiki/spaces/DEV/pages/53280776/API#API-/new_funds_request-Createnewfundsrequest
    ///
    /// - Parameters:
    ///   - fromFioAddress: FIO Address of user sending funds, i.e. requestee
    ///   - toFioAddress: FIO Address of user receiving funds, i.e. requestor
    ///   - publicAddress: Public address on other blockchain of user receiving funds.
    ///   - amount: Amount requested.
    ///   - tokenCode: Code of the token represented in Amount requested, i.e. DAI
    ///   - metadata: Contains the: memo, hash, offlineUrl
    ///   - completion: The completion handler containing the result
    public func requestFunds(from fromFioAddress:String, to toFioAddress: String, toPublicAddress publicAddress: String, amount: String, tokenCode: String, metadata: RequestFundsRequest.MetaData, completion: @escaping ( _ error:FIOError? ) -> ()) {
        let importedPk = try! PrivateKey(keyString: getSystemPrivateKey())
        let data = RequestFundsRequest(from: fromFioAddress, to: toFioAddress, toPublicAddress: publicAddress, amount: amount, tokenCode: tokenCode, metadata: "")
        
        
        var jsonString: String
        do{
            let jsonData:Data = try JSONEncoder().encode(data)
            jsonString = String(data: jsonData, encoding: .utf8)!
            print(jsonString)
        }catch {
            completion (FIOError(kind: .Failure, localizedDescription: "Json for input data not wrapping correctly"))
            return
        }
        
        let abi = try! AbiJson(code: "fio.system", action: "newfndsreq", json: jsonString)
        
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
            print("Ok. newfndsreq, Txid: \(result.transactionId)")
            completion(FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
        })
    }
}
