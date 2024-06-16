// Created by Daniel Amoafo on 20/2/2024.

import Foundation

extension URL {

    var isDeeplink: Bool {
        // my-url-scheme://<rest-of-the-url>
        return ["cw-reports", "https"].contains(scheme)
    }

    var queryItems: [URLQueryItem]? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems
    }

    var fragmentItems: [String: String]? {
        guard let array = URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .fragment?.split(separator: "&") else {
            return nil
        }
        // take the array of fragments and store values as a dictionary,
        // each entry will have a string value of key=value format.
        return array.reduce(into: [String: String]()) { (dict, substring) in
            if let index = substring.firstIndex(where: { $0 == "=" }) {
                let key = String(substring[substring.startIndex..<index])
                let value = String(substring[substring.index(after: index)..<substring.endIndex])
                dict[key] = value
            }
        }
    }
}
