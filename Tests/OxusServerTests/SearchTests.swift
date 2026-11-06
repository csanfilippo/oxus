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
        #expect(result.structuredContent == ["paths": ["/a", "/b"], "truncated": false])
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
        #expect(result.structuredContent == ["paths": ["/a", "/b"], "truncated": false])
    }

    @Test func `search with only a kind returns the paths Spotlight finds for the compiled kind query`() async throws {
        let spy = SpySpotlight(result: ["/a", "/b"])
        let client = try await connectedClient(spotlight: spy)

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["kind": "image"]))).value

        #expect(spy.receivedLimit?.value == 25)
        #expect(spy.receivedQuery?.text == #"kMDItemContentTypeTree == "public.image""#)
        #expect(result.structuredContent == ["paths": ["/a", "/b"], "truncated": false])
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
        #expect(result.structuredContent == ["paths": ["/a", "/b"], "truncated": false])
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

    @Test func `A folder denied by file permissions returns an error result naming the path and saying it lacks read permission`()
        async throws
    {
        let client = try await connectedClient(fileSystem: FilePermissionsDeniedFileSystem())

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": "/Users/test/Private"])
        let text = try #require(texts(in: content).first)

        #expect(isError == true)
        #expect(text.contains("/Users/test/Private"))
        #expect(text.contains("lacks read permission"))
    }

    @Test(arguments: ["Downloads", "Documents", "Desktop"])
    func
        `A protected folder denied by privacy protection returns an error result naming the path and the Files and Folders setting for that folder, granted to oxus if listed, otherwise to the app that launched oxus`(
            protectedFolder: String
        )
        async throws
    {
        let client = try await connectedClient(fileSystem: PrivacyProtectionDeniedFileSystem(), home: "/Users/test")

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": .string("~/\(protectedFolder)")])
        let text = try #require(texts(in: content).first)

        #expect(isError == true)
        #expect(text.contains("'/Users/test/\(protectedFolder)'"))
        #expect(text.contains("System Settings › Privacy & Security › Files and Folders › \(protectedFolder)"))
        #expect(text.contains("oxus if it is listed there, otherwise the app that launched oxus"))
    }

    @Test
    func
        `A folder inside ~/Downloads denied by privacy protection returns an error result naming the scope path and the Files and Folders › Downloads setting`()
        async throws
    {
        let client = try await connectedClient(fileSystem: PrivacyProtectionDeniedFileSystem(), home: "/Users/test")

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": "~/Downloads/Invoices"])
        let text = try #require(texts(in: content).first)

        #expect(isError == true)
        #expect(text.contains("'/Users/test/Downloads/Invoices'"))
        #expect(text.contains("System Settings › Privacy & Security › Files and Folders › Downloads"))
    }

    @Test(arguments: [
        ("/Volumes/Share", "/Volumes/Share"),
        ("~/Downloads Archive", "/Users/test/Downloads Archive"),
    ])
    func
        `A folder outside the three protected folders denied by privacy protection returns an error result naming the path and the generic Privacy & Security fix, with no folder setting`(
            folder: String, expected: String
        )
        async throws
    {
        let client = try await connectedClient(fileSystem: PrivacyProtectionDeniedFileSystem(), home: "/Users/test")

        let (content, isError) = try await client.callTool(name: "search", arguments: ["folder": .string(folder)])
        let text = try #require(texts(in: content).first)

        #expect(isError == true)
        #expect(text.contains("'\(expected)'"))
        #expect(text.contains("System Settings › Privacy & Security"))
        #expect(!text.contains("Files and Folders"))
        #expect(text.contains("oxus if it is listed there, otherwise the app that launched oxus"))
    }

    @Test
    func
        `search advertises an optional unreadableFolders array of objects with a required string path and fix, described as folders whose files are missing from paths`()
        async throws
    {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()
        let schema = try #require(toolWithName(tools: tools, name: "search")?.outputSchema?.objectValue)
        let unreadableFolders = try #require(schema["properties"]?.objectValue?["unreadableFolders"]?.objectValue)
        let item = try #require(unreadableFolders["items"]?.objectValue)
        let itemProperties = try #require(item["properties"]?.objectValue)
        let description = try #require(unreadableFolders["description"]?.stringValue)

        #expect(schema["required"] == ["paths", "truncated"])
        #expect(unreadableFolders["type"] == "array")
        #expect(item["type"] == "object")
        #expect(itemProperties["path"]?.objectValue?["type"] == "string")
        #expect(itemProperties["fix"]?.objectValue?["type"] == "string")
        #expect(item["required"] == ["path", "fix"])
        #expect(description.contains("missing from paths"))
    }

    @Test(arguments: ["search", "spotlight_query"])
    func
        `search and spotlight_query list truncated as a required boolean in their output schema, without saying it can be absent`(
            toolName: String
        )
        async throws
    {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()
        let schema = try #require(toolWithName(tools: tools, name: toolName)?.outputSchema?.objectValue)
        let truncated = try #require(schema["properties"]?.objectValue?["truncated"]?.objectValue)
        let description = try #require(truncated["description"]?.stringValue)

        #expect(schema["required"] == ["paths", "truncated"])
        #expect(truncated["type"] == "boolean")
        #expect(description.contains("more matches exist than paths holds"))
        #expect(description.contains("raise limit or narrow the search"))
        #expect(!description.contains("Absent"))
    }

    @Test(arguments: ["search", "spotlight_query"])
    func `search and spotlight_query describe their limit argument as truncated being true when a result is cut off`(toolName: String)
        async throws
    {
        let client = try await connectedClient()

        let (tools, _) = try await client.listTools()
        let schema = try #require(toolWithName(tools: tools, name: toolName)?.inputSchema.objectValue)
        let limit = try #require(schema["properties"]?.objectValue?["limit"]?.objectValue)
        let description = try #require(limit["description"]?.stringValue)

        #expect(description.contains("truncated is true"))
        #expect(description.contains("cut off"))
    }

    @Test
    func
        `A search scoped to ~ with ~/Downloads denied by privacy protection returns the paths Spotlight finds and one unreadableFolders entry with the Downloads path and the Files and Folders › Downloads fix`()
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads")
        ])
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a"]), fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "~"]))).value

        #expect(result.isError != true)
        #expect(
            result.structuredContent == [
                "paths": ["/Users/test/a"],
                "unreadableFolders": [
                    [
                        "path": "/Users/test/Downloads",
                        "fix":
                            "Allow access in System Settings › Privacy & Security › Files and Folders › Downloads, for oxus if it is listed there, otherwise the app that launched oxus",
                    ]
                ],
                "truncated": false,
            ])
    }

    @Test
    func
        `A search scoped to ~ with all three protected folders denied returns three entries in Downloads, Documents, Desktop order, each naming its own setting`()
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Desktop": .deniedByPrivacyProtection(path: "/Users/test/Desktop"),
            "/Users/test/Documents": .deniedByPrivacyProtection(path: "/Users/test/Documents"),
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads"),
        ])
        let client = try await connectedClient(fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "~"]))).value
        let entries = try #require(result.structuredContent?.objectValue?["unreadableFolders"]?.arrayValue)

        #expect(entries.map { $0.objectValue?["path"] } == ["/Users/test/Downloads", "/Users/test/Documents", "/Users/test/Desktop"])
        for (entry, protectedFolder) in zip(entries, ["Downloads", "Documents", "Desktop"]) {
            let fix = try #require(entry.objectValue?["fix"]?.stringValue)
            #expect(fix.contains("System Settings › Privacy & Security › Files and Folders › \(protectedFolder),"))
        }
    }

    @Test func `A search scoped to a folder containing the home folder (/Users) reports a denied ~/Documents`() async throws {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Documents": .deniedByPrivacyProtection(path: "/Users/test/Documents")
        ])
        let client = try await connectedClient(fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "/Users"]))).value
        let entries = try #require(result.structuredContent?.objectValue?["unreadableFolders"]?.arrayValue)

        #expect(entries.map { $0.objectValue?["path"] } == ["/Users/test/Documents"])
    }

    @Test func `A search scoped to ~ with all three protected folders readable returns no unreadableFolders key`() async throws {
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a"]), fileSystem: ScriptedFileSystem(), home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "~"]))).value

        #expect(result.isError != true)
        #expect(result.structuredContent == ["paths": ["/Users/test/a"], "truncated": false])
    }

    @Test(arguments: [
        FolderError.notFound(path: "/Users/test/Downloads"),
        FolderError.deniedByFilePermissions(path: "/Users/test/Downloads"),
        FolderError.unreadable(path: "/Users/test/Downloads", reason: "Input/output error"),
    ])
    func `A protected folder that is missing, lacks read permission or fails with another reason adds no entry`(failure: FolderError)
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: ["/Users/test/Downloads": failure])
        let client = try await connectedClient(fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "~"]))).value

        #expect(result.isError != true)
        #expect(result.structuredContent == ["paths": [], "truncated": false])
    }

    @Test func `A search scoped to a folder containing none of the protected folders (/System/Applications) adds no entry`()
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads")
        ])
        let client = try await connectedClient(fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(
            CallTool.request(.init(name: "search", arguments: ["folder": "/System/Applications"]))
        ).value

        #expect(result.structuredContent == ["paths": [], "truncated": false])
        #expect(fileSystem.checkedPaths == ["/System/Applications"])
    }

    @Test func `The protected folders are probed before Spotlight runs the query`() async throws {
        let fileSystem = ScriptedFileSystem()
        let spotlight = CheckedPathsRecordingSpotlight(fileSystem: fileSystem)
        let client = try await connectedClient(spotlight: spotlight, fileSystem: fileSystem, home: "/Users/test")

        _ = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "~"]))).value

        #expect(
            spotlight.checkedPathsWhenSearched == [
                "/Users/test", "/Users/test/Downloads", "/Users/test/Documents", "/Users/test/Desktop",
            ])
    }

    @Test func `A scope that fails its own check returns its error and probes no protected folder`() async throws {
        let fileSystem = ScriptedFileSystem(failures: ["/Users/test": .deniedByFilePermissions(path: "/Users/test")])
        let client = try await connectedClient(fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "~"]))).value

        #expect(result.isError == true)
        #expect(fileSystem.checkedPaths == ["/Users/test"])
    }

    @Test func `The text block decodes to the structured content, including unreadableFolders`() async throws {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads")
        ])
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a"]), fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "~"]))).value
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(result.content.count == 1)
        #expect(result.structuredContent?.objectValue?["unreadableFolders"] != nil)
        #expect(mirrored == result.structuredContent)
    }

    @Test func `The text block decodes to the structured content, including truncated`() async throws {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads")
        ])
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a", "/Users/test/b"]), fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["folder": "~", "limit": 1]))).value
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(result.content.count == 1)
        #expect(result.structuredContent?.objectValue?["unreadableFolders"] != nil)
        #expect(result.structuredContent?.objectValue?["truncated"] != nil)
        #expect(mirrored == result.structuredContent)
    }

    @Test func `The text block decodes to the structured content, including truncated false`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight(result: ["/a"]))

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["name_contains": "test"]))).value
        let text = try #require(texts(in: result.content).first)
        let mirrored = try JSONDecoder().decode(Value.self, from: Data(text.utf8))

        #expect(result.content.count == 1)
        #expect(result.structuredContent?.objectValue?["truncated"] == false)
        #expect(mirrored == result.structuredContent)
    }

    @Test
    func
        `An unscoped search with ~/Downloads denied by privacy protection returns the paths Spotlight finds and one unreadableFolders entry with the Downloads path and the Files and Folders › Downloads fix`()
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads")
        ])
        let client = try await connectedClient(
            spotlight: SpySpotlight(result: ["/Users/test/a"]), fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["name_contains": "test"]))).value

        #expect(result.isError != true)
        #expect(
            result.structuredContent == [
                "paths": ["/Users/test/a"],
                "unreadableFolders": [
                    [
                        "path": "/Users/test/Downloads",
                        "fix":
                            "Allow access in System Settings › Privacy & Security › Files and Folders › Downloads, for oxus if it is listed there, otherwise the app that launched oxus",
                    ]
                ],
                "truncated": false,
            ])
    }

    @Test
    func
        `An unscoped search with all three protected folders denied returns three entries in Downloads, Documents, Desktop order, each naming its own setting`()
        async throws
    {
        let fileSystem = ScriptedFileSystem(failures: [
            "/Users/test/Desktop": .deniedByPrivacyProtection(path: "/Users/test/Desktop"),
            "/Users/test/Documents": .deniedByPrivacyProtection(path: "/Users/test/Documents"),
            "/Users/test/Downloads": .deniedByPrivacyProtection(path: "/Users/test/Downloads"),
        ])
        let client = try await connectedClient(fileSystem: fileSystem, home: "/Users/test")

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["kind": "pdf"]))).value
        let entries = try #require(result.structuredContent?.objectValue?["unreadableFolders"]?.arrayValue)

        #expect(entries.map { $0.objectValue?["path"] } == ["/Users/test/Downloads", "/Users/test/Documents", "/Users/test/Desktop"])
        for (entry, protectedFolder) in zip(entries, ["Downloads", "Documents", "Desktop"]) {
            let fix = try #require(entry.objectValue?["fix"]?.stringValue)
            #expect(fix.contains("System Settings › Privacy & Security › Files and Folders › \(protectedFolder),"))
        }
    }

    @Test func `A search whose matches exceed limit returns limit paths and truncated true`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight(result: ["/a", "/b"]))

        let result = try await client.send(
            CallTool.request(.init(name: "search", arguments: ["name_contains": "test", "limit": 1]))
        ).value

        let content = try #require(result.structuredContent?.objectValue)

        #expect(content["paths"] == ["/a"])
        #expect(content["truncated"] == true)
    }

    @Test func `A search with no matches returns empty paths and truncated false`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight())

        let result = try await client.send(CallTool.request(.init(name: "search", arguments: ["name_contains": "test"]))).value

        #expect(result.structuredContent == ["paths": [], "truncated": false])
    }

    @Test func `A search whose matches equal limit returns them all and truncated false`() async throws {
        let client = try await connectedClient(spotlight: SpySpotlight(result: ["/a", "/b"]))

        let result = try await client.send(
            CallTool.request(.init(name: "search", arguments: ["name_contains": "test", "limit": 2]))
        ).value

        let content = try #require(result.structuredContent?.objectValue)

        #expect(content["paths"] == ["/a", "/b"])
        #expect(content["truncated"] == false)
    }
}
