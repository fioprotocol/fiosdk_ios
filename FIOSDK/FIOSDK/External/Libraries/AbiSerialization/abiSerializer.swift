//
//  abiSerializer.swift
//  FIOSDK
//
//  Created by shawn arney on 8/12/19.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

/*
 
 let abieos: EosioAbieosSerializationProvider? = EosioAbieosSerializationProvider()
 let hex = "1686755CA99DE8E73E1200" // some binary data
 let json = "{"name": "John"}" // some JSON
 
 let jsonToBinaryTransaction = try? abieos?.serializeTransaction(json: json)
 let binaryToJsonTransaction = try? abieos?.deserializeTransaction(hex: hex)
 
 
 */


import Foundation

class abiSerializer {
    
    private var context = abieos_create()
    private var abiJsonString = ""
    
    /// Getter to return error as a String.
    public var error: String? {
        return String(validatingUTF8: abieos_get_error(context))
    }
    
    /// Default init.
    required public init() {
        
    }
    
    deinit {
        abieos_destroy(context)
    }
    
    /// Convert ABIEOS String data to UInt64 value.
    ///
    /// - Parameter string: String data to convert.
    /// - Returns: A UInt64 value.
    public func name64(string: String?) -> UInt64 {
        guard let string = string else { return 0 }
        return abieos_string_to_name(context, string)
    }
    
    /// Convert ABIEOS UInt64 data to String value.
    ///
    /// - Parameter name64: A UInt64 value to convert.
    /// - Returns: A string value.
    public func string(name64: UInt64) -> String? {
        return String(validatingUTF8: abieos_name_to_string(context, name64))
    }
    
    private func refreshContext() {
        if context != nil {
            abieos_destroy(context)
        }
        context = abieos_create()
    }
    
