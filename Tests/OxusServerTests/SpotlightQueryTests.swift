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
import Testing
import OxusServer

@Suite struct SpotlightQueryTests {
    @Test func `the server advertises spotlight_query`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        #expect(tools.map(\.name).contains("spotlight_query"))
    }
    
    @Test func `spotlight_query advertises a required query and an optional limit between 1 and 100`() async throws {
        let client = try await connectedClient()
        
        let (tools, _) = try await client.listTools()
        let schema = try #require(tools.first(where: { tool in
            tool.name == "spotlight_query"
        })?.inputSchema.objectValue)
        let properties = try #require(schema["properties"]?.objectValue)
        let limit = try #require(properties["limit"]?.objectValue)
        
        #expect(schema["required"] == ["query"])
        #expect(properties["query"]?.objectValue?["type"] == "string")
        #expect(limit["type"] == "integer")
        #expect(limit["maximum"] == 100)
        #expect(limit["minimum"] == 1)
    }
    
    @Test func `query returns one text block per matching path, in Spotlight's order`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight(result: ["/b","/a"]))
        
        let (content, _) = try await client.callTool(name: "spotlight_query", arguments: ["query": "test"])
        
        #expect(texts(in: content) == ["/b","/a"])
    }
    
    @Test func `Spotlight is asked for 25 results when no limit is given`() async throws {
        
        let paths: [String] = .init(repeating: "a", count: 100)
        let client = try await connectedClient(spotlight: SpySpotlight(result: paths))
        
        let (content, _) = try await client.callTool(name: "spotlight_query", arguments: ["query": "test"])
        
        #expect(texts(in: content).count == 25)
    }
    
    @Test func `Spotlight is asked for 100 results when the limit exceeds 100`() async throws {
        
        let paths: [String] = .init(repeating: "a", count: 200)
        let client = try await connectedClient(spotlight: SpySpotlight(result: paths))
        
        let (content, _) = try await client.callTool(name: "spotlight_query", arguments: ["query": "test", "limit": 300])
        
        #expect(texts(in: content).count == 100)
    }
    
    @Test(arguments: [0,-5])
    func `A limit below 1 is rejected as an error result`(limit: Int) async throws {
        
        let client = try await connectedClient()
        
        let (content, isError) = try await client.callTool(name: "spotlight_query", arguments: ["query": "test", "limit": .int(limit)])
        
        #expect(isError == true)
        
        #expect(texts(in: content).first?.contains("got \(limit)") == true)
    }
    
    @Test func `A limit that is not an integer is rejected as an error result`() async throws {
        let client = try await connectedClient()
        
        let (content, isError) = try await client.callTool(name: "spotlight_query", arguments: ["query": "test", "limit": "test"])
        
        #expect(isError == true)
        
        #expect(texts(in: content).first?.contains("must be an integer") == true)
        
    }
    
    @Test(arguments: ["", "    "])
    func `A blank query is rejected as an error result`(query: String) async throws {
        let client = try await connectedClient()
          
        let (content, isError) = try await client.callTool(name: "spotlight_query", arguments: ["query": .string(query)])
        
        #expect(isError == true)
        
        #expect(texts(in: content).first?.contains("query cannot be empty") == true)
    }

    @Test func `A missing query is rejected as an error result`() async throws {
        let client = try await connectedClient()
        let (content, isError) = try await client.callTool(name: "spotlight_query", arguments: [:])
        
        #expect(isError == true)
        
        #expect(texts(in: content).first?.contains("query is missing") == true)
    }
    
    @Test func `A query that is not a string is rejected as an error result`() async throws {
        let client = try await connectedClient()
        let (content, isError) = try await client.callTool(name: "spotlight_query", arguments: ["query": 42])
        
        #expect(isError == true)
        
        #expect(texts(in: content).first?.contains("query must be a string") == true)
    }
    
    @Test func `An unknown tool is rejected as a protocol error`() async throws {
        let client = try await connectedClient()
        
        let error = try await #require(throws: MCPError.self) {
            try await client.callTool(name: "nonexistent")
        }
        guard case .invalidParams = error else {
            Issue.record("expected invalidParams, got \(error)")
            return
        }
    }
    
    @Test func `A query matching no files returns empty content without error`() async throws {
        let client = try await connectedClient()
        
        let (content, isError) = try await client.callTool(name: "spotlight_query", arguments: ["query": "test"])
        
        #expect(isError != true)
        
        #expect(content.isEmpty)
    }
    
    @Test func `A malformed query is rejected as an error result naming the query`() async throws {
        let client = try await connectedClient(spotlight: MalformedQuerySpotlight())
        
        let (content, isError) = try await client.callTool(name: "spotlight_query", arguments: ["query": "kMDItemFSName =="])
        
        #expect(isError == true)
        
        #expect(texts(in: content).first?.contains("malformed Spotlight query: 'kMDItemFSName =='") == true)
    }

    @Test func `A query Spotlight cannot run is rejected as an error result naming the query`() async throws {
        let client = try await connectedClient(spotlight: FailingExecutionSpotlight())

        let (content, isError) = try await client.callTool(name: "spotlight_query", arguments: ["query": #"kMDItemFSName == "Finder.app""#])

        #expect(isError == true)

        #expect(texts(in: content).first?.contains(#"Spotlight could not run the query 'kMDItemFSName == "Finder.app"'"#) == true)
    }
}
