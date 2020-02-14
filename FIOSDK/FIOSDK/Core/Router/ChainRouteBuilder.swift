//
//  ChainRouteBuilder.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-02.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct ChainRouteBuilder {
    
    static func build(route: ChainRoutes) -> String {
        return ChainRouteBuilder.getBaseURL() + route.rawValue
    }
    
    private static func getBaseURL() -> String {
        return Utilities.sharedInstance().URL
    }
    
}
