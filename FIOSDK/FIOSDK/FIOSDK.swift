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
    
    struct AddressByNameRequest: Codable {
        let fio_name: String
        let chain: String
        let requestor: String
    }
    
    public struct AddressByNameResponse: Codable {
        let is_registered: String
        let is_domain: String
        public let address: String
        
        var isRegistered:Bool{
            get { return (is_registered == "true" ? true : false) }
        }
        
        var isDomain:Bool{
            get { return (is_domain == "true" ? true : false) }
        }
    }
    
    struct NameByAddressRequest: Codable {
        let key: String
        let chain: String
    }
    
    public struct NameByAddressResponse: Codable {
        public let name: String
        public let expiration: String
    }
    
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
    
    public enum RequestStatus:String {
        case Requested = "Requested"
        case Rejected = "Rejected"
        case Approved = "Approved"
    }
    
    private static var _sharedInstance: FIOSDK = {
        let sharedInstance = FIOSDK()
        
        return sharedInstance
    }()
    
    public class func sharedInstance(accountName: String? = nil, privateKey:String? = nil, publicKey:String? = nil, systemPrivateKey:String?=nil, systemPublicKey:String? = nil, url:String? = nil) -> FIOSDK {
        
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
    
    internal func getPublicKey() -> String {
        return self.publicKey
    }
    
    public func getAddressByFioName (fioName:String, currencyCode:String, completion: @escaping (_ fioLookupResults: AddressByNameResponse, _ error:FIOError?) -> ()) {
    
        var responseStruct : AddressByNameResponse = AddressByNameResponse(is_registered: "", is_domain: "", address: "")
        
        let fioRequest = AddressByNameRequest(fio_name: fioName, chain:currencyCode, requestor:getAccountName())
        var jsonData: Data
        do{
            jsonData = try JSONEncoder().encode(fioRequest)
        }catch {
            completion (responseStruct, FIOError(kind: .NoDataReturned, localizedDescription: ""))
            return
        }
        
        // create post request
        let url = URL(string: getURI() + "/chain/fio_name_lookup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion(responseStruct, FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
                responseStruct = try JSONDecoder().decode(AddressByNameResponse.self, from: data)
                completion(responseStruct, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)///TODO:create this correctly with ERROR results
                completion(responseStruct, err)
            }
        }
   
        task.resume()
    }
 
    public func getFioNameByAddress (publicAddress:String, currencyCode:String, completion: @escaping (_ fioLookupResults: NameByAddressResponse, _ error:FIOError?) -> ()) {
        
        var fioRsvp : NameByAddressResponse = NameByAddressResponse(name: "", expiration: "11111111")
        
        let fioRequest = NameByAddressRequest(key: publicAddress, chain:currencyCode)
        var jsonData: Data
        do{
            jsonData = try JSONEncoder().encode(fioRequest)
        }catch {
            completion (fioRsvp, FIOError(kind: .NoDataReturned, localizedDescription: ""))
            return
        }
        
        // create post request
        let url = URL(string: getURI() + "/chain/fio_key_lookup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
   
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion(fioRsvp, FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
                let result = String(data: data, encoding: String.Encoding.utf8) as String!
                print(result)
                
                fioRsvp = try JSONDecoder().decode(NameByAddressResponse.self, from: data)
                print(fioRsvp)
                
                
                completion(fioRsvp, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)///TODO:create this correctly with ERROR results
                completion(fioRsvp, err)
            }
        }
        
        task.resume()
    }
    
    public func requestFundsByAddress (requestorAddress:String, requestorCurrencyCode:String, requesteeFioName:String, chain:String, asset:String, amount:Float, memo:String, completion: @escaping (_ error:FIOError?) -> ()) {

        self.getFioNameByAddress(publicAddress: requestorAddress, currencyCode:requestorCurrencyCode) { (response, error) in
            if (error?.kind == FIOError.ErrorKind.Success){
               self.requestFundsByFioName(requestorFioName: response.name
                    , requesteeFioName: requesteeFioName
                    , chain: chain
                    , asset: asset
                    , amount: amount
                    , memo: memo
                    , completion: { (err) in
                        completion(err)
                   })
            }
            else {
                completion(error)
            }
        }
    }
    
    public func requestFundsByFioName (requestorFioName:String, requesteeFioName:String, chain:String, asset:String, amount:Float, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        self.getAddressByFioName(fioName: requestorFioName, currencyCode: "FIO") { (response, error) in
            if (error?.kind == FIOError.ErrorKind.Success){
                let requestorAccountName = response.address
                
                self.getAddressByFioName(fioName: requesteeFioName, currencyCode: "FIO", completion: { (res, er) in
                    if (er?.kind == FIOError.ErrorKind.Success){
                        self.requestFunds(requestorAccountName: requestorAccountName, requesteeAccountName: res.address, chain: "FIO", asset: asset, amount: amount, memo: memo
                            , completion: { (errRequestFunds) in
                                completion(errRequestFunds)
                        })
                    }
                    else {
                        completion(er)
                    }
                })
            }
            else{
                completion(error)
            }
        }
    }
    
    private func requestFunds (requestorAccountName:String, requesteeAccountName:String, chain:String, asset:String, amount:Float, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        let timestamp = NSDate().timeIntervalSince1970
        self.requestFunds.requestFunds(requestorAccountName: requestorAccountName, requestId: Int(timestamp.rounded()) ,requesteeAccountName: requesteeAccountName, chain: chain, asset: asset, amount: amount, memo: memo) { (error) in
            completion(error)
        }
    }

    private struct RegisterName: Codable {
        let name:String
        let requestor:String
    }
    
    private func register(fioName:String, newAccountName:String, publicReceiveAddresses:Dictionary<String,String>, completion: @escaping ( _ error:FIOError?) -> ()) {
        let importedPk = try! PrivateKey(keyString: getSystemPrivateKey())
        let data = RegisterName(name: fioName, requestor: "fio.system")
        
        var jsonString: String
        do{
            let jsonData:Data = try JSONEncoder().encode(data)
            jsonString = String(data: jsonData, encoding: .utf8)!
            print(jsonString)
        }catch {
            completion (FIOError(kind: .Failure, localizedDescription: "Json for input data not wrapping correctly"))
            return
        }
       
        let abi = try! AbiJson(code: "fio.system", action: "registername", json: jsonString)
        
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
                
                self.addAllPublicAddresses(fioName: fioName, publicReceiveAddresses: addresses, completion: { (error) in
                    completion(error)
                })
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
    
    public func getRequesteePendingHistoryByAddress (address:String, currencyCode:String, maxItemsReturned:Int, completion: @escaping ( _ requests:[FIOSDK.Request] , _ error:FIOError?) -> ()) {
        self.getFioNameByAddress(publicAddress: address, currencyCode: currencyCode) { (response, error) in
            if (error?.kind == FIOError.ErrorKind.Success){
                self.getRequesteePendingHistoryByFioName(fioName: response.name
                    , maxItemsReturned: maxItemsReturned
                    , completion: { (responses, err) in
                        completion(responses,err)
                })
            }
            else {
                completion([FIOSDK.Request](),error)
            }
        }
    }
    
    public func getRequesteePendingHistoryByFioName (fioName:String, maxItemsReturned:Int, completion: @escaping ( _ requests:[FIOSDK.Request] , _ error:FIOError?) -> ()) {
        self.getAddressByFioName(fioName: fioName, currencyCode: "FIO") { (response, error) in
            if (error?.kind == FIOError.ErrorKind.Success){
                self.requestFunds.getRequesteePendingHistory(requesteeAccountName: response.address,maxItemsReturned: maxItemsReturned
                    , completion: { (responses, err) in
                        
                        if (err?.kind == FIOError.ErrorKind.Success){
                            completion(responses, err)
                        }
                        else{
                            completion([FIOSDK.Request](),error)
                        }
                })
            }
            else {
                completion([FIOSDK.Request](),error)
            }
        }
    }
    
    public func getRequestorHistoryByAddress (address:String, currencyCode:String, maxItemsReturned:Int, completion: @escaping ( _ requests:[FIOSDK.Request] , _ error:FIOError?) -> ()) {
        self.getFioNameByAddress(publicAddress: address, currencyCode: currencyCode) { (response, error) in
            if (error?.kind == FIOError.ErrorKind.Success){
                self.getRequestorHistoryByFioName(fioName: response.name, currencyCode: currencyCode
                    , maxItemsReturned: maxItemsReturned
                    , completion: { (responses, err) in
                        completion(responses,err)
                })
            }
            else {
                completion([FIOSDK.Request](),error)
            }
        }
    }
    
    public func getRequestorHistoryByFioName (fioName:String, currencyCode:String, maxItemsReturned:Int, completion: @escaping ( _ requests:[FIOSDK.Request] , _ error:FIOError?) -> ()) {
        self.getAddressByFioName(fioName: fioName, currencyCode: "FIO") { (response, error) in
            if (error?.kind == FIOError.ErrorKind.Success){
                self.requestFunds.getRequestorHistory(requestorAccountName: response.address, currencyCode: currencyCode, maxItemsReturned: maxItemsReturned
                    , completion: { (responses, err) in
                        
                        if (err?.kind == FIOError.ErrorKind.Success){
                            completion(responses, err)
                        }
                        else{
                            completion([FIOSDK.Request](),error)
                        }
                })
            }
            else {
                completion([FIOSDK.Request](),error)
            }
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

    public struct AddAddress : Codable{
        let fio_user_name: String
        let chain: String
        let address: String
        let requestor: String
    }
    
    public func addAllPublicAddresses(fioName : String,  publicReceiveAddresses:Dictionary<String,String>, completion: @escaping ( _ error:FIOError?) -> ()) {

        let account = "fio.system"
        let importedPk = try! PrivateKey(keyString: getSystemPrivateKey())
        
        let dispatchGroup = DispatchGroup()
        for (currencyCode, receiveAddress) in publicReceiveAddresses{
            dispatchGroup.enter()
            ///TODO: TEST THIS DEAL HERE
            let data = AddAddress(fio_user_name: fioName, chain: currencyCode, address: receiveAddress, requestor:getAccountName())
            
            var jsonString: String
            do{
                let jsonData:Data = try JSONEncoder().encode(data)
                jsonString = String(data: jsonData, encoding: .utf8)!
                print(jsonString)
            }catch {
                completion (FIOError(kind: .Failure, localizedDescription: "Input data JSON Encoding Failed"))
                return
            }
            
            let abi = try! AbiJson(code: "fio.system", action: "addaddress", json: jsonString)
            TransactionUtil.pushTransaction(abi: abi, account: account, privateKey: importedPk!, completion: { (result, error) in
                if error != nil {
                    if (error! as NSError).code == RPCErrorResponse.ErrorCode {
                        print("\(((error! as NSError).userInfo[RPCErrorResponse.ErrorKey] as! RPCErrorResponse).errorDescription())")
                    } else {
                        print("other error: \(String(describing: error?.localizedDescription))")
                    }
                } else {
                    print("Ok. Add Address, Txid: \(result!.transactionId)")
                }
                dispatchGroup.leave()
            })
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion(FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
        }
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
    
    public func isFioAddressOrDomainRegistered(fioAddress:String, completion: @escaping (_ isRegistered: Bool, _ error:FIOError?) -> ()) {
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

                completion(fioRsvp.is_registered, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)///TODO:create this correctly with ERROR results
                completion(false, err)
            }
        }
        
        task.resume()
    }
}
