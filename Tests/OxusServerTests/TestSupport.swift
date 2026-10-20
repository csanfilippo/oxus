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
import OxusServer

final class MalformedQuerySpotlight: Sendable, Spotlight {
    func search(query: String, limit: Int) async throws(SpotlightError) -> [String] {
        throw SpotlightError.malformedQuery(query: query)
    }
}

final class FailingExecutionSpotlight: Sendable, Spotlight {
    func search(query: String, limit: Int) async throws(SpotlightError) -> [String] {
        throw SpotlightError.executionFailed(query: query)
    }
}

final class SpySpotlight: Spotlight, @unchecked Sendable {
    private(set) var receivedQuery: String?
    private(set) var receivedLimit: Int?

    private let result: [String]
    init(result: [String] = []) { self.result = result }
    func search(query: String, limit: Int) async throws(SpotlightError) -> [String] {
        receivedQuery = query
        receivedLimit = limit
        return Array(result.prefix(limit))
    }
}

func connectedClient(spotlight: any Spotlight = SpySpotlight()) async throws -> Client {
    let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()
    let server = await makeOxusServer(spotlight: spotlight)
    try await server.start(transport: serverTransport)
    let client = Client(name: "oxus-tests", version: "0")
    try await client.connect(transport: clientTransport)
    return client
}

func texts(in content: [Tool.Content]) -> [String] {
    content.compactMap {
        if case .text(let text, _, _) = $0 { text } else { nil }
    }
}

func toolWithName(tools: [Tool], name: String) -> Tool? {
    tools.first { $0.name == name }
}
