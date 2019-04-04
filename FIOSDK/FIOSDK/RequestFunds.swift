//
//  Requests.swift
//  FIOSDK
//
//  Created by shawn arney on 11/6/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import Foundation

//fio.finance for request flow private/public

public class RequestFunds{
    
    private func getURI() -> String {
        return Utilities.sharedInstance().URL
    }
    
    private func fioFinanceAccount() -> String {
        return "fio.finance"
    }
    
    private func fioFinanceAccountPrivateKey() -> String {
        return FIOSDK.sharedInstance().getSystemPrivateKey()
    }
    
    private func privateKey() -> String {
        return FIOSDK.sharedInstance().getPrivateKey()
    }
    
    struct TableRequest: Codable {
        let json: Bool
        let code: String
        let scope: String
        let table: String
        let table_key: String
        let lower_bound: String
        let upper_bound: String
        let limit: Int
        let key_type: String
        let index_position: String
        let encode_type: String
    }

    struct PendingHistoryResponse: Codable {
        let json: Bool
        let code: String
        let scope: String
        let table: String
        let table_key: String
        let lower_bound: String
        let limit: Int
        let key_type: String
        let index_position: String
        let encode_type: String
    }
    
    struct HistoryResponseDetails: Codable {
        let rows:[HistoryResponseDetailsRecord]
        let more: Bool
    }
    
    struct HistoryResponseDetailsRecord: Codable {
        let requestid: Int
        let fioappid: Int
        let originator: String
        let receiver: String
    }
    
    struct ResponseDetailsRecord: Codable {
        let fioappid: Int
        let originator: String
        let receiver: String
        let chain: String
        let asset: String
        let quantity: String
    }
    
    struct ResponseDetailsRecordReturned: Codable {
        let fioappid: Int
        let originator: String
        let receiver: String
        let chain: String
        let asset: String
        let quantity: String
        let originatorFioName: String
        let receiverFioName: String
    }       
    
    private func dateFromTimeStamp(time:Int) -> Date {
        let index = Double(time)
        let date = NSDate(timeIntervalSince1970: index ?? 11111111)
        return date as Date
    }
    
    private func formattedDate(time:Int) -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMMM dd, yyyy, hh:mm a"
    
