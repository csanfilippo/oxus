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

private let minimumLimit = 1
private let defaultLimit = 25
private let maximumLimit = 100

public func makeOxusServer(spotlight: any Spotlight) async -> Server {
    let server = Server(
        name: "oxus",
        version: "0.1.0",
        capabilities: .init(tools: .init())
    )

    await server.withMethodHandler(ListTools.self) { _ in
        .init(tools: [spotlightQuery])
    }

    await server.withMethodHandler(CallTool.self) { params in
        guard params.name == spotlightQuery.name else {
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }
        
        let query = params.arguments?["query"]?.stringValue ?? ""
        let requestedLimit = params.arguments?["limit"]?.intValue ?? defaultLimit
        
        guard requestedLimit >= minimumLimit else {
            
            let errorMessage = "limit must be at least \(minimumLimit), got \(requestedLimit)"
            
            return CallTool.Result(content: [.text(text: errorMessage, annotations: nil, _meta: nil)], isError: true)
        }
        
        let paths = try await spotlight.search(query: query, limit: min(requestedLimit, maximumLimit))
        
        return CallTool.Result(content: paths.map { path in .text(text: path, annotations: nil, _meta: nil) }, isError: false)
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
                "maximum": .int(maximumLimit),
                "minimum": .int(minimumLimit),
                "description": "The maximum number of paths to return",
            ]),
        ]),
        "required": ["query"],
    ])
)
