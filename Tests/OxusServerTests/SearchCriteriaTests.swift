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
import Testing
@testable import OxusServer

@Suite struct SearchCriteriaTests {
    @Test func `A name compiles to a case- and diacritic-insensitive contains match on the display name`() throws {
        let criteria = try SearchCriteria(from: ["name_contains": .string("report")])

        #expect(criteria.spotlightQuery == #"kMDItemDisplayName == "*report*"cd"#)
    }
    
    @Test(arguments: [
        (#"say "hi""#, #"say \"hi\""#),
        (#"C:\temp"#, #"C:\\temp"#),
        ("*.txt", #"\*.txt"#),
        (#"\""#, #"\\\""#),
    ])
    func `Quotes, backslashes and asterisks in the name are matched literally`(name: String, escapedName: String) throws {
        let criteria = try SearchCriteria(from: ["name_contains": .string(name)])

        #expect(criteria.spotlightQuery == #"kMDItemDisplayName == "*\#(escapedName)*"cd"#)
    }
    
    @Test func `A name and a kind compile to both matches combined with AND`() throws {
        let criteria = try SearchCriteria(from: [
            "name_contains": "finde",
            "kind": "application"
        ])

        #expect(criteria.spotlightQuery == #"kMDItemDisplayName == "*finde*"cd && kMDItemContentTypeTree == "com.apple.application""#)
    }
}
