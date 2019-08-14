//
//  ViewController.swift
//  exploring-se-keys
//
//  Created by David Wagner on 14/08/2019.
//  Copyright © 2019 David Wagner. All rights reserved.
//

import UIKit

extension String: Swift.Error { }

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let label = "bob"
        deleteKey(label: label)
        createKey(label: label)
        findKeyRef(label: label)
        findKeyData(label: label)
    }
    
    func query(label: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassKey,
            kSecAttrLabel as String: label,
        ]
    }
    
    func deleteKey(label: String) {
        let query = self.query(label: label)
        let result = SecItemDelete(query as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else {
            print("Could not delete value: \(result)")
            return
        }
        
        print("Deleted \(label)")
    }
    
    func createKey(label: String) {
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .privateKeyUsage, &error) else {
            print("Could not create ACL object: \(String(describing:error))")
            return
        }
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String: true,
                kSecAttrLabel as String: label,
                kSecAttrAccessControl as String: access,
            ]
        ]
        
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            print("Failed to create random key: \(String(describing:error))")
            return
        }
        
        print("Created \(label)")

        guard let cfData = SecKeyCopyExternalRepresentation(key, &error) else {
            print("Could not copy external representation: \(String(describing:error))")
            return
        }
        
        let data = cfData as Data
        let asString = data.map { String(format: "%02x", $0) } .joined(separator: " ")
        print("External representation: \(asString)")
    }
    
    func findKeyRef(label: String) {
        var query = self.query(label: label)
        query[kSecReturnRef as String] = true
        var item: CFTypeRef?
        let result = SecItemCopyMatching(query as CFDictionary, &item)
        guard result == errSecSuccess else {
            print("Could not find key: \(result)")
            return
        }

        print("Found \(label): \(String(describing: item))")
    }
    
    func findKeyData(label: String) {
        var query = self.query(label: label)
        query[kSecReturnData as String] = true
        var item: CFTypeRef?
        let result = SecItemCopyMatching(query as CFDictionary, &item)
        guard result == errSecSuccess else {
            print("Could not find key: \(result)")
            return
        }

        guard let data = item as? Data else {
            if item == nil {
                print("Item is nil")
            } else {
                print("Did not find data type: \(CFGetTypeID(item))")
            }
            return
        }
        
        let asString = data.map { String(format: "%02x", $0) } .joined(separator: " ")
        print("Found data: \(asString)")
    }
}
