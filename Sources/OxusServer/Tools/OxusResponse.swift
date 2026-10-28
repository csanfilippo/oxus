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

struct OxusResponse: Codable {
    let paths: [String]

    static let schema: Value = .object([
        "type": "object",
        "properties": .object([
            "paths": .object([
                "type": "array",
                "items": .object(["type": "string"]),
                "description": "Paths of the matching files, in Spotlight's order",
            ])
        ]),
        "required": ["paths"],
    ])

    var asResult: CallTool.Result {
        get throws {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let text = String(decoding: try encoder.encode(self), as: UTF8.self)
            return try CallTool.Result(content: [.text(text: text, annotations: nil, _meta: nil)], structuredContent: self, isError: false)
        }
    }
}
