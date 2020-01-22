//
//  ChainInfo.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-12.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal struct ChainInfo: Codable {
    /*
    {
        "server_version": "f0be9dfd",
        "chain_id": "cf057bbfb72640471fd910bcb67639c22df9f92470936cddc1ade0e2f2e7dc4f",
        "head_block_num": 11451,
        "last_irreversible_block_num": 11413,
        "last_irreversible_block_id": "00002c95b37cd2b04be7677edb151b0a968da659077f3b07fe69f025423981d6",
        "head_block_id": "00002cbb0d63e285c7b46febd3a223b5440ef749582c1c91ec76889e7a6a42c2",
        "head_block_time": "2020-01-09T20:04:12.500",
        "head_block_producer": "qbxn5zhw2ypw",
        "virtual_block_cpu_limit": 200000000,
        "virtual_block_net_limit": 1048576000,
        "block_cpu_limit": 199900,
        "block_net_limit": 1048576,
        "server_version_string": "v1.2.1-3719-gf0be9dfd8",
        "fork_db_head_block_num": 11451,
        "fork_db_head_block_id": "00002cbb0d63e285c7b46febd3a223b5440ef749582c1c91ec76889e7a6a42c2"
    }
    */
    var serverVersion: String?
    var chainId: String?
    var headBlockNum: UInt64
    var lastIrreversibleBlockNum: UInt64
    var lastIrreversibleBlockId: String?
    var headBlockId: String?
    var headBlockTime: String?
    var headBlockProducer: String?
    var virtualBlockCpuLimit: UInt64
    var virtualBlockNetLimit: UInt64
    var blockCpuLimit: UInt64
    var blockNetLimit: UInt64
    var serverVersionString: String?
    var forkDbHeadBlockNum : UInt64
    var forkDbHeadBlockId: String?
    /*
    enum CodingKeys: String, CodingKey {
        case fioRequestId = "fio_request_id"
        case payerFIOAddress = "payer_fio_address"
        case payeeFIOAddress = "payee_fio_address"
        case payerFIOPublicKey = "payer_fio_public_key"
        case payeeFIOPublicKey = "payee_fio_public_key"
        case timeStamp = "time_stamp"
        case status
        case content
    }
    */
}


