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

// Run from the repository root: swift docs/design/architecture.swift docs/design/architecture.png

import AppKit

let width: CGFloat = 1495
let height: CGFloat = 810
let scale: CGFloat = 2

enum Style {
    case type, `protocol`, external
}

struct Node {
    let name: String
    let stereotype: String
    let subtitle: String
    let center: CGPoint
    let width: CGFloat
    var style: Style = .type
    var codeSubtitle = true
}

struct Container {
    let name: String
    let stereotype: String
    let frame: CGRect
    var isExternal = false
}

let boxHeight: CGFloat = 70

let client = Node(
    name: "MCP client", stereotype: "external", subtitle: "Claude Code, Desktop", center: .init(x: 95, y: 420), width: 140,
    style: .external, codeSubtitle: false)

let oxusMain = Node(name: "Oxus", stereotype: "@main", subtitle: "Oxus.swift", center: .init(x: 320, y: 185), width: 170)
let stdio = Node(name: "StdioTransport", stereotype: "MCP SDK", subtitle: "stdin, stdout", center: .init(x: 320, y: 420), width: 170)

let makeServer = Node(
    name: "makeOxusServer", stereotype: "func → MCP Server", subtitle: "OxusServer.swift", center: .init(x: 667, y: 185), width: 240)
let oxusTool = Node(
    name: "OxusTool", stereotype: "protocol", subtitle: "OxusTool.swift", center: .init(x: 667, y: 300), width: 180, style: .protocol)
let searchTool = Node(name: "SearchTool", stereotype: "struct", subtitle: "search", center: .init(x: 575, y: 420), width: 170)
let spotlightQueryTool = Node(
    name: "SpotlightQueryTool", stereotype: "struct", subtitle: "spotlight_query", center: .init(x: 760, y: 420), width: 180)
let toolArguments = Node(
    name: "Tool arguments", stereotype: "domain values", subtitle: "Query, NameContains, Kind, Folder, Limit",
    center: .init(x: 662, y: 565),
    width: 340)
let searchCriteria = Node(
    name: "SearchCriteria", stereotype: "struct", subtitle: "SearchCriteria.swift", center: .init(x: 565, y: 655), width: 160)
let privacyProbe = Node(
    name: "PrivacyProtectionProbe", stereotype: "struct", subtitle: "ProtectedFolder.swift", center: .init(x: 745, y: 655), width: 190)
let spotlightPort = Node(
    name: "Spotlight", stereotype: "protocol", subtitle: "Spotlight.swift", center: .init(x: 945, y: 420), width: 150, style: .protocol)
let fileSystemPort = Node(
    name: "FileSystem", stereotype: "protocol", subtitle: "FileSystem.swift", center: .init(x: 945, y: 655), width: 150, style: .protocol)

let coreServicesSpotlight = Node(
    name: "CoreServicesSpotlight", stereotype: "struct", subtitle: "CoreServicesSpotlight.swift", center: .init(x: 1165, y: 420), width: 196
)
let localFileSystem = Node(
    name: "LocalFileSystem", stereotype: "struct", subtitle: "LocalFileSystem.swift", center: .init(x: 1165, y: 655), width: 196)

let spotlightIndex = Node(
    name: "Spotlight index", stereotype: "macOS", subtitle: "MDQuery", center: .init(x: 1390, y: 420), width: 150, style: .external)
let fileSystem = Node(
    name: "File system", stereotype: "macOS", subtitle: "FileManager, TCC", center: .init(x: 1390, y: 655), width: 150, style: .external)

let nodes = [
    client, oxusMain, stdio, makeServer, oxusTool, searchTool, spotlightQueryTool, toolArguments, searchCriteria, privacyProbe,
    spotlightPort, fileSystemPort, coreServicesSpotlight, localFileSystem, spotlightIndex, fileSystem,
]

let containers = [
    Container(name: "oxus", stereotype: "executable", frame: .init(x: 215, y: 95, width: 210, height: 625)),
    Container(name: "OxusServer", stereotype: "library", frame: .init(x: 465, y: 95, width: 480, height: 625)),
    Container(name: "MacOSAdapters", stereotype: "library", frame: .init(x: 1060, y: 95, width: 210, height: 625)),
    Container(name: "macOS", stereotype: "outside oxus", frame: .init(x: 1305, y: 95, width: 170, height: 625), isExternal: true),
]
let domainPanel = CGRect(x: 480, y: 497, width: 370, height: 210)

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: rep)!
let cg = context.cgContext
cg.scaleBy(x: scale, y: scale)
cg.translateBy(x: 0, y: height)
cg.scaleBy(x: 1, y: -1)
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

let ink = NSColor(calibratedWhite: 0.15, alpha: 1)
let muted = NSColor(calibratedWhite: 0.45, alpha: 1)
let protocolFill = NSColor(calibratedRed: 0.89, green: 0.93, blue: 0.99, alpha: 1)
let protocolStroke = NSColor(calibratedRed: 0.22, green: 0.40, blue: 0.75, alpha: 1)
let containerFill = NSColor(calibratedWhite: 0.955, alpha: 1)
let panelFill = NSColor(calibratedWhite: 0.985, alpha: 1)
let italic = NSFontManager.shared.convert(.systemFont(ofSize: 12), toHaveTrait: .italicFontMask)
let labelFont = NSFont.systemFont(ofSize: 11)

