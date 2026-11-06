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

struct UnreadableFolder: Codable {
    let path: String
    let fix: String
}

struct OxusResponse: Codable {
    let paths: [String]
    let unreadableFolders: [UnreadableFolder]?
    let truncated: Bool

    init(paths: [String], unreadableFolders: [UnreadableFolder] = [], truncated: Bool) {
        self.paths = paths
        self.unreadableFolders = unreadableFolders.isEmpty ? nil : unreadableFolders
        self.truncated = truncated
    }

    static let schema: Value = .object([
        "type": "object",
        "properties": .object([
            "paths": .object([
                "type": "array",
                "items": .object(["type": "string"]),
                "description": "Paths of the matching files, in Spotlight's order",
            ]),
            "unreadableFolders": .object([
                "type": "array",
                "items": .object([
                    "type": "object",
                    "properties": .object([
                        "path": .object([
                            "type": "string",
                            "description": "Path of a protected folder that oxus cannot read",
                        ]),
                        "fix": .object([
                            "type": "string",
                            "description": "What the user has to change for oxus to read the folder",
                        ]),
                    ]),
                    "required": ["path", "fix"],
                ]),
                "description":
                    "Protected folders macOS privacy protection denies to oxus. Their files are missing from paths until the user applies the fix",
            ]),
            "truncated": .object([
                "type": "boolean",
                "description": "True when more matches exist than paths holds, so raise limit or narrow the search",
            ]),
        ]),
        "required": ["paths", "truncated"],
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
