//
//  AddPublicAddressOperation.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-04.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

internal class AddPublicAddressOperation {
    
    typealias AddPublicAdddressOperationAction = (_ operation: AddPublicAddressOperation) -> Void
    
    var action: AddPublicAdddressOperationAction!
    var operations: [AddPublicAddressOperation]!
    var index: Int!
    
    init(action: @escaping AddPublicAdddressOperationAction, index: Int) {
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
