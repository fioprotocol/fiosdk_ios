//
//  FIOErrorResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

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
internal struct FIOHTTPErrorResponse: Codable {
    
    var type: String?
    var message: String
    var fields: [FIOHTTPErrorFieldsResponse]?
    
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

internal struct FIOHTTPErrorFieldsResponse: Codable {
    
    var name: String
    var value: String
    var error: String
    
}
