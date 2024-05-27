// Created by Daniel Amoafo on 5/2/2024.

import Foundation
import KeychainSwift

public final class SecureKeyValueStore {

    // MARK: - Private Properties
    private let keychain: KeychainSwift

    public init(keyPrefix: String = "") {
        keychain = KeychainSwift(keyPrefix: keyPrefix)
    }
}

extension SecureKeyValueStore: KeyValueStore {

    // MARK: - KeyValueStore

    public var count: Int {
        return keychain.allKeys.count
    }

    public var keys: any Collection<String> {
        return keychain.allKeys
    }

    public func bool(forKey key: String) -> Bool? {
        guard let number: NSNumber = fetch(key) else {
            return nil
        }
        return number.boolValue
    }

    public func integer(forKey key: String) -> Int? {
        guard let number: NSNumber = fetch(key) else {
            return nil
        }
        return number.intValue
    }

    public func double(forKey key: String) -> Double? {
        guard let number: NSNumber = fetch(key) else {
            return nil
        }
        return number.doubleValue
    }

    public func string(forKey key: String) -> String? {
        guard let string: NSString = fetch(key) else { return nil }
        return string as String
    }

    public func data(forKey key: String) -> Data? {
        return keychain.getData(key)
    }

    public func date(forKey key: String) -> Date? {
        guard let nsDate: NSDate = fetch(key) else {
            return nil
        }
        return nsDate as Date
    }

    public func url(forKey key: String) -> URL? {
        guard let nsURL: NSURL = fetch(key) else { return nil }
        return nsURL as URL
    }

    public func value<T: KeyValueStoreValue>(forKey key: String) -> T? {
        guard let data = keychain.getData(key) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            debugPrint("Error \(error.toString())")
            return nil
        }
    }

    public func array<T: KeyValueStoreValue>(forKey key: String) -> [T]? {
        guard let data = keychain.getData(key) else {
            return nil
        }
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            debugPrint("Error \(error.toString())")
            return nil
        }
    }

    public func dictionary<T: KeyValueStoreValue>(forKey key: String) -> [String: T]? {
        guard let data = keychain.getData(key) else {
            return nil
        }
        do {
            return try JSONDecoder().decode([String: T].self, from: data)
        } catch {
            debugPrint("Error \(error.toString())")
            return nil
        }
    }

    public func set(_ value: Bool?, forKey key: String) {
        guard let value,
              case let number = NSNumber(value: value),
              store(value: number, key: key) else {
            removeValue(forKey: key)
            return
        }
    }

    public func set(_ value: Int?, forKey key: String) {
        guard let value,
              case let number = NSNumber(value: value),
              store(value: number, key: key) else {
            removeValue(forKey: key)
            return
        }
    }

    public func set(_ value: Double?, forKey key: String) {
        guard let value,
              case let number = NSNumber(value: value),
              store(value: number, key: key) else {
            removeValue(forKey: key)
            return
        }
    }

    public func set(_ string: String?, forKey key: String) {
        guard let nsString = string as? NSString,
              store(value: nsString, key: key) else {
            removeValue(forKey: key)
            return
        }
    }

    public func set(_ data: Data?, forKey key: String) {
        guard let data else {
            removeValue(forKey: key)
            return
        }
        keychain.set(data, forKey: key)
    }

    public func set(_ date: Date?, forKey key: String) {
        guard let nsDate = date as? NSDate,
            store(value: nsDate, key: key) else {
            removeValue(forKey: key)
            return
        }
    }

    public func set(_ url: URL?, forKey key: String) {
        guard let nsUrl = url as? NSURL,
              store(value: nsUrl, key: key) else {
            removeValue(forKey: key)
            return
        }
    }

    public func set<T: KeyValueStoreValue>(_ value: T?, forKey key: String) {
        guard let value else {
            removeValue(forKey: key)
            return
        }
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
        } catch {
            debugPrint("Error: \(error.toString())")
        }
    }

    public func set<T: KeyValueStoreValue>(_ array: [T]?, forKey key: String) {
        guard let array else {
            removeValue(forKey: key)
            return
        }
        do {
            let data = try JSONEncoder().encode(array)
            set(data, forKey: key)
        } catch {
            debugPrint("Error: \(error.toString())")
        }
    }

    public func set<T: KeyValueStoreValue>(_ dictionary: [String: T]?, forKey key: String) {
        guard let dictionary else {
            removeValue(forKey: key)
            return
        }
        do {
            let data = try JSONEncoder().encode(dictionary)
            set(data, forKey: key)
        } catch {
            debugPrint("Error: \(error.toString())")
        }
    }

    public func removeValue(forKey key: String) {
        keychain.delete(key)
    }

    public func removeAllValues() {
        keychain.clear()
    }

    // MARK: - Private Methods

    /**
     Fetch a value from the storage, decoding from Data if necessary.
     */
    private func fetch<DecodedObjectType>(_ key: String) -> DecodedObjectType?
    where DecodedObjectType: NSObject & NSCoding {
        if let data = data(forKey: key) {
            return try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: DecodedObjectType.self,
                from: data
            )
        } else {
            return nil
        }
    }

    private func store<DecodedObjectType>(value: DecodedObjectType, key: String) -> Bool
    where DecodedObjectType: NSObject & NSCoding {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
            return keychain.set(data, forKey: key)
        } catch {
            fatalError("Error storing value: \(error.toString())")
        }
    }

}