NSColor.white.setFill()
CGRect(x: 0, y: 0, width: width, height: height).fill()

func size(of text: String, font: NSFont) -> CGSize {
    text.size(withAttributes: [.font: font])
}

func draw(_ text: String, font: NSFont, color: NSColor, centeredAt point: CGPoint) {
    let textSize = size(of: text, font: font)
    text.draw(
        at: CGPoint(x: point.x - textSize.width / 2, y: point.y - textSize.height / 2),
        withAttributes: [.font: font, .foregroundColor: color])
}

func draw(_ text: String, font: NSFont, color: NSColor, leftAt point: CGPoint) {
    let textSize = size(of: text, font: font)
    text.draw(at: CGPoint(x: point.x, y: point.y - textSize.height / 2), withAttributes: [.font: font, .foregroundColor: color])
}

func label(_ text: String, centeredAt point: CGPoint, on background: NSColor) {
    let textSize = size(of: text, font: labelFont)
    background.setFill()
    CGRect(x: point.x - textSize.width / 2 - 3, y: point.y - textSize.height / 2, width: textSize.width + 6, height: textSize.height).fill()
    draw(text, font: labelFont, color: muted, centeredAt: point)
}

func dashed(_ path: NSBezierPath) {
    let pattern: [CGFloat] = [6, 4]
    path.setLineDash(pattern, count: pattern.count, phase: 0)
}

draw("oxus architecture", font: .boldSystemFont(ofSize: 22), color: ink, centeredAt: .init(x: width / 2, y: 40))

for container in containers {
    let box = NSBezierPath(roundedRect: container.frame, xRadius: 12, yRadius: 12)
    (container.isExternal ? NSColor.white : containerFill).setFill()
    box.fill()
    (container.isExternal ? muted : ink).setStroke()
    box.lineWidth = 1.5
    if container.isExternal { dashed(box) }
    box.stroke()

    let titleFont = NSFont.boldSystemFont(ofSize: 15)
    let titleOrigin = CGPoint(x: container.frame.minX + 12, y: container.frame.minY + 20)
    draw(container.name, font: titleFont, color: ink, leftAt: titleOrigin)
    draw(
        "«\(container.stereotype)»", font: italic, color: muted,
        leftAt: .init(x: titleOrigin.x + size(of: container.name, font: titleFont).width + 6, y: titleOrigin.y + 1))
}

let panel = NSBezierPath(roundedRect: domainPanel, xRadius: 8, yRadius: 8)
panelFill.setFill()
panel.fill()
muted.setStroke()
panel.lineWidth = 1
dashed(panel)
panel.stroke()
draw("domain, used by the tools", font: italic, color: muted, leftAt: .init(x: domainPanel.minX + 10, y: domainPanel.minY + 14))

func polyline(_ points: [CGPoint]) {
    let line = NSBezierPath()
    line.lineWidth = 1.5
    line.move(to: points[0])
    for point in points.dropFirst() { line.line(to: point) }
    ink.setStroke()
    line.stroke()
}

func unit(from start: CGPoint, to end: CGPoint) -> CGPoint {
    let dx = end.x - start.x
    let dy = end.y - start.y
    let length = (dx * dx + dy * dy).squareRoot()
    return .init(x: dx / length, y: dy / length)
}

func openHead(at tip: CGPoint, from previous: CGPoint) {
    let d = unit(from: previous, to: tip)
    let back = CGPoint(x: tip.x - d.x * 10, y: tip.y - d.y * 10)
    polyline([.init(x: back.x - d.y * 5, y: back.y + d.x * 5), tip, .init(x: back.x + d.y * 5, y: back.y - d.x * 5)])
}

func uses(_ points: [CGPoint]) {
    polyline(points)
    openHead(at: points[points.count - 1], from: points[points.count - 2])
}

let hollowLength: CGFloat = 14

func hollowHead(at tip: CGPoint, from previous: CGPoint) {
    let d = unit(from: previous, to: tip)
    let back = CGPoint(x: tip.x - d.x * hollowLength, y: tip.y - d.y * hollowLength)
    let head = NSBezierPath()
    head.move(to: tip)
    head.line(to: .init(x: back.x - d.y * 9, y: back.y + d.x * 9))
    head.line(to: .init(x: back.x + d.y * 9, y: back.y - d.x * 9))
    head.close()
    NSColor.white.setFill()
    head.fill()
    head.lineWidth = 1.5
    ink.setStroke()
    head.stroke()
}

func conforms(_ start: CGPoint, to tip: CGPoint) {
    let d = unit(from: start, to: tip)
    polyline([start, .init(x: tip.x - d.x * hollowLength, y: tip.y - d.y * hollowLength)])
    hollowHead(at: tip, from: start)
}

