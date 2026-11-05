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
import Testing

@Suite struct UnscopedProtectedFoldersTests {
    @Test(
        arguments: [
            FolderError.notFound(path: "/Users/test/Downloads"),
            FolderError.deniedByFilePermissions(path: "/Users/test/Downloads"),
            FolderError.unreadable(path: "/Users/test/Downloads", reason: "Input/output error"),
        ],
        UnscopedCall.allCases
    )
    func
        `For spotlight_query and an unscoped search, a protected folder that is missing, lacks read permission or fails with another reason adds no entry`(
            failure: FolderError, call: UnscopedCall
        )
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: ["/Users/test/Downloads": failure])
        let client = try await connectedClient(fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(call.request)).value

        #expect(result.isError != true)
        #expect(result.structuredContent == ["paths": []])
    }

    @Test(arguments: UnscopedCall.allCases)
    func `spotlight_query and an unscoped search probe the protected folders before Spotlight runs the query`(call: UnscopedCall)
        async throws
    {
        let fileSystem = ScriptedFileSystem()
        let spotlight = CheckedPathsRecordingSpotlight(fileSystem: fileSystem)
        let client = try await connectedClient(spotlight: spotlight, fileSystem: fileSystem, home: "/Users/test")

        _ = try await client.send(CallTool.request(call.request)).value

        #expect(spotlight.checkedPathsWhenSearched == ["/Users/test/Downloads", "/Users/test/Documents", "/Users/test/Desktop"])
    }

    @Test(arguments: UnscopedCall.allCases)
    func `A spotlight_query or search with a rejected argument returns its error and probes no protected folder`(call: UnscopedCall)
        async throws
    {
        let fileSystem = ScriptedFileSystem()
        let client = try await connectedClient(fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(call.rejectedRequest)).value

        #expect(result.isError == true)
        #expect(fileSystem.checkedPaths.isEmpty)
    }

    @Test func `A result that is cut off with a protected folder denied carries both truncated and unreadableFolders`() async throws {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads")
        ])
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a", "/Users/test/b"]), fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(
            CallTool.request(.init(name: "search", arguments: ["name_contains": "test", "limit": 1]))
        ).value

        let content = try #require(result.structuredContent?.objectValue)
        let entries = try #require(content["unreadableFolders"]?.arrayValue)

        #expect(content["paths"] == ["/Users/test/a"])
        #expect(content["truncated"] == true)
        #expect(entries.count == 1)
    }
}
