//
//  AvailCheckResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct AvailCheckResponse: Codable {
    
    private let is_registered: Int
    
    public var isRegistered: Bool{
        return (is_registered == 1 ? true : false)
    }
    
}
