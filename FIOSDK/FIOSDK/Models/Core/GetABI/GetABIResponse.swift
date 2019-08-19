//
//  GetABIResponse.swift
//  FIOSDK
//
//  Created by shawn arney on 6/20/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {
    
    public struct GetABIResponse: Codable {
        
        public let accountName: String
        public let codeHash: String
        public let abiHash: String
        public var abi: String
        
        enum CodingKeys: String, CodingKey {
            case accountName = "account_name"
            case codeHash = "code_hash"
            case abiHash = "abi_hash"
            case abi = "abi"
        }
    }
}

