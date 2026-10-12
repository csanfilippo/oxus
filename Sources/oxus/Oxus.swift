import MCP
import OxusServer

@main
struct Oxus {
    static func main() async throws {
        let server = await makeOxusServer()
        try await server.start(transport: StdioTransport())
        await server.waitUntilCompleted()
    }
}
