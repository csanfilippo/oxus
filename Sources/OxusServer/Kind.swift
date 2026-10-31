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

enum Kind: String, CaseIterable, ToolArgument {
    case image
    case movie
    case audio
    case pdf
    case folder
    case application

    static let name = "kind"
    private static let acceptedKinds = allCases.map(\.rawValue)
    static let schema: Value = .object([
        "type": "string",
        "enum": .array(acceptedKinds.map { .string($0) }),
        "description": "The kind of file to find; a kind includes all its subtypes, e.g. image matches PNG, JPEG and HEIC",
    ])

    enum Error: ToolFailure {
        case unknown(String)
        case wrongType(String)

        var message: String {
            switch self {
            case .unknown(let value):
                "unknown kind \(value); accepted kinds are: \(Kind.acceptedKinds.joined(separator: ","))"
            case .wrongType(let value):
                "wrong kind \(value); kind must be a string; accepted kinds are: \(Kind.acceptedKinds.joined(separator: ","))"
            }
        }
    }

    var spotlightQuery: String {
        #"kMDItemContentTypeTree == "\#(contentType)""#
    }

    private var contentType: String {
        return switch self {
        case .image:
            "public.image"
        case .movie:
            "public.movie"
        case .audio:
            "public.audio"
        case .pdf:
            "com.adobe.pdf"
        case .folder:
            "public.folder"
        case .application:
            "com.apple.application"
        }
    }

    init(_ argument: Value) throws(Error) {
        if let stringValue = argument.stringValue {
            try self.init(parsing: stringValue)
        } else {
            throw .wrongType(String(describing: argument))
        }
    }

    init(parsing value: String) throws(Error) {
        guard let kind = Kind(rawValue: value) else { throw .unknown(value) }
        self = kind
    }
}
