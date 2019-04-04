//
//  AddPubAddressOperation.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal class AddPubAddressOperation {
    
    typealias AddPubAdddressOperationAction = (_ operation: AddPubAddressOperation) -> Void
    
    var action: AddPubAdddressOperationAction!
    var operations: [AddPubAddressOperation]!
    var index: Int!
    
    init(action: @escaping AddPubAdddressOperationAction, index: Int) {
        self.action = action
        self.index = index
    }
    
    func run() {
        action(self)
    }
    
    func next() {
        let nextIndex = index+1
        guard nextIndex < operations.count else { return }
        operations[nextIndex].run()
    }
    
}
