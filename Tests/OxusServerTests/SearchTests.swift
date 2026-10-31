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

    @Test func `search advertises an optional string folder`() async throws {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()

        let search = try #require(toolWithName(tools: tools, name: "search"))
        let schema = try #require(search.inputSchema.objectValue)
        let properties = try #require(schema["properties"]?.objectValue)
        let required = schema["required"]?.arrayValue ?? []
        let folder = try #require(properties["folder"]?.objectValue)

        #expect(folder["type"] == "string")
        #expect(!required.contains("folder"))
    }

    @Test func `search returns the paths Spotlight finds for the compiled name query`() async throws {
        let spy = SpySpotlight(result: ["/a", "/b"])
        let client = try await connectedClient(spotlight: spy)

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["name_contains": "test"]))).value

        #expect(spy.receivedQuery?.text == #"kMDItemDisplayName == "*test*"cd"#)
        #expect(result.structuredContent == ["paths": ["/a", "/b"]])
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

        #expect(spy.receivedLimit?.value == 25)
        #expect(result.structuredContent == ["paths": ["/a", "/b"]])
    }

    @Test func `search with only a kind returns the paths Spotlight finds for the compiled kind query`() async throws {
        let spy = SpySpotlight(result: ["/a", "/b"])
        let client = try await connectedClient(spotlight: spy)

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["kind": "image"]))).value

        #expect(spy.receivedLimit?.value == 25)
        #expect(spy.receivedQuery?.text == #"kMDItemContentTypeTree == "public.image""#)
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

    @Test func `search with a name, a kind and a folder asks Spotlight for the compiled name and kind query within that folder`()
        async throws
    {
        let spy = SpySpotlight(result: ["/a", "/b"])
        let client = try await connectedClient(spotlight: spy)

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: [
                        "name_contains": "test",
                        "kind": "image",
                        "folder": "/test",
                    ]
                )
            )
        ).value

        #expect(spy.receivedQuery?.text == #"kMDItemDisplayName == "*test*"cd && kMDItemContentTypeTree == "public.image""#)
        #expect(spy.receivedFolder?.path == "/test")
        #expect(result.structuredContent == ["paths": ["/a", "/b"]])
    }

    @Test func `search without a folder asks Spotlight to search the whole index`() async throws {
        let spy = SpySpotlight()
        let client = try await connectedClient(spotlight: spy)

        _ = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: [
                        "name_contains": "test",
                        "kind": "image",
                    ]
                )
            )
        ).value

        #expect(spy.receivedFolder == nil)
    }

    @Test(arguments: [("~", "/Users/test"), ("~/Downloads", "/Users/test/Downloads")])
    func `~ alone and paths starting with ~/ are searched inside the given home folder`(folder: String, expected: String) async throws {
        let spy = SpySpotlight()
        let client = try await connectedClient(spotlight: spy, home: "/Users/test")

        _ = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: [
                        "kind": "image",
                        "folder": .string(folder),
                    ]
                )
            )
        ).value

        #expect(spy.receivedFolder?.path == expected)
    }

    @Test func `search with only a folder asks Spotlight for every file in that folder`() async throws {
        let spy = SpySpotlight()
        let client = try await connectedClient(spotlight: spy)

        _ = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: [
                        "folder": "/test"
                    ]
                )
            )
        ).value

        #expect(spy.receivedQuery?.text == #"kMDItemDisplayName == "*""#)
        #expect(spy.receivedFolder?.path == "/test")
    }

    @Test func `A search with neither name_contains, kind nor folder is rejected as an error result naming all three`() async throws {

        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: [:])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("at least one of name_contains or kind or folder is required") == true)
    }

    @Test(arguments: ["Downloads", "~alice/Downloads"])
    func `A relative folder or a ~name folder is rejected as an error result listing the accepted forms`(folder: String) async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": .string(folder)])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("folder must be an absolute path, ~ alone, or a path starting with ~/") == true)
    }

    @Test func `A folder that is not a string is rejected as an error result`() async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": 42])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("folder must be a string") == true)
    }

    @Test(arguments: ["", "   "])
    func `A blank folder is rejected as an error result`(folder: String) async throws {
        let client = try await connectedClient()

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": .string(folder)])

        #expect(isError == true)
        #expect(texts(in: content).first?.contains("folder cannot be empty") == true)
    }

    @Test
    func
        `A folder the file system reports as not found returns an error result naming the path, saying it does not exist, and asking to correct the path`()
        async throws
    {
        let client = try await connectedClient(fileSystem: FolderNotFoundFileSystem())

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": "/Users/test/Dowloads"])
        let text = try #require(texts(in: content).first)

        #expect(isError == true)
        #expect(text.contains("/Users/test/Dowloads"))
        #expect(text.contains("does not exist"))
        #expect(text.contains("correct the path"))
    }

    @Test
    func
        `A folder the file system reports as not a folder returns an error result naming the path, saying it is a file, and suggesting its parent folder`()
        async throws
    {
        let client = try await connectedClient(fileSystem: NotAFolderFileSystem())

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": "/Users/test/report.pdf"])
        let text = try #require(texts(in: content).first)

        #expect(isError == true)
        #expect(text.contains("/Users/test/report.pdf"))
        #expect(text.contains("is a file"))
        #expect(text.contains("parent folder"))
    }

    @Test
    func
        `A folder the file system reports as a package returns an error result naming the path, saying it is a package, and suggesting to search elsewhere`()
        async throws
    {
        let client = try await connectedClient(fileSystem: PackageFileSystem())

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": "/System/Applications/Calculator.app"])
        let text = try #require(texts(in: content).first)

        #expect(isError == true)
        #expect(text.contains("/System/Applications/Calculator.app"))
        #expect(text.contains("is a package"))
        #expect(text.contains("Search elsewhere"))
    }

    @Test func `A folder the file system reports as unreadable returns an error result naming the path and the reason macOS gives`()
        async throws
    {
        let client = try await connectedClient(fileSystem: UnreadableFolderFileSystem(reason: "Permission denied"))

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": "/Users/test/Private"])
        let text = try #require(texts(in: content).first)

        #expect(isError == true)
        #expect(text.contains("/Users/test/Private"))
        #expect(text.contains("is not readable"))
        #expect(text.contains("Permission denied"))
    }
}
