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

struct SearchTool: OxusTool {
    let definition: Tool = Tool(
        name: "search",
        description: "Finds files by name, kind, or both, without Spotlight query syntax. At least one of name_contains or kind is required; when both are given, a file must match both. Name matching ignores case and diacritics. Returns at most \(Limit.maximum) paths.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                NameContains.name: .object([
                    "type": "string",
                    "description": "Text the file's name must contain",
                ]),
                "limit": .object([
                    "type": "integer",
                    "maximum": .int(Limit.maximum),
                    "minimum": .int(Limit.minimum),
                    "description": "The maximum number of paths to return",
                ]),
                "kind": .object([
                    "type": "string",
                    "enum": .array(Kind.allCases.map { .string($0.rawValue) }),
                    "description": "The kind of file to find; a kind includes all its subtypes, e.g. image matches PNG, JPEG and HEIC",
                ]),
            ]),
            "required": [],
        ]),
        outputSchema: OxusResponse.schema
    )
    
    private let spotlight: any Spotlight
    
    init(spotlight: any Spotlight) {
        self.spotlight = spotlight
    }
    
    func call(with arguments: [String : Value]?) async throws -> CallTool.Result {
        do {
            let (query, limit) = try searchQueryAndLimit(arguments: arguments)
            return try await spotlight.pathsResult(query: query, limit: limit)
        } catch let failure as any ToolFailure {
            return failure.asResult
        }
    }
    
    private func searchQueryAndLimit(arguments: [String : Value]?) throws -> (query: String, limit: Int) {
        let query = try SearchCriteria(from: arguments)
        let limit = try Limit(arguments?["limit"])
        return (query: query.spotlightQuery, limit: limit.value)
    }
}