    private func getAbiJsonFile(fileName: String) throws -> String {
        var abiString = ""
        
        let bundle = Bundle(for: type(of: self))
        let path = bundle.url(forResource: fileName, withExtension: nil)?.path ?? ""
        abiString = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
        guard abiString != "" else {
          // throw // throw Error(.serializationProviderError, reason: "Json to hex -- No ABI file found for \(fileName)")
            throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "getAbiJsonFile"])
        }
        return abiString
    }
    
    /// Convert JSON Transaction data representation to ABIEOS binary representation of Transaction data.
    ///
    /// - Parameter json: The JSON representation of Transaction data to serialize.
    /// - Returns: A binary String of Transaction data.
    /// - Throws: If the data cannot be serialized for any reason.
    public func serializeTransaction(json: String) throws -> String {
        let transactionJson = try getAbiJsonFile(fileName: "transaction.abi.json")
        return try serialize(contract: nil, name: "", type: "transaction", json: json, abi: transactionJson)
    }
    
    /// Convert JSON ABI data representation to ABIEOS binary of data.
    ///
    /// - Parameter json: The JSON data String to serialize.
    /// - Returns: A String of binary data.
    /// - Throws: If the data cannot be serialized for any reason.
    public func serializeAbi(json: String) throws -> String {
        let abiJson = try getAbiJsonFile(fileName: "abi.abi.json")
        return try serialize(contract: nil, name: "error_message", type: "abi_def", json: json, abi: abiJson)
    }
    
    /// Calls ABIEOS to carry out JSON to binary conversion using ABIs.
    ///
    /// - Parameters:
    ///   - contract: An optional String representing contract name for the serialize action lookup for this ABIEOS conversion.
    ///   - name: An optional String representing an action name that is used in conjunction with contract (above) to derive the serialize type name.
    ///   - type: An optional string representing the type name for the serialize action lookup for this serialize conversion.
    ///   - json: The JSON data String to serialize to binary.
    ///   - abi: A String representation of the ABI to use for conversion.
    /// - Returns: A String of binary serialized data.
    /// - Throws: If the data cannot be serialized for any reason.
    //shawn notes
    #warning("I could pass in the raw abi for this here")
    public func serialize(contract: String?, name: String = "", type: String? = nil, json: String, abi: String) throws -> String {
        
        refreshContext()
        
        let contract64 = name64(string: contract)
        abiJsonString = abi
        
        // set the abi
        let setAbiResult = abieos_set_abi(context, contract64, abiJsonString)
        guard setAbiResult == 1 else {
            throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "json to hex"])
        }
        
        // get the type name for the action
        guard let type = type ?? getType(action: name, contract: contract64) else {
            throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "unable to find type for action"])
        }
        
        var jsonToBinResult: Int32 = 0
        jsonToBinResult = abieos_json_to_bin_reorderable(context, contract64, type, json)
        
        guard jsonToBinResult == 1 else {
          throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "unable to pack json to bin"])
        }
        
        guard let hex = String(validatingUTF8: abieos_get_bin_hex(context)) else {
          throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "unable to convert binary to hex"])
        }
        return hex
    }
    
    /// Converts a binary string of ABIEOS Transaction data to JSON string representation of Transaction data.
    ///
    /// - Parameter hex: The binary Transaction data String to deserialize.
    /// - Returns: A String of JSON Transaction data.
    /// - Throws: If the data cannot be deserialized for any reason.
    public func deserializeTransaction(hex: String) throws -> String {
        let transactionJson = try getAbiJsonFile(fileName: "transaction.abi.json")
        return try deserialize(contract: nil, name: "", type: "transaction", hex: hex, abi: transactionJson)
    }
    
    /// Converts a binary string of ABIEOS data to JSON string data.
    ///
    /// - Parameter hex: The binary data String to deserialize.
    /// - Returns: A String of JSON data.
    /// - Throws: If the data cannot be deserialized for any reason.
    public func deserializeAbi(hex: String) throws -> String {
        let abiJson = try getAbiJsonFile(fileName: "abi.abi.json")
        return try deserialize(contract: nil, name: "", type: "abi_def", hex: hex, abi: abiJson)
    }
    
    /// Calls ABIEOS to carry out binary to JSON conversion using ABIs.
    ///
    /// - Parameters:
    ///   - contract: An optional String representing contract name for the ABIEOS action lookup for this ABIEOS conversion.
    ///   - name: An optional String representing an action name that is used in conjunction with contract (above) to derive the ABIEOS type name.
    ///   - type: An optional string representing the type name for the ABIEOS action lookup for this ABIEOS conversion.
    ///   - hex: The binary data String to deserialize to a JSON String.
    ///   - abi: A String representation of the ABI to use for conversion.
    /// - Returns: A String of JSON data.
    /// - Throws: If the data cannot be deserialized for any reason.
    public func deserialize(contract: String?, name: String = "", type: String? = nil, hex: String, abi: String) throws -> String {
        
        refreshContext()
        
        let contract64 = name64(string: contract)
        abiJsonString = abi
        
        // set the abi
        let setAbiResult = abieos_set_abi(context, contract64, abiJsonString)
        guard setAbiResult == 1 else {
           // throw Error(.serializationProviderError, reason: "Hex to json -- Unable to set ABI. \(self.error ?? "")")
            throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "hex to json - unable to set abi"])
        }
        
        // get the type name for the action
        guard let type = type ?? getType(action: name, contract: contract64) else {
           // throw Error(.serializationProviderError, reason: "Unable find type for action \(name). \(self.error ?? "")")
            throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "unable to find type for action"])
        }
        
        if let json = abieos_hex_to_json(context, contract64, type, hex) {
            if let string = String(validatingUTF8: json) {
                return string
            } else {
                throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "unable to convert c string json to String"])
            }
        } else {
          throw NSError(domain: "com.fiosdk.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "unable to unpack hex to string"])
        }
        
    }
    
    // Get the type name for the action and contract.
    private func getType(action: String, contract: UInt64) -> String? {
        let action64 = name64(string: action)
        if let type = abieos_get_type_for_action(context, contract, action64) {
            return String(validatingUTF8: type)
        } else {
            return nil
        }
    }
    
    private func jsonString(dictionary: [String: Any]) -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    
}
