//
//  TransactionUtil+Extensions.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-03-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal class PackedTransactionUtil: NSObject {
    
    /**
     * This function creates a SignedTransaction that can be used for POST requests.
     * - Parameter code: The action code, i.e. "fio.system"
     * - Parameter action: The API function to be called "registername"
     * - Parameter data: The serialized json to be sent as data. Usually you can get one posting your model to /chain/serialize_json
     * - Parameter account: A hash generated value representing an account (actor aka FIO public address)
     * - Parameter privateKey: The private key to sign the transaction
     * - Parameter completion: A callback that expects SignedTransaction or Error, both optionals
     */
    static func packAndSignTransaction(code: String, action: String, data: String, account: String, privateKey: PrivateKey, completion: @escaping (_ signedTransaction: SignedTransaction?, _ error: Error?) -> ()) {
        FIOSDK.sharedInstance().chainInfo { (chainInfo, error) in
            if error != nil {
                completion(nil, error)
                return
            }
            FIOSDK.sharedInstance().getBlock(blockNumOrId: "\(chainInfo!.lastIrreversibleBlockNum)" as AnyObject, completion: { (blockInfo, error) in
                if error != nil {
                    completion(nil, error)
                    return
                }
                var actions: [Action] = []
                let auth = Authorization(actor: account, permission: "active")
                let action = Action(account: code, name: action, authorization: [auth], data: data)
                actions.append(action)
                let rawTx = Transaction(blockInfo: blockInfo!, actions: actions)
                var tx = PackedTransaction(transaction: rawTx, compression: "none")
                tx.sign(pk: privateKey, chainId: chainInfo!.chainId!)
                let signedTx = SignedTransaction(packedTx: tx)
                completion(signedTx, nil)
            })
        }
    }
    
}
