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

@Suite struct SearchTests {
    @Test func `The server advertises search alongside spotlight_query`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        #expect(Set(tools.map(\.name)) == Set(["search", "spotlight_query"]))
    }
    
    @Test func `search advertises a required name_contains and an optional limit between 1 and 100`() async throws {
        let client = try await connectedClient()
        
        let (tools, _) = try await client.listTools()
        
        let search = try #require(tools.first(where: { $0.name == "search" }))
        let schema = try #require(search.inputSchema.objectValue)
        let properties = try #require(schema["properties"]?.objectValue)
        let limit = try #require(properties["limit"]?.objectValue)

        #expect(schema["required"] == ["name_contains"])
        #expect(properties["name_contains"]?.objectValue?["type"] == "string")
        #expect(limit["type"] == "integer")
        #expect(limit["minimum"] == 1)
        #expect(limit["maximum"] == 100)
    }
}
