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

struct SearchTool: OxusTool {
    let definition: Tool = Tool(
        name: "search",
        description:
            "Finds files by name, kind, folder, or any combination of them, without Spotlight query syntax. At least one of name_contains, kind or folder is required; when several are given, a file must match all of them. Name matching ignores case and diacritics. A folder search includes its subfolders; folder must be an absolute path, ~ alone, or a path starting with ~/. Only files Spotlight has indexed can be found. Returns at most \(Limit.maximum) paths.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                NameContains.name: .object([
                    "type": "string",
                    "description": "Text the file's name must contain",
                ]),
                "limit": Limit.schema,
                "kind": .object([
                    "type": "string",
                    "enum": .array(Kind.allCases.map { .string($0.rawValue) }),
                    "description": "The kind of file to find; a kind includes all its subtypes, e.g. image matches PNG, JPEG and HEIC",
                ]),
                "folder": .object([
                    "type": "string",
                    "description": "The path of the folder to search",
                ]),
            ]),
            "required": [],
        ]),
        annotations: Tool.Annotations(readOnlyHint: true, openWorldHint: false),
        outputSchema: OxusResponse.schema
    )

    let spotlight: any Spotlight
    let home: String

    func call(with arguments: [String: Value]?) async throws -> CallTool.Result {
        do {
            let folder = try arguments?["folder"].map { try Folder($0, home: home) }
            let criteria = try SearchCriteria(
                nameContains: arguments?[NameContains.name].map { try NameContains($0) },
                kind: arguments?["kind"].map { try Kind($0) },
                folder: folder
            )
            let limit = try Limit(arguments?["limit"])
            return try await spotlight.pathsResult(query: criteria.spotlightQuery, limit: limit.value, folder: folder)
        } catch let failure as any ToolFailure {
            return failure.asResult
        }
    }
}
