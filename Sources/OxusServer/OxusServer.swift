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

public func makeOxusServer(spotlight: any Spotlight, fileSystem: any FileSystem, home: Folder) async -> Server {
    let server = Server(
        name: "oxus",
        version: "0.1.0",
        capabilities: .init(tools: .init())
    )

    let tools: [any OxusTool] = [
        SpotlightQueryTool(spotlight: spotlight), SearchTool(spotlight: spotlight, fileSystem: fileSystem, home: home),
    ]

    await server.withMethodHandler(ListTools.self) { _ in
        .init(tools: tools.map(\.definition))
    }

    await server.withMethodHandler(CallTool.self) { params in

        let selectedTool = tools.first { tool in
            tool.definition.name == params.name
        }

        guard let selectedTool else {
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }

        return try await selectedTool.call(with: params.arguments ?? [:])
    }

    return server
}
