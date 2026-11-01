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

public enum FolderError: Error, ToolFailure {
    case notFound(path: String)
    case notAFolder(path: String)
    case package(path: String)
    case deniedByPrivacyProtection(path: String)
    case deniedByFilePermissions(path: String)
    case unreadable(path: String, reason: String)

    var message: String {
        return switch self {
        case .notFound(let path):
            "'\(path)' does not exist. Please correct the path"
        case .notAFolder(let path):
            "'\(path)' is a file. Search its parent folder instead"
        case .package(let path):
            "'\(path)' is a package. Search elsewhere"
        case .deniedByPrivacyProtection(let path):
            "'\(path)' is denied by macOS privacy protection. Allow access in System Settings › Privacy & Security, for \(privacyProtectionGrantee)"
        case .deniedByFilePermissions(let path):
            "'\(path)' lacks read permission. Grant your user read permission on it"
        case .unreadable(let path, let reason):
            "'\(path)' is not readable. Reason '\(reason)'"
        }
    }
}

public protocol FileSystem: Sendable {
    func checkSearchable(_ folder: Folder) throws(FolderError)
}
