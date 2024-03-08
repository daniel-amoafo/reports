// Created by Daniel Amoafo on 20/2/2024.

@testable import Reports
import XCTest

final class URLTests: XCTestCase {

    func testFragmentDictionary() throws {
        let path = "cw-reports://oauth#access_token=aValidValue&token_type=Bearer&expires_in=7200"
        let url = URL(string: path)!
        let fragmentItems = try XCTUnwrap(url.fragmentItems)
        XCTAssertEqual(fragmentItems.count, 3)
        XCTAssertEqual(fragmentItems["access_token"], "aValidValue")
        XCTAssertEqual(fragmentItems["token_type"], "Bearer")
        XCTAssertEqual(fragmentItems["expires_in"], "7200")
    }
}