func left(_ node: Node) -> CGFloat { node.center.x - node.width / 2 }
func right(_ node: Node) -> CGFloat { node.center.x + node.width / 2 }
func top(_ node: Node) -> CGFloat { node.center.y - boxHeight / 2 }
func bottom(_ node: Node) -> CGFloat { node.center.y + boxHeight / 2 }

// The client and the transport exchange messages both ways.
uses([.init(x: right(client), y: 420), .init(x: left(stdio), y: 420)])
openHead(at: .init(x: right(client), y: 420), from: .init(x: left(stdio), y: 420))

uses([.init(x: 320, y: bottom(oxusMain)), .init(x: 320, y: top(stdio))])
uses([.init(x: right(oxusMain), y: 170), .init(x: left(makeServer), y: 170)])
uses([.init(x: right(stdio), y: 420), .init(x: 445, y: 420), .init(x: 445, y: 205), .init(x: left(makeServer), y: 205)])
uses([.init(x: 667, y: bottom(makeServer)), .init(x: 667, y: top(oxusTool))])

let toolsBusY = (bottom(oxusTool) + hollowLength + top(searchTool)) / 2
polyline([.init(x: searchTool.center.x, y: top(searchTool)), .init(x: searchTool.center.x, y: toolsBusY)])
polyline([.init(x: spotlightQueryTool.center.x, y: top(spotlightQueryTool)), .init(x: spotlightQueryTool.center.x, y: toolsBusY)])
polyline([.init(x: searchTool.center.x, y: toolsBusY), .init(x: spotlightQueryTool.center.x, y: toolsBusY)])
conforms(.init(x: 667, y: toolsBusY), to: .init(x: 667, y: bottom(oxusTool)))

uses([.init(x: right(spotlightQueryTool), y: 420), .init(x: left(spotlightPort), y: 420)])

// SearchTool needs both ports, so one trunk forks to each.
let fork = CGPoint(x: 900, y: 478)
polyline([.init(x: searchTool.center.x, y: bottom(searchTool)), .init(x: searchTool.center.x, y: fork.y), fork])
uses([fork, .init(x: fork.x, y: bottom(spotlightPort))])
uses([fork, .init(x: 925, y: fork.y), .init(x: 925, y: top(fileSystemPort))])
ink.setFill()
NSBezierPath(ovalIn: CGRect(x: fork.x - 3.5, y: fork.y - 3.5, width: 7, height: 7)).fill()

uses([.init(x: right(privacyProbe), y: 655), .init(x: left(fileSystemPort), y: 655)])

conforms(.init(x: left(coreServicesSpotlight), y: 420), to: .init(x: right(spotlightPort), y: 420))
conforms(.init(x: left(localFileSystem), y: 655), to: .init(x: right(fileSystemPort), y: 655))
uses([.init(x: right(coreServicesSpotlight), y: 420), .init(x: left(spotlightIndex), y: 420)])
uses([.init(x: right(localFileSystem), y: 655), .init(x: left(fileSystem), y: 655)])

for node in nodes {
    let rect = CGRect(x: left(node), y: top(node), width: node.width, height: boxHeight)
    let box = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
    (node.style == .protocol ? protocolFill : NSColor.white).setFill()
    box.fill()
    switch node.style {
    case .protocol:
        protocolStroke.setStroke()
        box.lineWidth = 2
    case .type:
        ink.setStroke()
        box.lineWidth = 1.5
    case .external:
        muted.setStroke()
        box.lineWidth = 1.5
        dashed(box)
    }
    box.stroke()

    draw(
        "«\(node.stereotype)»", font: italic, color: node.style == .protocol ? protocolStroke : muted,
        centeredAt: .init(x: node.center.x, y: node.center.y - 19))
    draw(node.name, font: .boldSystemFont(ofSize: 15), color: ink, centeredAt: node.center)
    draw(
        node.subtitle, font: node.codeSubtitle ? .monospacedSystemFont(ofSize: 11, weight: .regular) : .systemFont(ofSize: 11),
        color: muted, centeredAt: .init(x: node.center.x, y: node.center.y + 19))
}

label("JSON-RPC", centeredAt: .init(x: 200, y: 394), on: .white)
label("over stdio", centeredAt: .init(x: 200, y: 407), on: .white)
label("creates", centeredAt: .init(x: 320, y: 300), on: containerFill)
label("calls with the adapters", centeredAt: .init(x: 476, y: 156), on: .white)
label("messages", centeredAt: .init(x: 506, y: 190), on: containerFill)
draw("dispatches tools/call", font: labelFont, color: muted, leftAt: .init(x: 677, y: 242))

draw(
    "Open arrow: uses.  Hollow arrow: conforms to the protocol it points to.  Blue: protocols; Spotlight and FileSystem are the ports of OxusServer.",
    font: .systemFont(ofSize: 13), color: muted, centeredAt: .init(x: width / 2, y: 752))
draw(
    "Dependencies point inward: MacOSAdapters implements the ports, and OxusServer imports neither MacOSAdapters nor CoreServices.",
    font: .systemFont(ofSize: 13), color: muted, centeredAt: .init(x: width / 2, y: 776))

NSGraphicsContext.current = nil
let output = CommandLine.arguments[1]
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
