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
import Testing

@Suite struct VersionFlagTests {
    @Test func `oxus --version prints its version on stdout, nothing on stderr, and exits 0`() throws {
        let run = try runOxus(arguments: ["--version"])

        #expect(run.stdout == "oxus \(oxusVersion)\n")
        #expect(run.stderr == "")
        #expect(run.status == 0)
    }
}

private final class TestBundleMarker {}

private struct OxusRun {
    let stdout: String
    let stderr: String
    let status: Int32
}

private func runOxus(arguments: [String]) throws -> OxusRun {
    let process = Process()
    process.executableURL = Bundle(for: TestBundleMarker.self).bundleURL
        .deletingLastPathComponent()
        .appending(path: "oxus")
    process.arguments = arguments
    process.standardInput = FileHandle.nullDevice
    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()
    let output = stdout.fileHandleForReading.readDataToEndOfFile()
    let errors = stderr.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    return OxusRun(
        stdout: String(decoding: output, as: UTF8.self),
        stderr: String(decoding: errors, as: UTF8.self),
        status: process.terminationStatus
    )
}
