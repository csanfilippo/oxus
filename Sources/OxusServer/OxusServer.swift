import MCP

public func makeOxusServer() async -> Server {
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
        let name = params.arguments?["name"]?.stringValue ?? "world"
        return .init(content: [.text(text: "Hello, \(name)!", annotations: nil, _meta: nil)], isError: false)
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
                "maximum": 100,
                "description": "The maximum number of paths to return",
            ]),
        ]),
        "required": ["query"],
    ])
)
