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
import MacOSAdapters
import OxusServer
import Testing

@Suite struct AcceptanceTests {
    @Test
    func
        `a client queries kMDItemFSName == "Finder.app" with spotlight_query and receives Finder's path in structured content and in the text block`()
        async throws
    {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

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
        #expect(paths.contains("/System/Library/CoreServices/Finder.app"))
        #expect(result.content.count == 1)
        #expect(mirrored == result.structuredContent)
    }

    @Test func `a client searches for "finde" and receives Finder's path in structured content and in the text block`() async throws {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["name_contains": "finde"]
                ))
        ).value

        let paths = try #require(result.structuredContent?.objectValue?["paths"]?.arrayValue)
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(result.isError != true)
        #expect(paths.contains("/System/Library/CoreServices/Finder.app"))
        #expect(result.content.count == 1)
        #expect(mirrored == result.structuredContent)
    }

    @Test func `a client searches for "finde" with kind application over MCP and receives Finder's path`() async throws {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["name_contains": "finde", "kind": "application"]
                ))
        ).value
        let paths = try #require(result.structuredContent?.objectValue?["paths"]?.arrayValue)

        #expect(result.isError != true)
        #expect(paths.contains("/System/Library/CoreServices/Finder.app"))
    }

    @Test func `a client searches for "finde" with kind folder over MCP and does not receive Finder's path`() async throws {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["name_contains": "finde", "kind": "folder"]
                ))
        ).value
        let paths = try #require(result.structuredContent?.objectValue?["paths"]?.arrayValue)

        #expect(result.isError != true)
        #expect(!paths.contains("/System/Library/CoreServices/Finder.app"))
    }

    @Test func `a client searches for kind application in /System/Applications and receives Calculator's path but not Finder's`()
        async throws
    {

        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: [
                        "folder": "/System/Applications",
                        "kind": "application",
                        "limit": 100,
                    ]
                ))
        ).value
        let paths = try #require(result.structuredContent?.objectValue?["paths"]?.arrayValue)

        #expect(result.isError != true)
        #expect(paths.contains("/System/Applications/Calculator.app"))
        #expect(!paths.contains("/System/Library/CoreServices/Finder.app"))

    }

    @Test func `a client searches /System/Applications/Utilities with only a folder and receives Terminal's path`()
        async throws
    {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["folder": "/System/Applications/Utilities"]
                ))
        ).value
        let paths = try #require(result.structuredContent?.objectValue?["paths"]?.arrayValue)

        #expect(result.isError != true)
        #expect(paths.contains("/System/Applications/Utilities/Terminal.app"))

    }

    @Test func `a client searches a folder that does not exist and receives an error result saying the path does not exist`()
        async throws
    {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["folder": "/nonexistent-oxus-folder"]
                ))
        ).value
        let text = try #require(texts(in: result.content).first)

        #expect(result.isError == true)
        #expect(text.contains("/nonexistent-oxus-folder"))
        #expect(text.contains("does not exist"))

    }

    @Test func `a client searches /System/Applications/Calculator.app and receives an error result saying it is a package`() async throws {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["folder": "/System/Applications/Calculator.app"]
                ))
        ).value
        let text = try #require(texts(in: result.content).first)

        #expect(result.isError == true)
        #expect(text.contains("/System/Applications/Calculator.app"))
        #expect(text.contains("is a package"))
    }

    @Test func `a client searches a chmod 000 folder and receives an error result naming the path and saying it lacks read permission`()
        async throws
    {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: folder.path())
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["folder": .string(folder.path())]
                ))
        ).value
        let text = try #require(texts(in: result.content).first)

        #expect(result.isError == true)
        #expect(text.contains(folder.path()))
        #expect(text.contains("lacks read permission"))
    }

    @Test
    func
        `a client searches ~ in a temporary home whose Downloads, Documents and Desktop are readable and receives a result without unreadableFolders`()
        async throws
    {
        let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        for protectedFolder in ["Downloads", "Documents", "Desktop"] {
            try FileManager.default.createDirectory(at: home.appending(path: protectedFolder), withIntermediateDirectories: true)
        }
        let client = try await connectedClient(spotlight: CoreServicesSpotlight(), home: home.path(percentEncoded: false))

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["folder": "~"]
                ))
        ).value
        let structuredContent = try #require(result.structuredContent?.objectValue)

        #expect(result.isError != true)
        #expect(structuredContent["paths"] != nil)
        #expect(structuredContent["unreadableFolders"] == nil)
    }

    @Test
    func
        `a client runs spotlight_query for Finder.app with a temporary home whose protected folders are readable and receives Finder's path without unreadableFolders`()
        async throws
    {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "spotlight_query",
                    arguments: ["query": #"kMDItemFSName == "Finder.app""#]
                ))
        ).value
        let structuredContent = try #require(result.structuredContent?.objectValue)

        #expect(result.isError != true)
        #expect(structuredContent["paths"]?.arrayValue?.contains("/System/Library/CoreServices/Finder.app") == true)
        #expect(structuredContent["unreadableFolders"] == nil)
    }

    @Test
    func
        `a client searches for "finde" without a folder, with a temporary home whose protected folders are readable, and receives Finder's path without unreadableFolders`()
        async throws
    {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["name_contains": "finde"]
                ))
        ).value
        let structuredContent = try #require(result.structuredContent?.objectValue)

        #expect(result.isError != true)
        #expect(structuredContent["paths"]?.arrayValue?.contains("/System/Library/CoreServices/Finder.app") == true)
        #expect(structuredContent["unreadableFolders"] == nil)
    }

    @Test
    func
        `a client sends more concurrent spotlight_query calls for Finder.app than the Mac has CPUs and every call receives Finder's path`()
        async throws
    {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())
        let callCount = ProcessInfo.processInfo.activeProcessorCount + 1

        let results = try await withThrowingTaskGroup(of: CallTool.Result.self) { group in
            for _ in 0..<callCount {
                group.addTask {
                    try await client.send(
                        CallTool.request(
                            .init(
                                name: "spotlight_query",
                                arguments: ["query": #"kMDItemFSName == "Finder.app""#]
                            ))
                    ).value
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(results.count == callCount)
        for result in results {
            let paths = result.structuredContent?.objectValue?["paths"]?.arrayValue
            #expect(result.isError != true)
            #expect(paths?.contains("/System/Library/CoreServices/Finder.app") == true)
        }
    }

    @Test func `a client runs spotlight_query matching more system files than a limit of 1 and receives one path and truncated true`()
        async throws
    {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "spotlight_query",
                    arguments: ["query": #"kMDItemFSName == "*.app"c"#, "limit": 1]
                ))
        ).value

        let content = try #require(result.structuredContent?.objectValue)
        let paths = try #require(content["paths"]?.arrayValue)

        #expect(result.isError != true)
        #expect(paths.count == 1)
        #expect(content["truncated"] == true)
    }

    @Test func `a client searches for "finde" with a limit above its matches and receives the paths without a truncated key`() async throws
    {
        let client = try await connectedClient(spotlight: CoreServicesSpotlight())

        let result = try await client.send(
            CallTool.request(
                .init(
                    name: "search",
                    arguments: ["name_contains": "finde", "folder": "/System/Library/CoreServices", "limit": 100]
                ))
        ).value

        let content = try #require(result.structuredContent?.objectValue)
        let paths = try #require(content["paths"]?.arrayValue)

        #expect(result.isError != true)
        #expect(paths.contains("/System/Library/CoreServices/Finder.app"))
        #expect(content["truncated"] == nil)
    }

    // Unscoped calls probe the home's protected folders; the real home would make runs prompt and depend on its privacy settings.
    private static let home: String = {
        let home = FileManager.default.temporaryDirectory.appending(path: "oxus-acceptance-home")
        for protectedFolder in ["Downloads", "Documents", "Desktop"] {
            try! FileManager.default.createDirectory(at: home.appending(path: protectedFolder), withIntermediateDirectories: true)
        }
        return home.path(percentEncoded: false)
    }()

    private func connectedClient(spotlight: any Spotlight, home: String = Self.home) async throws -> Client {
        let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()
        let server = try await makeOxusServer(
            spotlight: spotlight, fileSystem: LocalFileSystem(), home: Folder(absolutePath: home))
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
