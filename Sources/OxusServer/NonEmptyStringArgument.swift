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

enum NonEmptyStringError: ToolFailure {
    case empty(argument: String)
    case notAString(argument: String)

    var message: String {
        return switch self {
        case .empty(let argument):
            "\(argument) cannot be empty"
        case .notAString(let argument):
            "\(argument) must be a string"
        }
    }
}

protocol NonEmptyStringArgument: ToolArgument {}

extension NonEmptyStringArgument {
    static func nonEmptyValue(of argument: Value) throws(NonEmptyStringError) -> String {
        guard let string = argument.stringValue else { throw .notAString(argument: name) }
        guard string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { throw .empty(argument: name) }
        return string
    }
}
