//
//  FIOError.swift
//  FIOSDK
//
//  Created by shawn arney on 10/19/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import Foundation

public struct FIOError: Error {
    public enum ErrorKind {
        case Success
        case NoDataReturned
        case FailedToUsePrivKey
        case MalformedRequest
        case MalformedURL
        case Failure
    }
    public let kind: ErrorKind
    public let localizedDescription: String
}
