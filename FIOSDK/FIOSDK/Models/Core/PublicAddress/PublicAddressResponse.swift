//
//  PublicAddressResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    /// Structure used as response body for getPublicAddress
    public struct PublicAddressResponse: Codable {
        
        /// public address for the specified FIO Address.
        public let publicAddress: String
        
        enum CodingKeys: String, CodingKey{
            case publicAddress = "public_address"
        }
        
    }

}
