//
//  JSONSerialization.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct SerializeJsonRequest<T: Codable>: Codable {
    let action: String
    let json: T
    
    enum CodingKeys: String, CodingKey {
        case action
        case json
    }
}

internal struct SerializeJsonResponse {
    var json: String
}

/**
 * Call serialize_json (POST) in order to serialize the given json object for an API action (ChainAction).
 * - Parameters:
 *      - json: A json object to serialize. Must implement Codable.
 *      - forAction: The API action (ChainActions) that will use the serialized json
 *      - onCompletion: A callback with either SerializeJsonResponse or FIOError as serialization result.
 */
internal func serializeJsonToData<T: Codable>(_ json: T, forCode code:String, forAction action: String, onCompletion: @escaping (SerializeJsonResponse?, FIOError?) -> Void) {

    var jsonString = "{}"
    if json is String {
        jsonString = json as! String
    }
    else {
        jsonString = String(decoding: FIOHTTPHelper.bodyFromJson(json)!, as: UTF8.self)
    }
    
    let myAbi = FIOSDK.sharedInstance().getCachedABI(accountName: code)
    
    if (myAbi.count > 1){
        let serializer = abiSerializer()
        let serializedResult = try? serializer.serialize(contract: code, name:action, json: jsonString, abi: myAbi)
        
        if (serializedResult != nil) {
            onCompletion(SerializeJsonResponse(json:serializedResult!), nil)
        }
        else {
            onCompletion(SerializeJsonResponse(json:""), FIOError.failure(localizedDescription: "unable to serialize json"))
        }
    }
    else{
        
        FIOSDK.sharedInstance().getABI(accountName: code) { (response
            , error
            ) in
            if (error.kind == FIOError.ErrorKind.Success){
                let serializer = abiSerializer()
                let serializedResult = try? serializer.serialize(contract: code, name:action, json: jsonString, abi: response?.abi ?? "")
                
                if (serializedResult != nil) {
                    onCompletion(SerializeJsonResponse(json:serializedResult!), nil)
                }
                else {
                    onCompletion(SerializeJsonResponse(json:""), FIOError.failure(localizedDescription: "unable to serialize json"))
                }
            }
            else {
                onCompletion(nil, error)
            }
        }
    }

}
