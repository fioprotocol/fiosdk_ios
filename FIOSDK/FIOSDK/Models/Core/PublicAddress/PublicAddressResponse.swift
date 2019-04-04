//
//  PublicAddressResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

/// Structure used as response body for getPublicAddress
public struct PublicAddressResponse: Codable {
    
    /// FIO Address for which public address is returned.
    public let fioAddress: String
    
    /// Token code for which public address is returned.
    public let tokenCode: String
    
    /// public address for the specified FIO Address.
    public let publicAddress: String
    
    enum CodingKeys: String, CodingKey{
        case fioAddress = "fio_address"
        case tokenCode = "token_code"
        case publicAddress = "pub_address"
    }
    
}
