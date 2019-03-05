//
//  HTTPHelper.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-03-01.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

struct FIOHTTPHelper {
    
    /**
     * Do a post request to the given url with a body parameter
     * - Parameter fullUrl: The full url string, i.e. https://server.com/chain/endpoint
     * - Parameter withBody: A Encodable object to be sent as post's body
     * - Parameter onCompletion: A callback function with result Data and FIOError as optional params
    */
    static func postRequestTo<J: Encodable>(_ fullUrl: String, withBody json: J, onCompletion: @escaping (_ result: Data?, FIOError?) -> Void) {
        var jsonData: Data
        do{
            jsonData = try JSONEncoder().encode(json)
        } catch {
            onCompletion(nil, FIOError(kind: .MalformedRequest, localizedDescription: ""))
            return
        }
        
        // create post request
        guard let url = URL(string: fullUrl) else {
            onCompletion(nil, FIOError(kind: .MalformedURL, localizedDescription: ""))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                if let message = error?.localizedDescription {
                    onCompletion(nil, FIOError(kind: .Failure, localizedDescription: message))
                }
                else {
                    onCompletion(nil, FIOError(kind: .NoDataReturned, localizedDescription: "No data"))
                }
                return
            }
            let httpResponse = response as? HTTPURLResponse
            guard let statusCode = httpResponse?.statusCode, statusCode >= 200, statusCode < 400 else {
                onCompletion(nil, FIOError(kind: .Failure, localizedDescription: String(format: "Failed with code: %d", httpResponse?.statusCode ?? -1)))
                return
            }
            onCompletion(data, FIOError(kind: .Success, localizedDescription: ""))
        }
        
        task.resume()
    }
    
}
