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
        } catch let error as CocoaError {

            let posixError = error.underlying as? POSIXError
            let posixErrorCode = posixError?.code
            switch (error.code, posixErrorCode) {
            case (.fileReadNoSuchFile, _):
                throw .notFound(path: folder.path)
            case (_, .ENOTDIR):
                throw .notAFolder(path: folder.path)
            case (.fileReadNoPermission, let errorCode?):
                throw .unreadable(path: folder.path, reason: String(cString: strerror(errorCode.rawValue)))
            default:
                break
            }
        } catch {}
    }

    private func throwIfPackage(_ folder: Folder) throws(FolderError) {
        let resourceValues = try? URL(filePath: folder.path).resolvingSymlinksInPath().resourceValues(forKeys: [.isPackageKey])

        guard resourceValues?.isPackage == true else {
            return
        }

        throw .package(path: folder.path)
    }
}
