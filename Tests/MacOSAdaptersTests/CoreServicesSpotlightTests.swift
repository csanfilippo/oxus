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
import MacOSAdapters
import OxusServer
import Testing

@Suite struct CoreServicesSpotlightTests {
    @Test func `Real Spotlight finds Finder.app by name`() async throws {
        let spotlight = CoreServicesSpotlight()

        let matches = try await spotlight.search(query: Query(#"kMDItemFSName == "Finder.app""#), limit: Limit(10), folder: nil)

        #expect(matches.paths.contains("/System/Library/CoreServices/Finder.app"))
    }

    @Test func `Real Spotlight returns at most the requested number of paths`() async throws {
        let spotlight = CoreServicesSpotlight()

        let matches = try await spotlight.search(
            query: Query(#"kMDItemContentType == "com.apple.application-bundle""#), limit: Limit(2), folder: nil)

        #expect(matches.paths.count == 2)
    }

    @Test func `Real Spotlight reports a malformed query as invalid`() async throws {
        let spotlight = CoreServicesSpotlight()

        let error = try await #require(throws: SpotlightError.self) {
            try await spotlight.search(query: Query("kMDItemFSName =="), limit: Limit(2), folder: nil)
        }
        guard case .malformedQuery(let query) = error else {
            Issue.record("expected malformedQuery, got \(error)")
            return
        }
        #expect(query == "kMDItemFSName ==")
    }

    @Test func `Real Spotlight returns no paths for a nonexistent file name`() async throws {
        let spotlight = CoreServicesSpotlight()
        let nonexistentFileName = UUID().uuidString

        let matches = try await spotlight.search(query: Query(#"kMDItemFSName == "\#(nonexistentFileName)""#), limit: Limit(2), folder: nil)

        #expect(matches.paths.isEmpty)
    }

    @Test func `a scope includes its subfolders: Terminal.app is found under /System/Applications`() async throws {
        let spotlight = CoreServicesSpotlight()

        let matches = try await spotlight.search(
            query: Query(#"kMDItemFSName == "Terminal.app""#),
            limit: Limit(10),
            folder: Folder(absolutePath: "/System/Applications")
        )

        #expect(matches.paths.contains("/System/Applications/Utilities/Terminal.app"))
    }

    @Test func `a scope excludes files outside it: Finder.app is not found under /System/Applications`() async throws {
        let spotlight = CoreServicesSpotlight()

        let matches = try await spotlight.search(
            query: Query(#"kMDItemFSName == "Finder.app""#),
            limit: Limit(10),
            folder: Folder(absolutePath: "/System/Applications")
        )

        #expect(!matches.paths.contains("/System/Library/CoreServices/Finder.app"))
    }

    @Test func `the scope folder is never a result: Utilities is not found under /Applications/Utilities`() async throws {
        let spotlight = CoreServicesSpotlight()

        let matches = try await spotlight.search(
            query: Query(#"kMDItemFSName == "Utilities""#),
            limit: Limit(10),
            folder: Folder(absolutePath: "/Applications/Utilities")
        )

        #expect(!matches.paths.contains("/Applications/Utilities"))
    }

    @Test func `the match-all query finds files of any name in a scope, e.g. Calculator.app and Terminal.app under /System/Applications`()
        async throws
    {
        let spotlight = CoreServicesSpotlight()

        let matches = try await spotlight.search(
            query: Query(#"kMDItemDisplayName == "*""#),
            limit: Limit(100),
            folder: Folder(absolutePath: "/System/Applications")
        )

        #expect(matches.paths.contains("/System/Applications/Calculator.app"))
        #expect(matches.paths.contains("/System/Applications/Utilities/Terminal.app"))
    }

    @Test func `a scope through a symlink finds the same paths as the folder it points to`() async throws {
        let spotlight = CoreServicesSpotlight()
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let link = directory.appending(path: "Utilities").path()
        try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: "/System/Applications/Utilities")

        let pathsThroughLink = try await spotlight.search(
            query: Query(#"kMDItemDisplayName == "*""#), limit: Limit(100), folder: Folder(absolutePath: link)
        ).paths
        let matches = try await spotlight.search(
            query: Query(#"kMDItemDisplayName == "*""#),
            limit: Limit(100),
            folder: Folder(absolutePath: "/System/Applications/Utilities")
        )

        #expect(matches.paths.contains("/System/Applications/Utilities/Terminal.app"))
        #expect(Set(pathsThroughLink) == Set(matches.paths))
    }

    @Test func `CoreServicesSpotlight answers more concurrent searches than the Mac has CPUs`() async throws {
        let spotlight = CoreServicesSpotlight()
        let searchCount = ProcessInfo.processInfo.activeProcessorCount + 1

        let results = try await withThrowingTaskGroup(of: [String].self) { group in
            for _ in 0..<searchCount {
                group.addTask {
                    try await spotlight.search(query: Query(#"kMDItemFSName == "Finder.app""#), limit: Limit(10), folder: nil).paths
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(results.count == searchCount)
        #expect(results.allSatisfy { $0.contains("/System/Library/CoreServices/Finder.app") })
    }

    @Test func `Separate CoreServicesSpotlight instances answer more concurrent searches than the Mac has CPUs`() async throws {
        let searchCount = ProcessInfo.processInfo.activeProcessorCount + 1

        let results = try await withThrowingTaskGroup(of: [String].self) { group in
            for _ in 0..<searchCount {
                group.addTask {
                    try await CoreServicesSpotlight().search(query: Query(#"kMDItemFSName == "Finder.app""#), limit: Limit(10), folder: nil)
                        .paths
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(results.count == searchCount)
        #expect(results.allSatisfy { $0.contains("/System/Library/CoreServices/Finder.app") })
    }

    @Test func `Concurrent searches for different files each return their own path`() async throws {
        let spotlight = CoreServicesSpotlight()
        let files = [
            (name: "Finder.app", path: "/System/Library/CoreServices/Finder.app"),
            (name: "Terminal.app", path: "/System/Applications/Utilities/Terminal.app"),
            (name: "Calculator.app", path: "/System/Applications/Calculator.app"),
        ]
        let searchCount = ProcessInfo.processInfo.activeProcessorCount + 1

        let results = try await withThrowingTaskGroup(of: (expected: String, paths: [String]).self) { group in
            for index in 0..<searchCount {
                let file = files[index % files.count]
                group.addTask {
                    let query = try Query(#"kMDItemFSName == "\#(file.name)""#)
                    return (file.path, try await spotlight.search(query: query, limit: Limit(10), folder: nil).paths)
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(results.count == searchCount)
        for result in results {
            #expect(result.paths == [result.expected])
        }
    }

    @Test func `A malformed query among concurrent searches reports its own error and the others return their paths`() async throws {
        let spotlight = CoreServicesSpotlight()
        let malformedQuery = "kMDItemFSName =="
        let searchCount = ProcessInfo.processInfo.activeProcessorCount + 1

        let results = await withTaskGroup(of: Result<[String], SpotlightError>.self) { group in
            for index in 0..<searchCount {
                let text = index == 0 ? malformedQuery : #"kMDItemFSName == "Finder.app""#
                group.addTask {
                    do {
                        return .success(try await spotlight.search(query: Query(text), limit: Limit(10), folder: nil).paths)
                    } catch let error as SpotlightError {
                        return .failure(error)
                    } catch {
                        fatalError("unexpected error: \(error)")
                    }
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }

        var malformedQueries: [String] = []
        var paths: [[String]] = []
        for result in results {
            switch result {
            case .success(let found):
                paths.append(found)
            case .failure(.malformedQuery(let query)):
                malformedQueries.append(query)
            case .failure(let error):
                Issue.record("expected malformedQuery, got \(error)")
            }
        }

        #expect(malformedQueries == [malformedQuery])
        #expect(paths.count == searchCount - 1)
        #expect(paths.allSatisfy { $0.contains("/System/Library/CoreServices/Finder.app") })
    }
}
