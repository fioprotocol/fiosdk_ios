//
//  HTTPHelper.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-03-01.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct FIOHTTPHelper {

    static func bodyFromJson<J: Encodable>(_ json: J?) -> Data? {
        guard let json = json else { return nil }
        
        var jsonData: Data? = nil
        
        do{
            jsonData = try JSONEncoder().encode(json)
        } catch {
            return nil
        }
        
        return jsonData
    }
    
    private static func request(url urlString: String, method: HTTPMethod = HTTPMethod.get, body: Data?) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }
    
    static func rpcPostRequestTo<T: Codable, J: Encodable>(_ fullUrl: String, withBody json: J?, onCompletion: @escaping (_ result: T?, _ error: Error?) -> ()) {

        guard let request = request(url: fullUrl, method: .post, body: bodyFromJson(json)) else {
            onCompletion(nil, FIOError(kind: .MalformedURL, localizedDescription: "Failed to post request to \(fullUrl)"))
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    onCompletion(nil, NSError(domain: Constants.errorDomain, code: 1,
                                            userInfo: [NSLocalizedDescriptionKey: "Networking error \(String(describing: error)) \(String(describing: response))"]))
                    return
                }
                let decoder = RPCDecoder()
                let jsonString = String(data:data, encoding: .utf8)
                print(jsonString!)
                do{
                    let testResponse = try decoder.decode(T.self, from: data)
                    print(testResponse)
                }catch let error{
                    print(error)
                }
                guard let responseObject = try? decoder.decode(T.self, from: data) else {
                    guard let errorResponse = try? decoder.decode(RPCErrorResponse.self, from: data) else {
                        onCompletion(nil, NSError(domain: Constants.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Decoding error \(String(describing: error))"]))
                        return
                    }
                    let userInfo = [RPCErrorResponse.ErrorKey: errorResponse]
                    onCompletion(nil, NSError(domain: Constants.errorDomain, code: RPCErrorResponse.ErrorCode, userInfo: userInfo))
                    return
                }
                onCompletion(responseObject, error)
            }
            
        }
        
        dataTask.resume()
    }    
    
    /**
     * Do a post request to the given url with a body parameter
     * - Parameter fullUrl: The full url string, i.e. https://server.com/chain/endpoint
     * - Parameter withBody: A Encodable object to be sent as post's body
     * - Parameter onCompletion: A callback function with result Data and FIOError as optional params
    */
    static func postRequestTo<J: Encodable>(_ fullUrl: String, withBody json: J, onCompletion: @escaping (_ result: Data?, FIOError?) -> Void) {
        
        guard let request = request(url: fullUrl, method: .post, body: bodyFromJson(json)) else {
            onCompletion(nil, FIOError(kind: .MalformedURL, localizedDescription: "[FIOSDK] Failed to post request to \(fullUrl)"))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    if let message = error?.localizedDescription {
                        onCompletion(nil, FIOError.failure(localizedDescription: message))
                    }
                    else {
                        onCompletion(nil, FIOError(kind: .NoDataReturned, localizedDescription: "No data"))
                    }
                    return
                }
                let httpResponse = response as? HTTPURLResponse
                guard let statusCode = httpResponse?.statusCode, statusCode >= 200, statusCode < 400 else {
                    guard let errorResponse = try? JSONDecoder().decode(FIOHTTPErrorResponse.self, from: data) else {
                        onCompletion(nil, FIOError.failure(localizedDescription: String(format: "Failed with code: %d", httpResponse?.statusCode ?? -1)))
                        return
                    }
                    onCompletion(nil, FIOError.failure(localizedDescription: errorResponse.toString()))
                    return
                }
                onCompletion(data, FIOError.success())
            }
        }
        
        task.resume()
    }
    
}
