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
        guard let protectedFolder = Self.allCases.first(where: { folder.path == home.path + "/" + $0.rawValue }) else {
            return nil
        }

        self = protectedFolder
    }
}

// TCC judges either oxus or the app that launched it, depending on the host, and oxus cannot tell which.
let privacyProtectionGrantee = "oxus if it is listed there, otherwise the app that launched oxus"

struct ProtectedFolderDenial: ToolFailure {
    let path: String
    let protectedFolder: ProtectedFolder

    var message: String {
        "'\(path)' is denied by macOS privacy protection. Allow access in System Settings › Privacy & Security › Files and Folders › \(protectedFolder.rawValue), for \(privacyProtectionGrantee)"
    }
}
