//
//  GetObtDataRequest.swift
//  FIOSDK
//
//  Created by shawn arney on 12/30/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

internal struct GetObtDataRequest: Codable {
    
    public let fioPublicKey: String
    public let limit: Int?
    public let offset: Int

    enum CodingKeys: String, CodingKey{
       case fioPublicKey = "fio_public_key"
       case limit
       case offset
    }
}
