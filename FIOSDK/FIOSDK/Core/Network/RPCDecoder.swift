//
//  RPCDecoder.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal class RPCDecoder: JSONDecoder {
    
    override init() {
        super.init()
        dateDecodingStrategy = .custom(customDateFormatter)
        keyDecodingStrategy = .convertFromSnakeCase
    }
    
    var se_iso8601dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return dateFormatter
    }()
    
    var se_iso8601dateFormatterWithoutMilliseconds: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()
    
    var se_iso8601dateFormatterRequest: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
        return dateFormatter
    }()
    
    func customDateFormatter(_ decoder: Decoder) throws -> Date {
        let dateString = try decoder.singleValueContainer().decode(String.self)
        switch dateString.count {
        case 20..<Int.max:
            return se_iso8601dateFormatter.date(from: dateString)!
        case 19:
            return se_iso8601dateFormatterWithoutMilliseconds.date(from: dateString)!
        default:
            let dateKey = decoder.codingPath.last
            fatalError("Unexpected date coding key: \(String(describing: dateKey))")
        }
    }
    
}
