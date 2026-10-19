/*
 MIT License

 Copyright (c) 2026 Calogero Sanfilippo

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import MCP
import Foundation

struct NameContains: NonEmptyStringArgument {
    static let name = "name_contains"
    let value: String

    init(from arguments: [String: Value]?) throws(NonEmptyStringError) {
        value = try Self.nonEmptyValue(in: arguments)
    }
}

struct SearchCriteria {
    enum Error: ToolFailure {
        case noFilters

        var message: String {
            "at least one of name_contains or kind is required"
        }
    }

    private let nameContains: NameContains?
    private let kind: Kind?

    init(from arguments: [String: Value]?) throws {
        if arguments?[NameContains.name] != nil {
            nameContains = try NameContains(from: arguments)
        } else {
            nameContains = nil
        }
        kind = try Kind(from: arguments)

        guard nameContains != nil || kind != nil else {
            throw Error.noFilters
        }
    }

    var spotlightQuery: String {
        [
            nameContains.map { #"kMDItemDisplayName == "*\#(literal($0.value))*"cd"# },
            kind?.spotlightQuery,
        ]
        .compactMap { $0 }
        .joined(separator: " && ")
    }
}

// Backslashes must be escaped first, or the backslashes added for quotes and asterisks would be doubled.
private func literal(_ value: String) -> String {
    value
        .replacingOccurrences(of: #"\"#, with: #"\\"#)
        .replacingOccurrences(of: #"""#, with: #"\""#)
        .replacingOccurrences(of: "*", with: #"\*"#)
}
