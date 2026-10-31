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

struct NameContains {
    enum Error: Swift.Error {
        case blank
    }

    let text: String

    init(_ text: String) throws(Error) {
        guard !text.isBlank else {
            throw .blank
        }

        self.text = text
    }
}

struct NameContainsArgument: NonEmptyStringArgument {
    static let name = "name_contains"
    static let schema: Value = .object([
        "type": "string",
        "description": "Text the file's name must contain",
    ])

    let nameContains: NameContains

    init(_ argument: Value) throws(NonEmptyStringError) {
        let text = try Self.stringValue(of: argument)

        do {
            nameContains = try NameContains(text)
        } catch {
            throw .empty(argument: Self.name)
        }
    }
}
