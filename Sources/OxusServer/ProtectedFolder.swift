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

enum ProtectedFolder: String, CaseIterable {
    case downloads = "Downloads"
    case documents = "Documents"
    case desktop = "Desktop"

    init?(containing folder: Folder, home: Folder) {
        guard let protectedFolder = Self.allCases.first(where: { $0.contains(folder, home: home) }) else {
            return nil
        }

        self = protectedFolder
    }

    static func inside(_ scope: Folder, home: Folder) -> [ProtectedFolder] {
        let scopePrefix = scope.path.hasSuffix("/") ? scope.path : scope.path + "/"
        return allCases.filter { $0.path(home: home).hasPrefix(scopePrefix) }
    }

    var fix: String {
        "Allow access in System Settings › Privacy & Security › Files and Folders › \(rawValue), for \(privacyProtectionGrantee)"
    }

    func folder(home: Folder) -> Folder {
        // A path appended to an absolute home folder is absolute.
        try! Folder(absolutePath: path(home: home))
    }

    private func path(home: Folder) -> String {
        home.path + "/" + rawValue
    }

    private func contains(_ folder: Folder, home: Folder) -> Bool {
        let path = path(home: home)
        return folder.path == path || folder.path.hasPrefix(path + "/")
    }
}

// TCC judges either oxus or the app that launched it, depending on the host, and oxus cannot tell which.
let privacyProtectionGrantee = "oxus if it is listed there, otherwise the app that launched oxus"

struct ProtectedFolderDenial: ToolFailure {
    let path: String
    let protectedFolder: ProtectedFolder

    var message: String {
        "'\(path)' is denied by macOS privacy protection. \(protectedFolder.fix)"
    }
}
