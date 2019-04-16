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

internal struct SerializeJsonResponse: Codable {
    let json: String
    
    enum CodingKeys: String, CodingKey {
        case json = "serialized_json"
    }
}


/**
 * Call serialize_json (POST) in order to serialize the given json object for an API action (ChainAction).
 * - Parameters:
 *      - json: A json object to serialize. Must implement Codable.
 *      - forAction: The API action (ChainActions) that will use the serialized json
 *      - onCompletion: A callback with either SerializeJsonResponse or FIOError as serialization result.
 */
internal func serializeJsonToData<T: Codable>(_ json: T, forAction action: ChainActions, onCompletion: @escaping (SerializeJsonResponse?, FIOError?) -> Void) {
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
