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

struct Limit: ToolArgument {

    static let name = "limit"

    static let schema: Value = .object([
        "type": "integer",
        "maximum": .int(Limit.maximum),
        "minimum": .int(Limit.minimum),
        "description": "The maximum number of paths to return",
    ])

    static let minimum = 1
    static let maximum = 100
    static let `default` = Limit(value: 25)

    enum Error: ToolFailure {
        case notAnInteger
        case belowMinimum(received: Int)

        var message: String {
            switch self {
            case .notAnInteger:
                return "limit must be an integer"
            case .belowMinimum(let received):
                return "limit must be at least \(Limit.minimum), got \(received)"
            }
        }
    }

    let value: Int

    private init(value: Int) {
        self.value = value
    }

    init(_ argument: Value) throws(Error) {
        guard let intValue = argument.intValue else {
            throw .notAnInteger
        }

        guard intValue >= Self.minimum else {
            throw .belowMinimum(received: intValue)
        }

        self.value = min(intValue, Self.maximum)
    }
}
