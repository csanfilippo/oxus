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

import CoreServices
import Foundation
import OxusServer

public struct CoreServicesSpotlight: Spotlight {
    public func search(query: Query, limit: Limit, folder: Folder?) async throws(SpotlightError) -> [String] {

        guard let spotlightQuery = MDQueryCreate(kCFAllocatorDefault, query.text as CFString, nil, nil) else {
            throw .malformedQuery(query: query.text)
        }

        MDQuerySetMaxCount(spotlightQuery, limit.value)

        if let folder {
            MDQuerySetSearchScope(spotlightQuery, [folder.path] as CFArray, 0)
        }

        guard MDQueryExecute(spotlightQuery, CFOptionFlags(kMDQuerySynchronous.rawValue)) else {
            throw .executionFailed(query: query.text)
        }

        return (0..<MDQueryGetResultCount(spotlightQuery)).compactMap { index in
            let item = Unmanaged<MDItem>.fromOpaque(MDQueryGetResultAtIndex(spotlightQuery, index)).takeUnretainedValue()
            return MDItemCopyAttribute(item, kMDItemPath) as? String
        }
    }

    public init() {}
}
