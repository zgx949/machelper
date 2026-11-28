#!/usr/bin/env swift
// Rebuild the app's vector-drawn icon assets. Run: xcrun swift scripts/generate-app-icon.swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let assets = root.appendingPathComponent("machelper/Assets.xcassets")
let fileManager = FileManager.default

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

// The two arches form a lowercase m; a small slot in its central stem recalls a mouse wheel.
func drawMark(in context: CGContext, wheelColor: CGColor) {
    let mark = CGMutablePath()
    mark.move(to: CGPoint(x: 292, y: 330))
    mark.addLine(to: CGPoint(x: 292, y: 548))
    mark.addCurve(to: CGPoint(x: 512, y: 548),
                  control1: CGPoint(x: 292, y: 698), control2: CGPoint(x: 512, y: 698))
    mark.addLine(to: CGPoint(x: 512, y: 330))
    mark.move(to: CGPoint(x: 512, y: 548))
    mark.addCurve(to: CGPoint(x: 732, y: 548),
                  control1: CGPoint(x: 512, y: 698), control2: CGPoint(x: 732, y: 698))
    mark.addLine(to: CGPoint(x: 732, y: 330))
    context.setStrokeColor(color(1, 1, 1))
    context.setLineWidth(112)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.addPath(mark)
    context.strokePath()

    context.setStrokeColor(wheelColor)
    context.setLineWidth(24)
    context.move(to: CGPoint(x: 512, y: 437))
    context.addLine(to: CGPoint(x: 512, y: 495))
    context.strokePath()
}

func png(size: Int, template: Bool = false) throws -> Data {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                        isPlanar: false, colorSpaceName: .deviceRGB,
                                        bytesPerRow: 0, bitsPerPixel: 0),
          let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create icon canvas")
    }
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = graphics
    let context = graphics.cgContext
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    context.setAllowsAntialiasing(true)

    if template {
        // Fill the menu-bar canvas while retaining a small optical inset.
        context.translateBy(x: -240, y: -190)
        context.scaleBy(x: 1.46, y: 1.46)
        drawMark(in: context, wheelColor: color(1, 1, 1))
    } else {
        let tile = CGPath(roundedRect: CGRect(x: 64, y: 64, width: 896, height: 896),
                          cornerWidth: 196, cornerHeight: 196, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -12), blur: 22,
                          color: color(0.04, 0.12, 0.31, 0.22))
        context.setFillColor(color(0.20, 0.36, 0.88))
        context.addPath(tile)
        context.fillPath()
        context.restoreGState()

        context.saveGState()
        context.addPath(tile)
        context.clip()
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [color(0.17, 0.69, 0.98), color(0.19, 0.40, 0.94),
                                           color(0.30, 0.27, 0.80)] as CFArray,
                                  locations: [0, 0.52, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 180, y: 960),
                                   end: CGPoint(x: 850, y: 64), options: [])
        context.restoreGState()

        context.addPath(tile)
        context.setLineWidth(2)
        context.setStrokeColor(color(1, 1, 1, 0.24))
        context.strokePath()

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -7), blur: 14,
                          color: color(0.06, 0.15, 0.48, 0.17))
        drawMark(in: context, wheelColor: color(0.19, 0.43, 0.94))
        context.restoreGState()
    }
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode icon PNG")
    }
    return data
}

func writeJSON(_ value: [String: Any], to directory: URL) throws {
    var data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    data.append(0x0a)
    try data.write(to: directory.appendingPathComponent("Contents.json"))
}

let info: [String: Any] = ["author": "xcode", "version": 1]
let iconDirectory = assets.appendingPathComponent("AppIcon.appiconset")
try fileManager.createDirectory(at: iconDirectory, withIntermediateDirectories: true)
var icons: [[String: Any]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let filename = "icon_\(points)x\(points)@\(scale)x.png"
        try png(size: points * scale).write(to: iconDirectory.appendingPathComponent(filename))
        icons.append(["idiom": "mac", "size": "\(points)x\(points)",
                      "scale": "\(scale)x", "filename": filename])
    }
}
try writeJSON(["images": icons, "info": info], to: iconDirectory)

for (name, points, template) in [("AppLogo", 128, false), ("MenuBarIcon", 18, true)] {
    let directory = assets.appendingPathComponent("\(name).imageset")
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    var images: [[String: Any]] = []
    for scale in [1, 2] {
        let filename = "\(name)@\(scale)x.png"
        try png(size: points * scale, template: template).write(to: directory.appendingPathComponent(filename))
        images.append(["idiom": "mac", "scale": "\(scale)x", "filename": filename])
    }
    var contents: [String: Any] = ["images": images, "info": info]
    if template { contents["properties"] = ["template-rendering-intent": "template"] }
    try writeJSON(contents, to: directory)
}
print("Generated AppIcon, AppLogo and MenuBarIcon assets.")
