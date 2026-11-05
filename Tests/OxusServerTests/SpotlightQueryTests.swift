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

@Suite struct SpotlightQueryTests {
    @Test func `the server advertises spotlight_query`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        #expect(tools.map(\.name).contains("spotlight_query"))
    }

    @Test func `spotlight_query advertises a required query and an optional limit between 1 and 100`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()
        let schema = try #require(toolWithName(tools: tools, name: "spotlight_query")?.inputSchema.objectValue)
        let properties = try #require(schema["properties"]?.objectValue)
        let limit = try #require(properties["limit"]?.objectValue)

        #expect(schema["required"] == ["query"])
        #expect(properties["query"]?.objectValue?["type"] == "string")
        #expect(limit["type"] == "integer")
        #expect(limit["maximum"] == 100)
        #expect(limit["minimum"] == 1)
    }

    @Test func `spotlight_query advertises an output schema with a required array of string paths`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()
        let schema = try #require(toolWithName(tools: tools, name: "spotlight_query")?.outputSchema?.objectValue)

        let paths = try #require(schema["properties"]?.objectValue?["paths"]?.objectValue)
        #expect(paths["type"] == "array")
        #expect(paths["items"]?.objectValue?["type"] == "string")
        #expect(schema["required"] == ["paths"])
    }

    @Test func `Spotlight is asked for 25 results when no limit is given`() async throws {

        let paths: [String] = .init(repeating: "a", count: 100)
        let client = try await connectedClient(spotlight: SpySpotlight(result: paths))

        let result = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test"]))).value

        #expect(result.structuredContent?.objectValue?["paths"]?.arrayValue?.count == 25)
    }

    @Test func `Spotlight is asked for 100 results when the limit exceeds 100`() async throws {

        let paths: [String] = .init(repeating: "a", count: 200)
        let client = try await connectedClient(spotlight: SpySpotlight(result: paths))

        let result = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test", "limit": 300])))
            .value

        #expect(result.structuredContent?.objectValue?["paths"]?.arrayValue?.count == 100)
    }

    @Test(arguments: [0, -5])
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

    @Test func `A query matching no files returns empty paths in structured content and text, without error`() async throws {
        let client = try await connectedClient()

        let result = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test"]))).value
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(result.isError != true)
        #expect(result.structuredContent == ["paths": []])
        #expect(mirrored == result.structuredContent)
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

    @Test func `spotlight_query returns the paths Spotlight finds as structured content, in Spotlight's order`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight(result: ["/path1", "/path2"]))

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "spotlight_query",
                    arguments: ["query": #"kMDItemFSName == "Finder.app""#]
                ))
        ).value

        let paths = try #require(result.structuredContent?.objectValue?["paths"]?.arrayValue)
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(result.isError != true)
        #expect(paths == ["/path1", "/path2"])
        #expect(result.content.count == 1)
        #expect(mirrored == result.structuredContent)
    }

    @Test func `Paths containing quotes, backslashes or newlines decode from the text block unchanged`() async throws {
        let paths = [#"/a "quoted" name"#, #"/a\back\slash"#, "/a\nnew\nline"]
        let client = try await connectedClient(spotlight: SpySpotlight(result: paths))

        let result = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test"]))).value
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(mirrored == ["paths": .array(paths.map { .string($0) })])
    }

    @Test func `An error result carries no structured content`() async throws {
        let client = try await connectedClient(spotlight: MalformedQuerySpotlight())

        let result = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "kMDItemFSName =="]))).value

        #expect(result.isError == true)
        #expect(result.structuredContent == nil)
    }

    @Test func `spotlight_query asks Spotlight to search the whole index`() async throws {
        let spy = SpySpotlight()
        let client = try await connectedClient(spotlight: spy)

        _ = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test", "folder": "/test"]))).value

        #expect(spy.receivedQuery?.text == "test")
        #expect(spy.receivedFolder == nil)
    }

    @Test
    func
        `spotlight_query with ~/Desktop denied by privacy protection returns the paths Spotlight finds and one unreadableFolders entry with the Desktop path and the Files and Folders › Desktop fix`()
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Desktop": .deniedByPrivacyProtection(path: "/Users/test/Desktop")
        ])
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a"]), fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test"]))).value

        #expect(result.isError != true)
        #expect(
            result.structuredContent == [
                "paths": ["/Users/test/a"],
                "unreadableFolders": [
                    [
                        "path": "/Users/test/Desktop",
                        "fix":
                            "Allow access in System Settings › Privacy & Security › Files and Folders › Desktop, for oxus if it is listed there, otherwise the app that launched oxus",
                    ]
                ],
            ])
    }

    @Test func `spotlight_query with all three protected folders readable returns no unreadableFolders key`() async throws {
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a"]), fileSystem: ScriptedFileSystem(), home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test"]))).value

        #expect(result.isError != true)
        #expect(result.structuredContent == ["paths": ["/Users/test/a"]])
    }

    @Test func `spotlight_query returns a single text block that decodes to its structured content, including unreadableFolders`()
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads")
        ])
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a"]), fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test"]))).value
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(result.content.count == 1)
        #expect(result.structuredContent?.objectValue?["unreadableFolders"] != nil)
        #expect(mirrored == result.structuredContent)
    }

    @Test func `spotlight_query whose matches exceed limit returns limit paths and truncated true`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight(result: ["/a", "/b"]))

        let result = try await client.send(
            CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test", "limit": 1]))
        ).value

        let content = try #require(result.structuredContent?.objectValue)

        #expect(content["paths"] == ["/a"])
        #expect(content["truncated"] == true)
    }

    @Test func `spotlight_query whose matches equal limit returns them all and no truncated key`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight(result: ["/a", "/b"]))

        let result = try await client.send(
            CallTool.request(.init(name: "spotlight_query", arguments: ["query": "test", "limit": 2]))
        ).value

        let content = try #require(result.structuredContent?.objectValue)

        #expect(content["paths"] == ["/a", "/b"])
        #expect(content["truncated"] == nil)
    }
}
