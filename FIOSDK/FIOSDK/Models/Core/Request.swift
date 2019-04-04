//
//  Request.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct Request {
    
    public let amount:Float
    public let currencyCode:String
    public var status:RequestStatus
    public let requestTimeStamp:Int
    public let requestDate:Date
    public let requestDateFormatted:String
    public let fromFioName:String
    public let toFioName:String
    public let requestorAccountName:String
    public let requesteeAccountName:String
    public let memo:String
    public let fioappid:Int
    public let requestid:Int
    public let statusDescription:String
    
}

public enum RequestStatus:String, Codable {
    
    case Requested = "Requested"
    case Rejected = "Rejected"
    case Approved = "Approved"
    
}
