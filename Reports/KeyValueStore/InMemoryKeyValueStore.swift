// Created by Daniel Amoafo on 5/2/2024.

import Foundation

public final class InMemoryKeyValueStore {

    // MARK: - Private Properties

    private var storage: [String: any KeyValueStoreValue] = [:]

    public init(storage: [String: any KeyValueStoreValue] = [:]) {
        self.storage = storage
    }
}

extension InMemoryKeyValueStore: @unchecked Sendable, KeyValueStore {

    // MARK: - KeyValueStore

    public var count: Int {
        storage.count
    }

    public var keys: [String] {
        storage.keys.compactMap { $0 as String }
    }

    public func bool(forKey key: String) -> Bool? {
        storage[key] as? Bool
    }

    public func integer(forKey key: String) -> Int? {
        storage[key] as? Int
    }

    public func double(forKey key: String) -> Double? {
        storage[key] as? Double
    }

    public func string(forKey key: String) -> String? {
        storage[key] as? String
    }

    public func data(forKey key: String) -> Data? {
        storage[key] as? Data
    }

    public func date(forKey key: String) -> Date? {
        storage[key] as? Date
    }

    public func url(forKey key: String) -> URL? {
        guard let nsURL: NSURL = fetch(key) else { return nil }
        return nsURL as URL
    }

    public func array<T: KeyValueStoreValue>(forKey key: String) -> [T]? {
        storage[key] as? [T]
    }

    public func dictionary<T: KeyValueStoreValue>(forKey key: String) -> [String: T]? {
        storage[key] as? [String: T]
    }

    public func set(_ value: Bool?, forKey key: String) {
        storage[key] = value
    }

    public func set(_ value: Int?, forKey key: String) {
        storage[key] = value
    }

    public func set(_ value: Double?, forKey key: String) {
        storage[key] = value
    }

    public func set(_ string: String?, forKey key: String) {
        storage[key] = string
    }

    public func set(_ data: Data?, forKey key: String) {
        storage[key] = data
    }

    public func set(_ date: Date?, forKey key: String) {
        storage[key] = date
    }

    public func set(_ url: URL?, forKey key: String) {
        storage[key] = url
    }

    public func set<T: KeyValueStoreValue>(_ array: [T]?, forKey key: String) {
        storage[key] = array
    }

    public func set<T: KeyValueStoreValue>(_ dictionary: [String: T]?, forKey key: String) {
        storage[key] = dictionary
    }

    public func removeValue(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    public func removeAllValues() {
        storage.removeAll()
    }

    // MARK: - Private Methods

    /**
     Fetch a value from the storage, decoding from Data if necessary.
     */
    private func fetch<DecodedObjectType>(_ key: String) -> DecodedObjectType?
    where DecodedObjectType: NSObject & NSCoding {
        if let val = storage[key] as? DecodedObjectType {
            return val
        } else if let data = data(forKey: key) {
            return try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: DecodedObjectType.self,
                from: data
            )
        } else {
            return nil
        }
    }

}
