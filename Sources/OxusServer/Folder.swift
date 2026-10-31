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

public struct Folder: Sendable {
    public enum Error: Swift.Error {
        case unacceptedForm
    }

    static let acceptedForms = "an absolute path, ~ alone, or a path starting with ~/"

    public let path: String

    public init(path: String, home: String) throws(Error) {
        if path == "~" || path.hasPrefix("~/") {
            self.path = home + path.dropFirst()
        } else if path.hasPrefix("/") {
            self.path = path
        } else {
            throw .unacceptedForm
        }
    }
}

struct FolderArgument: NonEmptyStringArgument {
    static let name = "folder"
    static let schema: Value = .object([
        "type": "string",
        "description": "The path of the folder to search",
    ])

    enum Error: ToolFailure {
        case unacceptedForm

        var message: String {
            "\(FolderArgument.name) must be \(Folder.acceptedForms)"
        }
    }

    private let path: String

    init(_ argument: Value) throws {
        path = try Self.nonEmptyValue(of: argument)
    }

    func folder(home: String) throws(Error) -> Folder {
        do {
            return try Folder(path: path, home: home)
        } catch {
            throw .unacceptedForm
        }
    }
}
