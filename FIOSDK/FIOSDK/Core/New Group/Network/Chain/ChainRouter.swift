//
//  ChainRouter.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//


import Foundation

enum ChainEndpoint {
    
    case GetInfo()
    case GetBlock(blockNumberOrId: AnyObject)
    
}

class ChainRouter: BaseRouter {
    
    var endpoint: ChainEndpoint
    init(endpoint: ChainEndpoint) {
        self.endpoint = endpoint
    }
    
    override var method: HTTPMethod {
        return .post
    }
    
    override var path: String {
        switch endpoint {
        case .GetInfo: return "/chain/get_info"
        case .GetBlock: return "/chain/get_block"
        }
    }
    
    override var parameters: QueryParams {
        switch endpoint {
        default: return [:]
        }
    }
    
    override var body: Data? {
        switch endpoint {
        case .GetInfo(): return nil
        case .GetBlock(let blockNumberOrId):
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let block: String = blockNumberOrId as! String
            let b:Int? = Int(block) as Int?
            _ = b! - 3
            let jsonData = try! encoder.encode(["block_num_or_id": "\(blockNumberOrId)"])
            return jsonData
        }
    }
    
}
