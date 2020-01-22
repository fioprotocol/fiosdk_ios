//
//  FIOBalanceResponse.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-02.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

extension FIOSDK.Responses {

    public struct FIOBalanceResponse: Codable {
        public var balance: Int
        
        enum CodingKeys: String, CodingKey {
            case balance
        }
        
        public func displayBalance() -> Double {
            return Double(balance)/Double(SUFUtils.SUFUnit)
        }
    }
    
}
