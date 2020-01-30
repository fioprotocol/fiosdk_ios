//
//  KeyChainInteractor.swift
//  FIOSDK
//
//  Created by Vitor Navarro on 2019-04-05.
//  Copyright © 2019 Dapix, Inc. All rights reserved.
//

import Foundation

/**
 * Wrapper for store and retrieve objects on keychain
 */
internal class KeychainInteractor {
    
    private let walletSecAttrService: String!
    
    convenience init() {
        self.init(walletSecAttrService: "io.dapix.breadwallet")
    }
    
    init(walletSecAttrService: String) {
        self.walletSecAttrService = walletSecAttrService
    }
    
    func keychainItem<T>(key: String) throws -> T? {
        let query = [kSecClass as String : kSecClassGenericPassword as String,
                     kSecAttrService as String : self.walletSecAttrService,
                     kSecAttrAccount as String : key,
                     kSecReturnData as String : true as Any]
        var result: CFTypeRef? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &result);
        guard status == noErr || status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        guard let data = result as? Data else { return nil }
        
        switch T.self {
        case is Data.Type:
            return data as? T
        case is String.Type:
            return CFStringCreateFromExternalRepresentation(secureAllocator, data as CFData,
                                                            CFStringBuiltInEncodings.UTF8.rawValue) as? T
        case is Int64.Type:
            guard data.count == MemoryLayout<T>.stride else { return nil }
            return data.withUnsafeBytes { $0.pointee }
        case is Dictionary<AnyHashable, Any>.Type:
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
        default:
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(errSecParam))
        }
    }
    
    func setKeychainItem<T>(key: String, item: T?, authenticated: Bool = false) throws {
        let accessible = (authenticated) ? kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
            : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        let query = [kSecClass as String : kSecClassGenericPassword as String,
                     kSecAttrService as String : self.walletSecAttrService,
                     kSecAttrAccount as String : key]
        var status = noErr
        var data: Data? = nil
        if let item = item {
            switch T.self {
            case is Data.Type:
                data = item as? Data
            case is String.Type:
                data = CFStringCreateExternalRepresentation(secureAllocator, item as! CFString,
                                                            CFStringBuiltInEncodings.UTF8.rawValue, 0) as Data
            case is Int64.Type:
                data = CFDataCreateMutable(secureAllocator, MemoryLayout<T>.stride) as Data
                [item].withUnsafeBufferPointer { data?.append($0) }
            case is Dictionary<AnyHashable, Any>.Type:
                data = NSKeyedArchiver.archivedData(withRootObject: item)
            default:
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(errSecParam))
            }
        }
        
        if data == nil { // delete item
            if SecItemCopyMatching(query as CFDictionary, nil) != errSecItemNotFound {
                status = SecItemDelete(query as CFDictionary)
            }
        }
        else if SecItemCopyMatching(query as CFDictionary, nil) != errSecItemNotFound { // update existing item
            let update = [kSecAttrAccessible as String : accessible,
                          kSecValueData as String : data as Any]
            status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        }
        else { // add new item
            let item = [kSecClass as String : kSecClassGenericPassword as String,
                        kSecAttrService as String : self.walletSecAttrService,
                        kSecAttrAccount as String : key,
                        kSecAttrAccessible as String : accessible,
                        kSecValueData as String : data as Any]
            status = SecItemAdd(item as CFDictionary, nil)
        }
        
        guard status == noErr else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
    
}

public let secureAllocator: CFAllocator = {
    var context = CFAllocatorContext()
    context.version = 0;
    CFAllocatorGetContext(kCFAllocatorDefault, &context);
    context.allocate = secureAllocate
    context.reallocate = secureReallocate;
    context.deallocate = secureDeallocate;
    return CFAllocatorCreate(kCFAllocatorDefault, &context).takeRetainedValue()
}()

private func secureAllocate(allocSize: CFIndex, hint: CFOptionFlags, info: UnsafeMutableRawPointer?)
    -> UnsafeMutableRawPointer?
{
    guard let ptr = malloc(MemoryLayout<CFIndex>.stride + allocSize) else { return nil }
    // keep track of the size of the allocation so it can be cleansed before deallocation
    ptr.storeBytes(of: allocSize, as: CFIndex.self)
    return ptr.advanced(by: MemoryLayout<CFIndex>.stride)
}

private func secureDeallocate(ptr: UnsafeMutableRawPointer?, info: UnsafeMutableRawPointer?)
{
    guard let ptr = ptr else { return }
    let allocSize = ptr.load(fromByteOffset: -MemoryLayout<CFIndex>.stride, as: CFIndex.self)
    memset(ptr, 0, allocSize) // cleanse allocated memory
    free(ptr.advanced(by: -MemoryLayout<CFIndex>.stride))
}

private func secureReallocate(ptr: UnsafeMutableRawPointer?, newsize: CFIndex, hint: CFOptionFlags,
                              info: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?
{
    // there's no way to tell ahead of time if the original memory will be deallocted even if the new size is smaller
    // than the old size, so just cleanse and deallocate every time
    guard let ptr = ptr else { return nil }
    let newptr = secureAllocate(allocSize: newsize, hint: hint, info: info)
    let allocSize = ptr.load(fromByteOffset: -MemoryLayout<CFIndex>.stride, as: CFIndex.self)
    if (newptr != nil) { memcpy(newptr, ptr, (allocSize < newsize) ? allocSize : newsize) }
    secureDeallocate(ptr: ptr, info: info)
    return newptr
}
