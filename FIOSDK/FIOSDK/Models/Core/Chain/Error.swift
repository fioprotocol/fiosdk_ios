//
//  Error.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct RPCErrorDetail: Codable {
    var message: String
    var file: String
    var lineNumber: Int
    var method: String
}

internal struct RPCError: Codable {
    var code: Int
    var name: String
    var what: String
    var details: [RPCErrorDetail]
}

internal struct RPCErrorResponse: Error, Codable {
    static let ErrorKey = "RPCErrorResponse"
    static let ErrorCode = 80000
    
    var code: Int
    var message: String
    var error: RPCError
    
    func errorDescription() -> String {
        return "\nerror:\n  name:       \(error.name)\n  what:       \(error.what)\n  details[0]: \(String(describing: error.details.first!.message))"
    }
}
