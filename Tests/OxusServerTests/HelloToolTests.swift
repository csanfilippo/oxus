import MCP
import OxusServer
import Testing

struct HelloToolTests {
    @Test func advertisesHelloTool() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        #expect(tools.map(\.name) == ["hello"])
    }

    @Test func greetsByName() async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "hello", arguments: ["name": "Ada"])

        #expect(isError != true)
        #expect(texts(in: content) == ["Hello, Ada!"])
    }

    @Test func greetsTheWorldWhenNoNameIsGiven() async throws {
        let client = try await connectedClient()

        let (content, _) = try await client.callTool(name: "hello")

        #expect(texts(in: content) == ["Hello, world!"])
    }

    @Test func rejectsUnknownTool() async throws {
        let client = try await connectedClient()

        await #expect(throws: MCPError.self) {
            _ = try await client.callTool(name: "goodbye") as (content: [Tool.Content], isError: Bool?)
        }
    }
}

private func connectedClient() async throws -> Client {
    let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()
    let server = await makeOxusServer()
    try await server.start(transport: serverTransport)
    let client = Client(name: "oxus-tests", version: "0")
    try await client.connect(transport: clientTransport)
    return client
}

private func texts(in content: [Tool.Content]) -> [String] {
    content.compactMap {
        if case .text(let text, _, _) = $0 { text } else { nil }
    }
}
