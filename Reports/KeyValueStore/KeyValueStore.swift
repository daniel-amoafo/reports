import Foundation

// A protocol that mimics the API of NSUserDefaults so that we can decouple
// ourselves from that implementation.
public protocol KeyValueStore: Sendable {

    var count: Int { get }
    var keys: [String] { get }

    func bool(forKey: String) -> Bool?
    func integer(forKey: String) -> Int?
    func double(forKey: String) -> Double?
    func string(forKey: String) -> String?
    func data(forKey: String) -> Data?
    func date(forKey: String) -> Date?
    func url(forKey: String) -> URL?
    func array<T: KeyValueStoreValue>(forKey: String) -> [T]?
    func dictionary<T: KeyValueStoreValue>(forKey: String) -> [String: T]?

    func set(_ bool: Bool?, forKey: String)
    func set(_ integer: Int?, forKey: String)
    func set(_ double: Double?, forKey: String)
    func set(_ string: String?, forKey: String)
    func set(_ data: Data?, forKey: String)
    func set(_ date: Date?, forKey: String)
    func set(_ url: URL?, forKey: String)
    func set<T: KeyValueStoreValue>(_ array: [T]?, forKey: String)
    func set<T: KeyValueStoreValue>(_ dictionary: [String: T]?, forKey: String)

    func removeValue(forKey: String)
    func removeAllValues()

}

// MARK: - KeyValueStoreValue

public protocol KeyValueStoreValue: Codable, Equatable, Sendable {}

extension String: KeyValueStoreValue {}
extension Date: KeyValueStoreValue {}
extension Data: KeyValueStoreValue {}
extension Bool: KeyValueStoreValue {}
extension Int: KeyValueStoreValue {}
extension Double: KeyValueStoreValue {}
extension URL: KeyValueStoreValue {}
extension Array: KeyValueStoreValue where Element: KeyValueStoreValue {}
extension Dictionary: KeyValueStoreValue where Key == String, Value: KeyValueStoreValue {}

// MARK: - UserDefaults

extension UserDefaults: KeyValueStore, @unchecked @retroactive Sendable {

    public var count: Int {
        return dictionaryRepresentation().count
    }

    public var keys: [String] {
        return dictionaryRepresentation().keys.compactMap({ $0 as String })
    }

    public func bool(forKey key: String) -> Bool? {
        return (object(forKey: key) != nil) ? bool(forKey: key) as Bool : nil
    }

    public func integer(forKey key: String) -> Int? {
        return (object(forKey: key) != nil) ? integer(forKey: key) as Int : nil
    }

    public func double(forKey key: String) -> Double? {
        return (object(forKey: key) != nil) ? double(forKey: key) as Double : nil
    }

    public func data(forKey key: String) -> Data? {
        return object(forKey: key) as? Data
    }

    public func date(forKey key: String) -> Date? {
        return object(forKey: key) as? Date
    }

    public func array<T: KeyValueStoreValue>(forKey key: String) -> [T]? {
        return array(forKey: key) as [Any]? as? [T]
    }

    public func dictionary<T: KeyValueStoreValue>(forKey key: String) -> [String: T]? {
        return dictionary(forKey: key) as [String: Any]? as? [String: T]
    }

    public func set(_ bool: Bool?, forKey key: String) {
        if let bool {
            set(bool, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }

    public func set(_ integer: Int?, forKey key: String) {
        if let integer {
            set(integer, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }

    public func set(_ double: Double?, forKey key: String) {
        if let double {
            set(double, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }

    public func set(_ string: String?, forKey key: String) {
        set(string as Any?, forKey: key)
    }

    public func set(_ data: Data?, forKey key: String) {
        set(data as Any?, forKey: key)
    }

    public func set(_ date: Date?, forKey key: String) {
        set(date as Any?, forKey: key)
    }

    public func set<T: KeyValueStoreValue>(_ array: [T]?, forKey key: String) {
        set(array as Any?, forKey: key)
    }

    public func set<T: KeyValueStoreValue>(_ dictionary: [String: T]?, forKey key: String) {
        set(dictionary as Any?, forKey: key)
    }

    public func removeValue(forKey key: String) {
        removeObject(forKey: key)
    }

    public func removeAllValues() {
        dictionaryRepresentation().keys.forEach { removeObject(forKey: $0) }
    }

}
