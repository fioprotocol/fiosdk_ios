//
//  ChainInfo.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct ChainInfo: Codable {
    
    var serverVersion: String?
    var chainId: String?
    var headBlockNum: UInt64
    var lastIrreversibleBlockNum: UInt64
    var lastIrreversibleBlockId: String?
    var headBlockId: String?
    var headBlockTime: Date?
    var headBlockProducer: String?
    var virtualBlockCpuLimit: UInt64
    var blockCpuLimit: UInt64
    var blockNetLimit: UInt64
    
}
