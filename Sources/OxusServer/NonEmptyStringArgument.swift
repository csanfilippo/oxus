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

enum NonEmptyStringError: ToolFailure {
    case empty(argument: String)
    case missing(argument: String)
    case notAString(argument: String)
    
    var message: String {
        return switch self {
        case .empty(let argument):
            "\(argument) cannot be empty"
        case .missing(let argument):
            "\(argument) is missing"
        case .notAString(let argument):
            "\(argument) must be a string"
        }
    }
}

protocol NonEmptyStringArgument {
    static var name: String { get }
    var value: String { get }
    init(value: String)
}

extension NonEmptyStringArgument {
    init(from arguments: [String: Value]?) throws(NonEmptyStringError) {
        guard let argument = arguments?[Self.name] else { throw .missing(argument: Self.name) }
        guard let string = argument.stringValue else { throw .notAString(argument: Self.name) }
        guard string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { throw .empty(argument: Self.name) }
        self.init(value: string)
    }
}
