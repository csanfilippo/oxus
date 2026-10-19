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

private struct OxusResponse: Codable {
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

public func makeOxusServer(spotlight: any Spotlight) async -> Server {
    let server = Server(
        name: "oxus",
        version: "0.1.0",
        capabilities: .init(tools: .init())
    )

    await server.withMethodHandler(ListTools.self) { _ in
        .init(tools: [search, spotlightQuery])
    }

    await server.withMethodHandler(CallTool.self) { params in
    
        switch params.name {
        case spotlightQuery.name:
            return try await handleSpotlightSearch(params: params, spotlight: spotlight)
        case search.name:
            return try await handleSearch(params: params, spotlight: spotlight)
        default:
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }
    }

    return server
}

private func handleSpotlightSearch(params: CallTool.Parameters, spotlight: any Spotlight) async throws -> CallTool.Result {
    do {
        let (query, limit) = try queryAndLimit(params: params)
        return try await pathsResult(query: query, limit: limit, spotlight: spotlight)
    } catch let failure as any ToolFailure {
        return failureResult(failure)
    }
}

private func handleSearch(params: CallTool.Parameters, spotlight: any Spotlight) async throws -> CallTool.Result {
    do {
        let (query, limit) = try searchQueryAndLimit(params: params)
        return try await pathsResult(query: query, limit: limit, spotlight: spotlight)
    } catch let failure as any ToolFailure {
        return failureResult(failure)
    }
}

private func failureResult(_ failure: any ToolFailure) -> CallTool.Result {
    CallTool.Result(content: [.text(text: failure.message, annotations: nil, _meta: nil)], isError: true)
}

private func pathsResult(query: String, limit: Int, spotlight: any Spotlight) async throws -> CallTool.Result {
    let paths: [String]
    do {
        paths = try await spotlight.search(query: query, limit: limit)
    } catch let spotlightError {
        return failureResult(spotlightError)
    }
    let response = paths.asOxusResponse
    let encoder = JSONEncoder()
    encoder.outputFormatting = .withoutEscapingSlashes
    let text = String(decoding: try encoder.encode(response), as: UTF8.self)
    return try CallTool.Result(content: [.text(text: text, annotations: nil, _meta: nil)], structuredContent: response, isError: false)
}

private func queryAndLimit(params: CallTool.Parameters) throws -> (query: String, limit: Int) {
    let query = try Query(from: params.arguments)
    let limit = try Limit(params.arguments?["limit"])
    return (query: query.value, limit: limit.value)
}

private func searchQueryAndLimit(params: CallTool.Parameters) throws -> (query: String, limit: Int) {
    let query = try SearchCriteria(from: params.arguments)
    let limit = try Limit(params.arguments?["limit"])
    return (query: query.spotlightQuery, limit: limit.value)
}

private let spotlightQuery = Tool(
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

private let search = Tool(
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
