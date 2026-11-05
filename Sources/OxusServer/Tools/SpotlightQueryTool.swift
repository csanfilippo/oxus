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
    let privacyProtectionProbe: PrivacyProtectionProbe

    let definition: Tool = Tool(
        name: "spotlight_query",
        description:
            "Runs a raw Spotlight query and returns the paths of matching files. The query uses Spotlight query syntax (https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html), e.g. kMDItemFSName == \"*.pdf\"c finds files whose name ends in .pdf, ignoring case. Returns at most \(Limit.maximum) paths.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                QueryArgument.name: QueryArgument.schema,
                LimitArgument.name: LimitArgument.schema,
            ]),
            "required": [.string(QueryArgument.name)],
        ]),
        annotations: Tool.Annotations(readOnlyHint: true, openWorldHint: false),
        outputSchema: OxusResponse.schema
    )

    func call(with arguments: [String: Value]) async throws -> CallTool.Result {
        do {
            let query = try arguments.required(QueryArgument.self).query
            let limit = try arguments.optional(LimitArgument.self)?.limit ?? .default
            let unreadableFolders = privacyProtectionProbe.unreadableFolders(in: nil)
            let matches = try await spotlight.search(query: query, limit: limit, folder: nil)
            return try OxusResponse(paths: matches.paths, unreadableFolders: unreadableFolders).asResult
        } catch let failure as any ToolFailure {
            return failure.asResult
        }
    }
}
