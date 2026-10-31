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

// Run from the repository root: swift docs/diagrams/tool-argument-hierarchy.swift docs/diagrams/tool-argument-hierarchy.png

import AppKit

let width: CGFloat = 1000
let height: CGFloat = 520
let scale: CGFloat = 2

struct Node {
    let name: String
    let stereotype: String
    let file: String
    let center: CGPoint
    let width: CGFloat
    var isProtocol: Bool { stereotype == "protocol" }
}

let boxHeight: CGFloat = 78

let toolArgument = Node(name: "ToolArgument", stereotype: "protocol", file: "ToolArgument.swift", center: .init(x: 560, y: 110), width: 220)
let nonEmpty = Node(
    name: "NonEmptyStringArgument", stereotype: "protocol", file: "NonEmptyStringArgument.swift", center: .init(x: 345, y: 270), width: 250)
let limitArgument = Node(name: "LimitArgument", stereotype: "struct", file: "Limit.swift", center: .init(x: 640, y: 270), width: 170)
let kindArgument = Node(name: "KindArgument", stereotype: "struct", file: "Kind.swift", center: .init(x: 840, y: 270), width: 170)
let queryArgument = Node(name: "QueryArgument", stereotype: "struct", file: "Query.swift", center: .init(x: 125, y: 430), width: 210)
let nameContainsArgument = Node(
    name: "NameContainsArgument", stereotype: "struct", file: "NameContains.swift", center: .init(x: 345, y: 430), width: 210)
let folderArgument = Node(name: "FolderArgument", stereotype: "struct", file: "Folder.swift", center: .init(x: 565, y: 430), width: 210)

let nodes = [toolArgument, nonEmpty, limitArgument, kindArgument, queryArgument, nameContainsArgument, folderArgument]
let edges: [(parent: Node, children: [Node])] = [
    (toolArgument, [nonEmpty, limitArgument, kindArgument]),
    (nonEmpty, [queryArgument, nameContainsArgument, folderArgument]),
]

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
let typeFill = NSColor(calibratedWhite: 0.97, alpha: 1)

NSColor.white.setFill()
CGRect(x: 0, y: 0, width: width, height: height).fill()

func draw(_ text: String, font: NSFont, color: NSColor, centeredAt point: CGPoint) {
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let size = text.size(withAttributes: attributes)
    text.draw(at: CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2), withAttributes: attributes)
}

draw("ToolArgument hierarchy", font: .boldSystemFont(ofSize: 22), color: ink, centeredAt: .init(x: width / 2, y: 36))

func top(_ node: Node) -> CGFloat { node.center.y - boxHeight / 2 }
func bottom(_ node: Node) -> CGFloat { node.center.y + boxHeight / 2 }

let arrowSize: CGFloat = 14
ink.setStroke()
for (parent, children) in edges {
    let busY = (bottom(parent) + arrowSize + top(children[0])) / 2
    let line = NSBezierPath()
    line.lineWidth = 1.5
    for child in children {
        line.move(to: .init(x: child.center.x, y: top(child)))
        line.line(to: .init(x: child.center.x, y: busY))
    }
    let xs = children.map(\.center.x) + [parent.center.x]
    line.move(to: .init(x: xs.min()!, y: busY))
    line.line(to: .init(x: xs.max()!, y: busY))
    line.move(to: .init(x: parent.center.x, y: busY))
    line.line(to: .init(x: parent.center.x, y: bottom(parent) + arrowSize))
    line.stroke()

    let head = NSBezierPath()
    head.move(to: .init(x: parent.center.x, y: bottom(parent)))
    head.line(to: .init(x: parent.center.x - arrowSize / 2 - 2, y: bottom(parent) + arrowSize))
    head.line(to: .init(x: parent.center.x + arrowSize / 2 + 2, y: bottom(parent) + arrowSize))
    head.close()
    NSColor.white.setFill()
    head.fill()
    head.lineWidth = 1.5
    head.stroke()
}

for node in nodes {
    let rect = CGRect(x: node.center.x - node.width / 2, y: top(node), width: node.width, height: boxHeight)
    let box = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
    (node.isProtocol ? protocolFill : typeFill).setFill()
    box.fill()
    (node.isProtocol ? protocolStroke : ink).setStroke()
    box.lineWidth = node.isProtocol ? 2 : 1.5
    box.stroke()

    let italic = NSFontManager.shared.convert(.systemFont(ofSize: 12), toHaveTrait: .italicFontMask)
    draw(
        "«\(node.stereotype)»", font: italic, color: node.isProtocol ? protocolStroke : muted,
        centeredAt: .init(x: node.center.x, y: node.center.y - 20))
    draw(node.name, font: .boldSystemFont(ofSize: 16), color: ink, centeredAt: node.center)
    draw(
        node.file, font: .monospacedSystemFont(ofSize: 11, weight: .regular), color: muted,
        centeredAt: .init(x: node.center.x, y: node.center.y + 21))
}

draw(
    "A hollow arrow points to the protocol a type conforms to, or that a protocol inherits from.", font: .systemFont(ofSize: 13),
    color: muted, centeredAt: .init(x: width / 2, y: height - 24))

NSGraphicsContext.current = nil
let output = CommandLine.arguments[1]
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
