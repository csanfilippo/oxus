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

struct SpotlightQueryTool: OxusTool {
    let spotlight: any Spotlight

    let definition: Tool = Tool(
        name: "spotlight_query",
        description:
            "Runs a raw Spotlight query and returns the paths of matching files. The query uses Spotlight query syntax (https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html), e.g. kMDItemFSName == \"*.pdf\"c finds files whose name ends in .pdf, ignoring case. Returns at most \(Limit.maximum) paths.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                Query.name: .object([
                    "type": "string",
                    "description": "Spotlight query syntax, e.g. kMDItemFSName == \"*.pdf\"c",
                ]),
                "limit": Limit.schema,
            ]),
            "required": [.string(Query.name)],
        ]),
        annotations: Tool.Annotations(readOnlyHint: true, openWorldHint: false),
        outputSchema: OxusResponse.schema
    )

    func call(with arguments: [String: Value]?) async throws -> CallTool.Result {
        do {
            let criteria = try Query(from: arguments)
            let limit = try Limit(arguments?["limit"])
            return try await spotlight.pathsResult(query: criteria.spotlightQuery, limit: limit.value, folder: nil)
        } catch let failure as any ToolFailure {
            return failure.asResult
        }
    }
}
