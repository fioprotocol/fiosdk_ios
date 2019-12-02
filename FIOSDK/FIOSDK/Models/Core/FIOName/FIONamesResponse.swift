//
//  FIONamesResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    public struct FIONamesResponse: Codable {
        
        public let domains: [FIODomainResponse]
        public let addresses: [FIOAddressResponse]
        
        enum CodingKeys: String, CodingKey {
            case domains = "fio_domains"
            case addresses = "fio_addresses"
        }
        
        public struct FIODomainResponse: Codable{
            public let domain: String
            private let _expiration: String
            private let _isPublic: Int
            
            public var expiration: Date{
                return _expiration.toLocalDate
            }
            
            public var isPublic: Bool{
                return (_isPublic == 1 ? true : false)
            }
            
            enum CodingKeys: String, CodingKey{
                case domain = "fio_domain"
                case _expiration = "expiration"
                case _isPublic = "is_public"
            }
        }
        
    }

    public struct FIOAddressResponse: Codable{
        public let address: String
        private let _expiration: String

        public var expiration: Date{
             return _expiration.toLocalDate
        }
        
        enum CodingKeys: String, CodingKey{
            case address = "fio_address"
            case _expiration = "expiration"
        }
    }

}
