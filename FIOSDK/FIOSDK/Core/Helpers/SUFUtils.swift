//
//  SUFUtils.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-05-13.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

/**
 * This class helps on Smallest Units of FIO (SUF) internal calculation prior to FIO transactions. [visit API specs](https://stealth.atlassian.net/wiki/spaces/DEV/pages/90898460/FIO+Protocol#FIOProtocol-Supply)
 **/
internal class SUFUtils {
    
    static let SUFUnit = 1000000000
    
    static func amountToSUF(amount: Double) -> Int {
        return Int(amount * Double(SUFUnit))
    }
    
    static func amountToSUFString(amount: Double) -> String {
        return String(amountToSUF(amount: amount))
    }
    
}
