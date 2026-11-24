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

struct SearchCriteria {
    enum Error: ToolFailure {
        case noFilters

        var message: String {
            "at least one of \(NameContainsArgument.name) or \(KindArgument.name) or \(FolderArgument.name) is required"
        }
    }

    let query: Query
    let folder: Folder?

    init(nameContains: NameContains? = nil, kind: Kind? = nil, folder: Folder? = nil) throws(Error) {
        let filters = [nameContains?.query, kind?.query].compactMap { $0 }

        switch (Query.all(of: filters), folder) {
        case (let query?, _): self.query = query
        case (nil, _?): query = .everyFile
        case (nil, nil): throw .noFilters
        }

        self.folder = folder
    }
}
