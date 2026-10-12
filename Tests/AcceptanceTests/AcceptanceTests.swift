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

import Testing
import MCP
import OxusServer
import CoreServicesAdapter

@Suite struct AcceptanceTests {
    @Test func `a client queries kMDItemFSName == "Finder.app" over MCP and receives Finder's path`() async throws {
        
        await withKnownIssue {
            let client = try await connectedClient(spotlight: CoreServicesSpotlight())
            
            let (content, isError) = try await client.callTool(
                name: "spotlight_query",
                arguments: ["query": #"kMDItemFSName == "Finder.app""#]
            )
            
            #expect(isError != true)
            #expect(texts(in: content).contains("/System/Library/CoreServices/Finder.app"))
        }
    }
    
    private func connectedClient(spotlight: CoreServicesSpotlight) async throws -> Client {
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
}
