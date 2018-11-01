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
    
    struct AddressByNameRequest: Codable {
        let fio_name: String
        let chain: String
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
    }
    
    private static var _sharedInstance: FIOSDK = {
        let sharedInstance = FIOSDK()
        
        return sharedInstance
    }()
    
    public class func sharedInstance(accountName: String? = nil, privateKey:String? = nil, publicKey:String? = nil, url:String? = nil) -> FIOSDK {
        
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
    
    private func getPrivateKey() -> String {
        return self.privateKey
    }
    
    private func getURI() -> String {
        return Utilities.sharedInstance().URL
    }
    
    private func getPublicKey() -> String {
        return self.publicKey
    }
    
    public func getAddressByFioName (fioName:String, currencyCode:String, completion: @escaping (_ fioLookupResults: AddressByNameResponse, _ error:FIOError?) -> ()) {
    
        var responseStruct : AddressByNameResponse = AddressByNameResponse(is_registered: "", is_domain: "", address: "")
        
        let fioRequest = AddressByNameRequest(fio_name: fioName, chain:currencyCode)
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
        
        var fioRsvp : NameByAddressResponse = NameByAddressResponse(name: "")
        
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
    
    public func registerFioName (fioName:String, publicReceiveAddresses:Dictionary<String,String>, completion: @escaping ( _ error:FIOError?) -> ()) {
        let account = getAccountName()
        let importedPk = try! PrivateKey(keyString: getPrivateKey())
        
        let data = "{\"name\":\"" + fioName + "\"}"
        let abi = try! AbiJson(code: account, action: "registername", json: data)

        TransactionUtil.pushTransaction(abi: abi, account: account, privateKey: importedPk!, completion: { (result, error) in
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
            
                self.createAccountAddAllPublicAddresses(fioName: fioName, publicReceiveAddresses: publicReceiveAddresses, completion: { (error) in
                    completion(error)
                })
           }
        })
    }
    
    private func createAccountAddAllPublicAddresses(fioName : String,  publicReceiveAddresses:Dictionary<String,String>, completion: @escaping ( _ error:FIOError?) -> ()) {
        getValidNewAccountName { (newAccountName, error) in
            if (newAccountName != nil && newAccountName!.count > 0){
                self.createAccount(newAccountName: newAccountName!, completion: { (error) in
                    if (error?.kind == FIOError.ErrorKind.Success){
                        var addresses:Dictionary<String,String> = publicReceiveAddresses
                        addresses[newAccountName!] = "BTC"
                        
                        self.addAllPublicAddresses(fioName: fioName, publicReceiveAddresses: addresses, completion: { (error) in
                            completion(error)
                        })
                    }
                    else{
                        completion(error)
                    }
                })
            }
            else{
                completion(error)
            }
        }
    }
    
    // try 4 times.
    private func getValidNewAccountName(completion: @escaping (_ newAccountName: String?, _ error:FIOError?) -> ()) {
        
        self.getAccount(accountName: createRandomAccountName()) { (account, error) in
            if (account != nil){
                completion(account?.accountName, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
            }
            else {
                self.getAccount(accountName: self.createRandomAccountName()) { (account, error) in
                    if (account != nil){
                        completion(account?.accountName, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
                    }
                    else {
                        self.getAccount(accountName: self.createRandomAccountName()) { (account, error) in
                            if (account != nil){
                                completion(account?.accountName, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
                            }
                            else {
                                self.getAccount(accountName: self.createRandomAccountName()) { (account, error) in
                                    if (account != nil){
                                        completion(account?.accountName, FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
                                    }
                                    else {
                                        completion(nil, FIOError.init(kind: FIOError.ErrorKind.Failure, localizedDescription: "Unable to create new account for register name"))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    private func addAllPublicAddresses(fioName : String,  publicReceiveAddresses:Dictionary<String,String>, completion: @escaping ( _ error:FIOError?) -> ()) {

        let account = getAccountName()
        let importedPk = try! PrivateKey(keyString: getPrivateKey())
        
        let dispatchGroup = DispatchGroup()
        for (receiveAddress, currencyCode) in publicReceiveAddresses{
            dispatchGroup.enter()
            let data = "{\"fio_user_name\":\"" + fioName +  "\",\"chain\":\"" + currencyCode + "\",\"address\":\"" + receiveAddress + "\"}"
            let abi = try! AbiJson(code: account, action: "addaddress", json: data)
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
        
        AccountUtil.createAccount(account: newAccountName, ownerKey:getPublicKey() , activeKey: getPublicKey(), creator: getAccountName(), pkString: getPrivateKey()) { (result, error) in
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
    
    private func getAccount(accountName:String, completion: @escaping (_ account: Account?, _ error:FIOError?) -> ()) {
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
    
    private func createRandomAccountName() -> String{
        return Utilities.sharedInstance().randomString(length:12)
    }
    
}
