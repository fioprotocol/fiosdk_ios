//
//  Utilities.swift
//  FIOWalletSDK
//
//  Created by shawn arney on 10/18/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import Foundation

public class Utilities:NSObject{
    
    private static var _sharedInstance: Utilities = {
        let sharedInstance = Utilities()
        
        return sharedInstance
    }()
    
    public class func sharedInstance() -> Utilities {
        return _sharedInstance
    }
    
    public var URL:String = ""
    
    public func getSettingForBundle (keyName:String) -> String{
        let bundle = Bundle(for: type(of: self))
        
        if let url = bundle.url(forResource:"Settings", withExtension: "plist"),
            let myDict = NSDictionary(contentsOf: url) as? [String:Any] {
            if (myDict.keys.contains(keyName)){
                return myDict[keyName] as! String
            }
        }
        
       // AccountUtil
        return ""
    }

    public func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz12345"
        return String((0...length-1).map{ _ in letters.randomElement()! })
    }
}

extension Float {
    func string(fractionDigits:Int) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
