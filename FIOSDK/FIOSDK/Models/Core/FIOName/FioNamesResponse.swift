//
//  FioNamesResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

/// DTO to represent the response of /get_fio_names
public struct FioNamesResponse: Codable {
    
    public let publicAddress: String
    public let domains: [FioDomainResponse]
    public let addresses: [FioAddressResponse]
    
    enum CodingKeys: String, CodingKey {
        case publicAddress = "fio_pub_address"
        case domains = "fio_domains"
        case addresses = "fio_addresses"
    }
    
    public struct FioDomainResponse: Codable{
        public let domain: String
        private let _expiration: String
        
        public var expiration: Date{
            return Date(timeIntervalSince1970: (Double(_expiration) ?? 0))
        }
        
        enum CodingKeys: String, CodingKey{
            case domain = "fio_domain"
            case _expiration = "expiration"
        }
    }
    
}

public struct FioAddressResponse: Codable{
    public let address: String
    private let _expiration: String
    
    public var expiration: Date{
        return Date(timeIntervalSince1970: (Double(_expiration) ?? 0))
    }
    
    enum CodingKeys: String, CodingKey{
        case address = "fio_address"
        case _expiration = "expiration"
    }
}
