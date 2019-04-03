//
//  HTTPHelper.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-03-01.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct FIOHTTPHelper {
    
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
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
                    guard let errorResponse = try? JSONDecoder().decode(FIOErrorResponse.self, from: data) else {
                        onCompletion(nil, FIOError(kind: .Failure, localizedDescription: String(format: "Failed with code: %d", httpResponse?.statusCode ?? -1)))
                        return
                    }
                    onCompletion(nil, FIOError(kind: .Failure, localizedDescription: errorResponse.toString()))
                    return
                }
                onCompletion(data, FIOError(kind: .Success, localizedDescription: ""))
            }
        }
        
        task.resume()
    }
    
    ///Chain endpoints response model, it has the following format:
    /// ```
    ///{
    ///    "type": "invalid_input",
    ///    "message": "An invalid request was sent in, please check the nested errors for details.",
    ///    "fields": [{
    ///    "name": "fromfioadd",
    ///    "value": "sha1551986532.brd",
    ///    "error": "No such FIO Address"
    ///    }]
    ///}
    ///```
    /// Note: type and fields are optionals.
    private struct FIOErrorResponse: Codable {
        
        var type: String?
        var message: String
        var fields: [FIOErrorFieldsResponse]?
        
        func toString() -> String {
            var value = ""
            if let type = type {
                value = String(format: "Type: %@ ", type)
            }
            value = String(format: "%@Message: %@ ", value, message)
            guard let fields = fields else { return value }
            for field in fields {
                value = String(format: "%@Field: %@ - Error: %@ ", value, field.name, field.error)
            }
            return value
        }
        
    }
    
    private struct FIOErrorFieldsResponse: Codable {
        
        var name: String
        var value: String
        var error: String
        
    }
    
}
