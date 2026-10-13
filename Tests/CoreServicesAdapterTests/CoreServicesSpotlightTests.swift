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
import Testing
import OxusServer
import CoreServicesAdapter

@Suite struct CoreServicesAdapterTests {
    @Test func `Real Spotlight finds Finder.app by name`() async throws {
        let spotlight = CoreServicesSpotlight()

        let paths = try await spotlight.search(query: #"kMDItemFSName == "Finder.app""#, limit: 10)

        #expect(paths.contains("/System/Library/CoreServices/Finder.app"))
    }
    
    @Test func `Real Spotlight returns at most the requested number of paths`() async throws {
        let spotlight = CoreServicesSpotlight()

        let paths = try await spotlight.search(query: #"kMDItemContentType == "com.apple.application-bundle""#, limit: 2)

        #expect(paths.count == 2)
    }
    
    @Test func `Real Spotlight reports a malformed query as invalid`() async throws {
        let spotlight = CoreServicesSpotlight()

        let error = try await #require(throws: SpotlightError.self) {
            try await spotlight.search(query: "kMDItemFSName ==", limit: 2)
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

        let paths = try await spotlight.search(query: #"kMDItemFSName == "\#(nonexistentFileName)""#, limit: 2)

        #expect(paths.isEmpty)
    }
}
