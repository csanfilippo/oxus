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

enum Kind: String, CaseIterable {
    case image
    case movie
    case audio
    case pdf
    case folder
    case application
    
    enum Error: Swift.Error {
        case unknown(String)
        case wrongType(String)

        var message: String {
            switch self {
            case .unknown(let value):
                "unknown kind \(value); accepted kinds are: \(Kind.allCases.map(\.rawValue).joined(separator: ","))"
            case .wrongType(let value):
                "wrong kind \(value); kind must be a string; accepted kinds are: \(Kind.allCases.map(\.rawValue).joined(separator: ","))"
            }
        }
    }
    
    var spotlightQuery: String {
        return switch self {
        case .image:
            #"kMDItemContentTypeTree == "public.image""#
        case .movie:
            #"kMDItemContentTypeTree == "public.movie""#
        case .audio:
            #"kMDItemContentTypeTree == "public.audio""#
        case .pdf:
            #"kMDItemContentTypeTree == "com.adobe.pdf""#
        case .folder:
            #"kMDItemContentTypeTree == "public.folder""#
        case .application:
            #"kMDItemContentTypeTree == "com.apple.application""#
        }
    }
    
    init?(from arg: [String: Value]?) throws(Error) {
        
        guard let kind = arg?["kind"] else {
            return nil
        }
        
        if let stringValue = kind.stringValue {
            try self.init(parsing: stringValue)
        } else {
            throw .wrongType(String(describing: kind))
        }
    }
    
    init(parsing value: String) throws(Error) {
        guard let kind = Kind(rawValue: value) else { throw .unknown(value) }
        self = kind
    }
}
