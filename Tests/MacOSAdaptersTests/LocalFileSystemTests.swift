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

@Suite struct LocalFileSystemTests {
    @Test func `a folder that does not exist is reported as not found, with its path`() throws {
        let fileSystem = LocalFileSystem()

        let error = #expect(throws: FolderError.self) {
            try fileSystem.checkSearchable(Folder(absolutePath: "/not/existing"))
        }

        guard case .notFound(let path) = error else {
            Issue.record("expected .notFound, got \(String(describing: error))")
            return
        }

        #expect(path == "/not/existing")
    }

    @Test func `/System/Library/CoreServices/SystemVersion.plist is reported as not a folder, with its path`() throws {
        let fileSystem = LocalFileSystem()

        let error = #expect(throws: FolderError.self) {
            try fileSystem.checkSearchable(Folder(absolutePath: "/System/Library/CoreServices/SystemVersion.plist"))
        }

        guard case .notAFolder(let path) = error else {
            Issue.record("expected .notAFolder, got \(String(describing: error))")
            return
        }

        #expect(path == "/System/Library/CoreServices/SystemVersion.plist")
    }

    @Test func `/System/Applications/Calculator.app is reported as a package, with its path`() throws {
        let fileSystem = LocalFileSystem()

        let error = #expect(throws: FolderError.self) {
            try fileSystem.checkSearchable(Folder(absolutePath: "/System/Applications/Calculator.app"))
        }

        guard case .package(let path) = error else {
            Issue.record("expected .package, got \(String(describing: error))")
            return
        }

        #expect(path == "/System/Applications/Calculator.app")
    }

    @Test func `a symlink to /System/Applications/Calculator.app is reported as a package`() throws {
        let fileSystem = LocalFileSystem()
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let link = directory.appending(path: "Calculator.app").path()
        try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: "/System/Applications/Calculator.app")

        let error = #expect(throws: FolderError.self) {
            try fileSystem.checkSearchable(Folder(absolutePath: link))
        }

        guard case .package(let path) = error else {
            Issue.record("expected .package, got \(String(describing: error))")
            return
        }

        #expect(path == link)
    }

    @Test func `a chmod 000 folder is reported as unreadable, with its path and the reason Permission denied`() throws {
        let fileSystem = LocalFileSystem()

        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: folder.path())

        let error = #expect(throws: FolderError.self) {
            try fileSystem.checkSearchable(Folder(absolutePath: folder.path()))
        }

        guard case .unreadable(let path, let reason) = error else {
            Issue.record("expected .unreadable, got \(String(describing: error))")
            return
        }

        #expect(path == folder.path())
        #expect(reason == "Permission denied")
    }
}
