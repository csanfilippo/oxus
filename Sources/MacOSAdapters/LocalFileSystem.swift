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
import OxusServer

public struct LocalFileSystem: FileSystem {
    public init() {}

    public func checkSearchable(_ folder: Folder) throws(FolderError) {
        try throwIfNotAReadableFolder(folder)

        try throwIfPackage(folder)
    }

    private func throwIfNotAReadableFolder(_ folder: Folder) throws(FolderError) {
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        } catch {
            throw FolderError(readFailure: error, path: folder.path)
        }
    }

    private func throwIfPackage(_ folder: Folder) throws(FolderError) {
        let resourceValues: URLResourceValues
        do {
            resourceValues = try URL(filePath: folder.path).resolvingSymlinksInPath().resourceValues(forKeys: [.isPackageKey])
        } catch {
            throw FolderError(readFailure: error, path: folder.path)
        }

        guard resourceValues.isPackage == true else {
            return
        }

        throw .package(path: folder.path)
    }
}

extension FolderError {
    init(readFailure: any Error, path: String) {
        let cocoaError = readFailure as? CocoaError
        let posixErrorCode = (cocoaError?.underlying as? POSIXError)?.code

        switch (cocoaError?.code, posixErrorCode) {
        case (.fileReadNoSuchFile?, _):
            self = .notFound(path: path)
        case (_, .ENOTDIR?):
            self = .notAFolder(path: path)
        case (_, .EPERM?):
            self = .deniedByPrivacyProtection(path: path)
        case (_, .EACCES?):
            self = .deniedByFilePermissions(path: path)
        case (_, let errorCode?):
            self = .unreadable(path: path, reason: String(cString: strerror(errorCode.rawValue)))
        case (_, nil):
            self = .unreadable(path: path, reason: readFailure.localizedDescription)
        }
    }
}
