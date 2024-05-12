// Created by Daniel Amoafo on 6/2/2024.

import Foundation
@testable import Reports
import XCTest

final class SecureKeyValueStoreTests: XCTestCase {

    var sut: SecureKeyValueStore!

    func testSuccessStoreValues() throws {
        sut = Factory.createSecureKeyValueStore()

        // Validate values being stored in keychain correctly
        sut.set(Factory.url, forKey: "my-url")
        XCTAssertEqual(sut.url(forKey: "my-url"), Factory.url)

        sut.set(true, forKey: "my-bool")
        XCTAssertEqual(sut.bool(forKey: "my-bool"), true)

        sut.set(Factory.date, forKey: "my-date")
        XCTAssertEqual(sut.date(forKey: "my-date"), Factory.date)

        sut.set(Int(10), forKey: "my-int")
        XCTAssertEqual(sut.integer(forKey: "my-int"), Int(10))

        sut.set(Double(123.987654), forKey: "my-double")
        XCTAssertEqual(sut.double(forKey: "my-double"), Double(123.987654))

        sut.set(Data("some data value".utf8), forKey: "my-data")
        let data = try XCTUnwrap(sut.data(forKey: "my-data"))
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "some data value")

        sut.set("hello", forKey: "my-string")
        XCTAssertEqual(sut.string(forKey: "my-string"), "hello")

        sut.set([1, 2, 3, 4], forKey: "my-array")
        let arrayValues: [Int] = try XCTUnwrap(sut.array(forKey: "my-array"))
        XCTAssertEqual(arrayValues, [1, 2, 3, 4])

        sut.set(Factory.dictionary, forKey: "my-dictionary")
        let dictValues: [String: String] = try XCTUnwrap(sut.dictionary(forKey: "my-dictionary"))
        XCTAssertEqual(dictValues, Factory.dictionary)

        XCTAssertEqual(sut.count, 9)
    }

    func testRemoveKeyForNilValue() {

        sut = Factory.createSecureKeyValueStore()
        let key = "my-key"
        sut.set("hey there", forKey: key)
        XCTAssertEqual(sut.string(forKey: key), "hey there")

        let newValue: String? = nil
        sut.set(newValue, forKey: key)
        XCTAssertNil(sut.string(forKey: key))
    }

}

private enum Factory {

    static let KeyPrefix = "TEST-"
    static let url = URL(string: "http://example.com")!
    static let date = Date(timeIntervalSince1970: 1000)
    static let dictionary = ["First": "🔑", "Second": "🔒"]

    static func createSecureKeyValueStore() -> SecureKeyValueStore {
        let store = SecureKeyValueStore(keyPrefix: KeyPrefix)
        store.removeAllValues()
        return store
    }

}
