//
//  BlockInfo.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal class BlockInfo: NSObject, Codable {
    
    var previous: String?
    var timestamp: Date?
    var transactionMerkleRoot: String?
    var producer: String?
    var producerChanges: [String]?
    var producerSignature: String?
    var cycles: [String]?
    var id: String?
    var blockNum: Int = 0
    var refBlockPrefix: Int = 0
    
    // not metioned in the doc
    var actionMerkleRoot: String?
    var blockMerkleRoot: String?
    var scheduleVersion: UInt64 = 0
    var newProducers: [String]?
    var inputTransactions: [String]?
    //    var regions: [Any]?
    
    override init() {
        
    }
    
}
