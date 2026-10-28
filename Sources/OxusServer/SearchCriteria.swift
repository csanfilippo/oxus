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

import Foundation
import MCP

struct NameContains: NonEmptyStringArgument {
    static let name = "name_contains"
    let value: String

    init(_ argument: Value) throws(NonEmptyStringError) {
        value = try Self.nonEmptyValue(of: argument)
    }
}

struct SearchCriteria {
    enum Error: ToolFailure {
        case noFilters

        var message: String {
            "at least one of \(NameContains.name) or \(Kind.name) or \(Folder.name) is required"
        }
    }

    private let nameContains: NameContains?
    private let kind: Kind?
    let folder: Folder?

    private var onlyFolder: Bool {
        nameContains == nil && kind == nil
    }

    init(nameContains: NameContains? = nil, kind: Kind? = nil, folder: Folder? = nil) throws(Error) {
        self.nameContains = nameContains
        self.kind = kind
        self.folder = folder

        guard nameContains != nil || kind != nil || folder != nil else {
            throw .noFilters
        }
    }

    var spotlightQuery: String {

        guard !onlyFolder else {
            return #"kMDItemDisplayName == "*""#
        }

        return [
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
