//
//  SignedRequestHelper.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-17.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

//MARK: - Signed Post Request

/**
 * This function does a signed post request to our API. It uses TransactionUtil.packAndSignTransaction to pack and sign body before doing the POST request to the required route.
 * - Parameters:
 *      - privateKey: The string value of the key used to sign the transaction.
 *      - route: The route to be requested. Look at ChainRoutes for possible values
 *      - action: The API action for the given request. Look at ChainActions for possible values
 *      - body: The request body parameters to be serialized and sent as a data string
 *      - code: The code required for packing and signing a transaction, for more info look at TransactionUtil.packAndSignTransaction
 *      - account: The account required for packing and signing a transaction, for more info look at TransactionUtil.packAndSignTransaction
 *      - onCompletion: A callback function that is called when request is finished with is Data value and either with success or failure, both values are optional. Check FIOError.kind to determine if is a success or a failure.
 */
internal func signedPostRequestTo<T: Codable>(privateKey: String, route: ChainRoutes, forAction action: ChainActions, withBody body: T, code: String, account: String, onCompletion: @escaping (_ result: TxResult?, FIOError?) -> Void) {
    guard let privateKey = try! PrivateKey(keyString: privateKey) else {
        onCompletion(nil, FIOError(kind: .FailedToUsePrivKey, localizedDescription: "Failed to retrieve private key."))
        return
    }
    
    serializeJsonToData(body, forCode: code, forAction: action) { (result, error) in
        if let result = result {
            
            PackedTransactionUtil.packAndSignTransaction(code: code, action: action.rawValue, data: result.json, account: account, privateKey: privateKey, completion: { (signedTx, error) in
                if let error = translateErrorToFIOError(error: error) {
                    onCompletion(nil, error)
                }
                else {
                    let url = ChainRouteBuilder.build(route: route)

                    FIOHTTPHelper.postRequestTo(url, withBody: signedTx, onCompletion: { (data, error) in
                        if data == nil, let error = error {
                            onCompletion(nil, error)
                            return
                        }
                        let handledResults = parseResponseDataToTransactionResult(data: data)
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
internal func parseResponseDataToTransactionResult(data: Data?) -> (response: TxResult?, error: FIOError?) {
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
internal func parseResponseFromTransactionResult<T: Codable>(txResult: TxResult) -> (response: T?, error: FIOError) {
    guard let responseString = txResult.processed?.actionTraces.first?.receipt.response.value as? String, let responseData = responseString.data(using: .utf8), let response = try? JSONDecoder().decode(T.self, from: responseData) else {
        return (nil, FIOError.init(kind: .Failure, localizedDescription: "Error parsing the response"))
    }
    return (response, FIOError(kind: .Success, localizedDescription: ""))
}

internal func translateErrorToFIOError(error: Error?) -> FIOError? {
    guard error != nil else { return nil }
    if (error! as NSError).code == RPCErrorResponse.ErrorCode {
        let errDescription = "error"
        return FIOError.init(kind: .Failure, localizedDescription: errDescription)
    } else {
        let errDescription = ("other error: \(String(describing: error?.localizedDescription))")
        return FIOError.init(kind: .Failure, localizedDescription: errDescription)
    }
}
