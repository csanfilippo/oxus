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
        guard params.name == spotlightQuery.name else {
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }
        
        do {
            let query = try Query(params.arguments?["query"])
            let limit = try Limit(params.arguments?["limit"])
            
            let paths = try await spotlight.search(query: query.value, limit: limit.value)
            
            return CallTool.Result(content: paths.map { path in .text(text: path, annotations: nil, _meta: nil) }, isError: false)
        } catch let limitError as Limit.Error {
            return CallTool.Result(content: [.text(text: limitError.message, annotations: nil, _meta: nil)], isError: true)
        } catch let queryError as Query.Error {
            return CallTool.Result(content: [.text(text: queryError.message, annotations: nil, _meta: nil)], isError: true)
        } catch let spotlightError as SpotlightError {
            return CallTool.Result(content: [.text(text: spotlightError.message, annotations: nil, _meta: nil)], isError: true)
        }
    }

    return server
}

private let spotlightQuery = Tool(
    name: "spotlight_query",
    description: "Perform raw Spotlight queries",
    inputSchema: .object([
        "type": "object",
        "properties": .object([
            "query": .object([
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
        "required": ["query"],
    ])
)

private let search = Tool(
    name: "search",
    description: "Finds files whose name contains the given text, without Spotlight query syntax. Matching ignores case and diacritics. Returns at most \(Limit.maximum) paths.",
    inputSchema: .object([
        "type": "object",
        "properties": .object([
            "name_contains": .object([
                "type": "string",
                "description": "Text the file's name must contain",
            ]),
            "limit": .object([
                "type": "integer",
                "maximum": .int(Limit.maximum),
                "minimum": .int(Limit.minimum),
                "description": "The maximum number of paths to return",
            ]),
        ]),
        "required": ["name_contains"],
    ])
)
