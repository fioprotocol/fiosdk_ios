//
//  DateUtils.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-08.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

public struct FIODateUtils {
    
    public static func formattedDate(interval: Double, format: String = "MMM dd, yyyy") -> String {
        let date = Date(timeIntervalSince1970: interval)
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    public static func formattedDate(interval: Double, format: String = "MMM dd, yyyy") -> Date? {
        let date = Date(timeIntervalSince1970: interval)
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: formatter.string(from: date))
    }
    
    public static func formattedDate(date: Date, format: String = "MMM dd, yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

}