        return dateFormatterPrint.string(from: dateFromTimeStamp(time:time))
    }
    
    struct ResponseDetails: Codable {
        let rows:[ResponseDetailsRecord]
    }
    
    struct ResponseDetailsReturned: Codable {
        let rows:[ResponseDetailsRecordReturned]
    }
    
    private struct FioName{
        let fioName: String
        let address: String
    }
    
    private func getRequestDetails (appIdStart:Int, appIdEnd:Int, maxItemsReturned:Int, completion: @escaping ( _ requests:ResponseDetailsReturned , _ error:FIOError?) -> ()) {
        
        let fioRequest = TableRequest(json: true, code: "fio.finance", scope: "fio.finance", table: "trxcontexts", table_key: "", lower_bound: String(appIdStart),
                                      upper_bound: String(appIdEnd+1), limit: 0, key_type: "", index_position: "", encode_type: "dec")
        var jsonData: Data
        var jsonString: String
        do{
            jsonData = try JSONEncoder().encode(fioRequest)
            jsonString = String(data: jsonData, encoding: .utf8)!
            //print(jsonString)
        }catch {
            completion (ResponseDetailsReturned(rows: [RequestFunds.ResponseDetailsRecordReturned]()), FIOError(kind: .Failure, localizedDescription: "Json Encoding of input data failed."))
            return
        }
        
        // create post request
        let url = URL(string: getURI() + "/chain/get_table_rows")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("no-cache", forHTTPHeaderField: "cache-control")
        
        // insert json data to the request
        request.httpBody = jsonString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                
                completion(ResponseDetailsReturned(rows: []), FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
               
                let result = String(data: data, encoding: String.Encoding.utf8) as String!
                //print(result)
                //print ("getRequestDetails() data was printed")
                let response = try JSONDecoder().decode(ResponseDetails.self, from: data)
                //print ("*****")
                //print (response)
                //print ("***")
  
                if (response.rows.count < 1){
                    completion(ResponseDetailsReturned(rows: []), FIOError(kind: .NoDataReturned, localizedDescription: ""))
                    return
                }
                //print(response.rows.count)
                let dispatchGroup = DispatchGroup()
                var fioNameRecords = SynchronizedArray<FioName>()
                ///TODO: do this with some sort of bounds to minimize calls - no time left to do this right
                for item in response.rows{
                    //print("dispatch")
                    dispatchGroup.enter()
                    FIOSDK.sharedInstance().getFioNames(publicAddress: item.receiver, completion: { (response, error) in
                        if error?.kind == FIOError.ErrorKind.Success, let responseAddress = response?.addresses.first?.address{
                            fioNameRecords.append(newElement: FioName(fioName: responseAddress, address: item.receiver) )
                        }
                        else {
                            fioNameRecords.append(newElement: FioName(fioName: "not found", address: item.receiver) )
                        }
                        dispatchGroup.leave()
                    })
                }
                
                for item in response.rows{
                    //print("dispatch2")
                    dispatchGroup.enter()
                    FIOSDK.sharedInstance().getFioNames(publicAddress: item.originator, completion: { (response, error) in
                        if error?.kind == FIOError.ErrorKind.Success, let responseAddress = response?.addresses.first?.address{
                            fioNameRecords.append(newElement: FioName(fioName: responseAddress, address: item.originator) )
                        }
                        else {
                            fioNameRecords.append(newElement: FioName(fioName: "not found", address: item.originator) )
                        }
                        dispatchGroup.leave()
                    })
                }
                
                ///TODO: do this the right way -- right now, we know there is only one record.
                dispatchGroup.notify(queue: DispatchQueue.main) {
                    //print("dispatch group main")
                    var arr = [ResponseDetailsRecordReturned]()
                    for item in response.rows{
                        // let responseRow = response.rows.first(where:{$0.fioappid == detail.fioappid})
                       //let fioName:FioName = fioNameRecords.first(where:{$0.address == item.receiver})
                        var receiverFioName = ""
                        for i in 0 ..< fioNameRecords.count {
                            let fioName = fioNameRecords[i]
                            if (fioName.address == item.receiver){
                                receiverFioName = fioName.fioName
                                break
                            }
                        }
                        
                        var originatorFioName = ""
                        for i in 0 ..< fioNameRecords.count {
                            let fioName = fioNameRecords[i]
                            if (fioName.address == item.originator){
                                originatorFioName = fioName.fioName
                                break
                            }
                        }
                        
                        arr.append(ResponseDetailsRecordReturned(fioappid: item.fioappid, originator: item.originator, receiver: item.receiver, chain: item.chain, asset: item.asset, quantity: item.quantity, originatorFioName: originatorFioName, receiverFioName: receiverFioName))
                    }
                    completion(ResponseDetailsReturned(rows: arr), FIOError(kind: .Success, localizedDescription: ""))
                }
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)///TODO:create this correctly with ERROR results
                completion(ResponseDetailsReturned(rows: []), err)
            }
        }
        
        task.resume()
    }

    struct RequestTrxLogDetails: Codable {
        let rows:[RequestTrxLog]
        let more:Bool
    }
    
    struct RequestTrxData: Codable{
        let reqid: String?
        let obtid: String?
        let memo: String
    }
    
    struct RequestTrxLog: Codable{
        let key: Int
        let fioappid: Int
        let type: Int
        let status: Int
        let time: Int
        let data: String
    }
    
    struct ResponseRequestMemoDate{
        let fioappid: Int
        let time: Int
        let memo: String
        let status: Int
    }

    ///TODO: get the bounds working, to restrict the data
    private func getRequestMemoDate (appIdStart:Int, appIdEnd:Int, includeType:Int, removeType:Int, status:Int, maxItemsReturned:Int, completion: @escaping ( _ requests:[ResponseRequestMemoDate] , _ error:FIOError?) -> ()) {
        
        let fioRequest = TableRequest(json: true, code: "fio.finance", scope: "fio.finance", table: "trxlogs", table_key: "", lower_bound: String(appIdStart),
                                      upper_bound: String(appIdEnd+1), limit: 0, key_type: "i64", index_position: "2", encode_type: "dec")
        var jsonData: Data
        var jsonString: String
        do{
            jsonData = try JSONEncoder().encode(fioRequest)
            jsonString = String(data: jsonData, encoding: .utf8)!
            //print(jsonString)
        }catch {
            completion ([ResponseRequestMemoDate](), FIOError(kind: .NoDataReturned, localizedDescription: ""))
            return
        }
        
        // create post request
        let url = URL(string: getURI() + "/chain/get_table_rows")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("no-cache", forHTTPHeaderField: "cache-control")
        
        // insert json data to the request
        request.httpBody = jsonString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                
                completion([ResponseRequestMemoDate](), FIOError(kind: .NoDataReturned, localizedDescription: ""))
                return
            }
            do {
                
                let result = String(data: data, encoding: String.Encoding.utf8) as String!
               // print(result)
             //   print ("getRequestMemoDate() data was printed")
                let response = try JSONDecoder().decode(RequestTrxLogDetails.self, from: data)
               // print ("*****")
                //print (response)
               // print ("***")
                
                if (response.rows.count < 1){
                    completion([ResponseRequestMemoDate](), FIOError(kind: .NoDataReturned, localizedDescription: ""))
                    return
                }

                var arr = [ResponseRequestMemoDate]()
                //var filteredRows = response.rows.filter({$0.fioappid == appIdStart})
                for row in response.rows {
                    if (row.fioappid == appIdStart){
                        var include = true
                        if (includeType > 0){
                            if (row.type != includeType){
                                include = false
                            }
                        }
                        if (removeType > 0){
                            if (row.type == removeType){
                                include = false
                            }
                        }
                        
                        if (include){
                            //print("MEMO MATCHED")
                            // let memo = try JSONDecoder().decode(RequestTrxLogDetails.self, from: row.data)
                            let jsonDecoder = JSONDecoder()
                            let datafield = try jsonDecoder.decode(RequestTrxData.self, from: row.data.data(using: .utf8)!)
                            
                            arr.append(ResponseRequestMemoDate(fioappid: row.fioappid, time: row.time, memo: datafield.memo, status:row.status))
                            
                        }
                    }
                }
                completion(arr, FIOError(kind: .Success, localizedDescription: ""))
                
            }catch let error{
                let err = FIOError(kind: .Failure, localizedDescription: error.localizedDescription)///TODO:create this correctly with ERROR results
                completion([ResponseRequestMemoDate](), err)
            }
        }
        
        task.resume()
    }
    
    struct CancelFundsData: Codable {
        let requestid: Int
        let requestor: String
        let memo: String
    }
    
    public func cancelFundsRequest (requestorAccountName:String, requestId:Int, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        var privateKey = self.fioFinanceAccountPrivateKey()  // So, the accounts are being created with the FIO.system private key... will it work if we USE FIO.system privatekey HERE
        if (requestorAccountName == "fioname22222"){
            privateKey = "5JA5zQkg1S59swPzY6d29gsfNhNPVCb7XhiGJAakGFa7tEKSMjT"
        }
        
        let importedPk = try! PrivateKey(keyString: privateKey)
        
        let data = CancelFundsData(requestid: requestId, requestor: requestorAccountName, memo: memo)
        
        var jsonString: String
        do{
            let jsonData:Data = try JSONEncoder().encode(data)
            jsonString = String(data: jsonData, encoding: .utf8)!
        }catch {
            completion (FIOError(kind: .Failure, localizedDescription: "JSon encoding of input data failed."))
            return
        }
        //print(jsonString)
        
        let abi = try! AbiJson(code: fioFinanceAccount(), action: "cancelrqst", json:jsonString)
        
        TransactionUtil.pushTransaction(abi: abi, account: requestorAccountName, privateKey: importedPk!, completion: { (result, error) in
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
                print("Ok. cancel funds successful, Txid: \(result!.transactionId)")
                 completion(FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
            }
        })
    }
    
    struct ApproveFundsData: Codable {
        let fioappid: Int
        let requestee: String
        let obtid:String
        let memo: String
    }
    
    //THE PRIVATE KEY is associated with the account: name --> so, need to tie it back into.. the account creation side of things.
    // reportrqst '{"fioappid": "2","requestee":"fioname22222","obtid":"0x123456789","memo":"approved"}' --permission fioname22222@active
    public func approveFundsRequest (requesteeAccountName:String, fioAppId:Int, obtid:String, memo:String, completion: @escaping ( _ error:FIOError?) -> ()) {
        var privateKey = self.fioFinanceAccountPrivateKey()  // So, the accounts are being created with the FIO.system private key... will it work if we USE FIO.system privatekey HERE
        if (requesteeAccountName == "fioname22222"){
            privateKey = "5JA5zQkg1S59swPzY6d29gsfNhNPVCb7XhiGJAakGFa7tEKSMjT"
        }
        
        let importedPk = try! PrivateKey(keyString: privateKey)
        
        let data = ApproveFundsData(fioappid: fioAppId, requestee: requesteeAccountName, obtid:obtid, memo: memo)
        
        var jsonString: String
        do{
            let jsonData:Data = try JSONEncoder().encode(data)
            jsonString = String(data: jsonData, encoding: .utf8)!
        }catch {
            completion (FIOError(kind: .Failure, localizedDescription: "Json encoding of input data failed."))
            return
        }
        //print(jsonString)
        
        let abi = try! AbiJson(code: fioFinanceAccount(), action: "reportrqst", json:jsonString)
        
        TransactionUtil.pushTransaction(abi: abi, account: requesteeAccountName, privateKey: importedPk!, completion: { (result, error) in
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
                print("Ok. reject funds successful, Txid: \(result!.transactionId)")
                completion(FIOError.init(kind: FIOError.ErrorKind.Success, localizedDescription: ""))
            }
        })
    }
    
    
    public class SynchronizedArray<T> {
        private var array: [T] = []
        private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)
        
        public func append(newElement: T) {
            
            self.accessQueue.async(flags:.barrier) {
                self.array.append(newElement)
            }
        }
        
        public func removeAtIndex(index: Int) {
            
            self.accessQueue.async(flags:.barrier) {
                self.array.remove(at: index)
            }
        }
        
        public var count: Int {
            var count = 0
            
            self.accessQueue.sync {
                count = self.array.count
            }
            
            return count
        }
        
        public func first() -> T? {
            var element: T?
            
            self.accessQueue.sync {
                if !self.array.isEmpty {
                    element = self.array[0]
                }
            }
            
            return element
        }
        
        public subscript(index: Int) -> T {
            set {
                self.accessQueue.async(flags:.barrier) {
                    self.array[index] = newValue
                }
            }
            get {
                var element: T!
                self.accessQueue.sync {
                    element = self.array[index]
                }
                
                return element
            }
        }
    }
    
}
