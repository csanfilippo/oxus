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

struct OxusResponse: Codable {
    let paths: [String]

    static let schema: Value = .object([
        "type": "object",
        "properties": .object([
            "paths": .object([
                "type": "array",
                "items": .object(["type": "string"]),
                "description": "Paths of the matching files, in Spotlight's order",
            ]),
        ]),
        "required": ["paths"],
    ])
}

private extension Array where Element == String {
    var asOxusResponse: OxusResponse {
        .init(paths: self)
    }
}

extension Spotlight {
    func pathsResult(query: String, limit: Int) async throws -> CallTool.Result {
        let paths: [String]
        do {
            paths = try await search(query: query, limit: limit)
        } catch let spotlightError {
            return spotlightError.asResult
        }
        let response = paths.asOxusResponse
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let text = String(decoding: try encoder.encode(response), as: UTF8.self)
        return try CallTool.Result(content: [.text(text: text, annotations: nil, _meta: nil)], structuredContent: response, isError: false)
    }
}
