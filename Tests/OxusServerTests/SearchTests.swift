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

import Foundation
import MCP
import OxusServer
import Testing

@Suite struct SearchTests {
    @Test func `The server advertises search alongside spotlight_query`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        #expect(Set(tools.map(\.name)) == Set(["search", "spotlight_query"]))
    }

    @Test func `search advertises a string name_contains and an optional limit between 1 and 100`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        let search = try #require(toolWithName(tools: tools, name: "search"))
        let schema = try #require(search.inputSchema.objectValue)
        let properties = try #require(schema["properties"]?.objectValue)
        let limit = try #require(properties["limit"]?.objectValue)

        #expect(properties["name_contains"]?.objectValue?["type"] == "string")
        #expect(limit["type"] == "integer")
        #expect(limit["minimum"] == 1)
        #expect(limit["maximum"] == 100)
    }

    @Test func `search advertises the same output schema as spotlight_query`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        let search = try #require(toolWithName(tools: tools, name: "search"))
        let spotlightQuery = try #require(toolWithName(tools: tools, name: "spotlight_query"))
        let searchSchema = try #require(search.outputSchema?.objectValue)
        let spotlightQuerySchema = try #require(spotlightQuery.outputSchema?.objectValue)

        #expect(searchSchema == spotlightQuerySchema)
    }

    @Test func `search advertises an optional kind listing the six kinds, and name_contains is no longer required`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        let search = try #require(toolWithName(tools: tools, name: "search"))
        let schema = try #require(search.inputSchema.objectValue)
        let properties = try #require(schema["properties"]?.objectValue)
        let kind = try #require(properties["kind"]?.objectValue)
        let required = schema["required"]?.arrayValue ?? []

        #expect(kind["type"] == "string")
        #expect(kind["enum"] == ["image", "movie", "audio", "pdf", "folder", "application"])
        #expect(!required.contains("kind"))
        #expect(!required.contains("name_contains"))
    }

    @Test func `search returns the paths Spotlight finds for the compiled name query`() async throws {
        let spy = SpySpotlight(result: ["/a", "/b"])
        let client = try await connectedClient(spotlight: spy)

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["name_contains": "test"]))).value

        #expect(spy.receivedQuery == #"kMDItemDisplayName == "*test*"cd"#)
        #expect(result.structuredContent == ["paths": ["/a", "/b"]])
    }

    @Test func `A search with neither name_contains nor kind is rejected as an error result`() async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: [:])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("at least one of name_contains or kind is required") == true)
    }

    @Test(arguments: ["", "   "])
    func `A blank name_contains is rejected as an error result`(name: String) async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: ["name_contains": .string(name)])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("name_contains cannot be empty") == true)
    }

    @Test func `A name_contains that is not a string is rejected as an error result`() async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: ["name_contains": 42])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("name_contains must be a string") == true)
    }

    @Test func `search asks Spotlight for 25 results when no limit is given`() async throws {
        let spy = SpySpotlight(result: ["/a", "/b"])
        let client = try await connectedClient(spotlight: spy)

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["name_contains": "test"]))).value

        #expect(spy.receivedLimit == 25)
        #expect(result.structuredContent == ["paths": ["/a", "/b"]])
    }

    @Test func `search with only a kind returns the paths Spotlight finds for the compiled kind query`() async throws {
        let spy = SpySpotlight(result: ["/a", "/b"])
        let client = try await connectedClient(spotlight: spy)

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["kind": "image"]))).value

        #expect(spy.receivedLimit == 25)
        #expect(spy.receivedQuery == #"kMDItemContentTypeTree == "public.image""#)
        #expect(result.structuredContent == ["paths": ["/a", "/b"]])
    }

    @Test func `An unknown kind is rejected as an error result that lists the accepted kinds`() async throws {

        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: ["kind": "unknown"])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("accepted kinds are: image,movie,audio,pdf,folder,application") == true)
    }

    @Test func `A kind that is not a string is rejected as an error result`() async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: ["kind": 42])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("kind must be a string") == true)
        #expect(texts(in: content).first?.contains("accepted kinds are: image,movie,audio,pdf,folder,application") == true)
    }

    @Test(arguments: ["", "   "])
    func `A blank name_contains is rejected as an error result even when a kind is given`(name: String) async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: ["name_contains": .string(name), "kind": "image"])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("name_contains cannot be empty") == true)
    }

    @Test func `search returns a single text block that decodes to its structured content`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight(result: ["/a", "/b"]))

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["name_contains": "test"]))).value
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(result.content.count == 1)
        #expect(mirrored == result.structuredContent)
    }

    @Test func `A search error result carries no structured content`() async throws {
        let client = try await connectedClient()

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: [:]))).value

        #expect(result.isError == true)
        #expect(result.structuredContent == nil)
    }
}
