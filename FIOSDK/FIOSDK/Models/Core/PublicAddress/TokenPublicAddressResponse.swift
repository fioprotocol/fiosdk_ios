//
//  TokenPublicAddressResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-09.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    /// The response object for getTokenPublicAddress function, contains the requested public address for a given token code.
    public struct TokenPublicAddressResponse {
        
        public let fioAddress: String
        public let tokenPublicAddress: String
        
    }

}
