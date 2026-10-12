import MCP

public func makeOxusServer() async -> Server {
    let server = Server(
        name: "oxus",
        version: "0.1.0",
        capabilities: .init(tools: .init())
    )

    await server.withMethodHandler(ListTools.self) { _ in
        .init(tools: [hello])
    }

    await server.withMethodHandler(CallTool.self) { params in
        guard params.name == hello.name else {
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }
        let name = params.arguments?["name"]?.stringValue ?? "world"
        return .init(content: [.text(text: "Hello, \(name)!", annotations: nil, _meta: nil)], isError: false)
    }

    return server
}

private let hello = Tool(
    name: "hello",
    description: "Greets someone by name, or the world when no name is given.",
    inputSchema: .object([
        "type": "object",
        "properties": .object([
            "name": .object([
                "type": "string",
                "description": "Who to greet",
            ]),
        ]),
    ])
)
