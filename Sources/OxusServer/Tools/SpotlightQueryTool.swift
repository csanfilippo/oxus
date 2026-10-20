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

struct SpotlightQueryTool: OxusTool {
    
    private let spotlight: any Spotlight
    
    let definition: Tool = Tool(
        name: "spotlight_query",
        description: "Perform raw Spotlight queries",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                Query.name: .object([
                    "type": "string",
                    "description": "The query to be performed",
                ]),
                "limit": .object([
                    "type": "integer",
                    "maximum": .int(Limit.maximum),
                    "minimum": .int(Limit.minimum),
                    "description": "The maximum number of paths to return",
                ]),
            ]),
            "required": [.string(Query.name)],
        ]),
        outputSchema: OxusResponse.schema
    )
    
    init(spotlight: any Spotlight) {
        self.spotlight = spotlight
    }
    
    func call(with arguments: [String : Value]?) async throws -> CallTool.Result {
        do {
            let (query, limit) = try queryAndLimit(arguments: arguments)
            return try await spotlight.pathsResult(query: query, limit: limit)
        } catch let failure as any ToolFailure {
            return failure.asResult
        }
    }
    
    private func queryAndLimit(arguments: [String : Value]?) throws -> (query: String, limit: Int) {
        let query = try Query(from: arguments)
        let limit = try Limit(arguments?["limit"])
        return (query: query.value, limit: limit.value)
    }
}
