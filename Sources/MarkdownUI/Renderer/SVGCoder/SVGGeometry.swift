//
//  SVGGeometry.swift
//  LaTeXSwiftUI
//
//  Copyright (c) 2023 Colin Campbell
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
internal typealias _Image = UIImage
internal typealias _Font = UIFont
internal typealias _Color = UIColor
#else
import Cocoa
internal typealias _Image = NSImage
internal typealias _Font = NSFont
internal typealias _Color = NSColor
#endif

/// The geometry of a SVG.
struct SVGGeometry: Codable {
    
    // MARK: Types
    
    typealias XHeight = CGFloat
    
    enum ParsingError: Error {
        case missingSVGElement
        case missingGeometry
    }
    
    // MARK: Static properties
    
    private static let svgRegex = try! NSRegularExpression(pattern: "<svg.*?>", options: [])
    private static let attributeRegex = try! NSRegularExpression(pattern: "\\w*:*\\w+=\".*?\"", options: [])
    
    // MARK: Public properties
    
    let verticalAlignment: XHeight
    let width: XHeight
    let height: XHeight
    let frame: CGRect
    
    // MARK: Initializers
    
    init(svg: String) throws {
        let range = NSRange(svg.startIndex..<svg.endIndex, in: svg)
        
        guard let svgMatch = SVGGeometry.svgRegex.firstMatch(in: svg, options: [], range: range) else {
            throw ParsingError.missingSVGElement
        }
        
        let svgElementRange = Range(svgMatch.range, in: svg)!
        let svgElement = String(svg[svgElementRange])
        
        var verticalAlignment: XHeight?
        var width: XHeight?
        var height: XHeight?
        var frame: CGRect?
        
        let attributeMatches = SVGGeometry.attributeRegex.matches(in: svgElement, options: [], range: NSRange(svgElement.startIndex..<svgElement.endIndex, in: svgElement))
        
        for match in attributeMatches {
            let attributeRange = Range(match.range, in: svgElement)!
            let attribute = String(svgElement[attributeRange])
            let components = attribute.components(separatedBy: "=")
            guard components.count == 2 else { continue }
            
            switch components[0] {
            case "style": verticalAlignment = SVGGeometry.parseAlignment(from: components[1])
            case "width": width = SVGGeometry.parseXHeight(from: components[1])
            case "height": height = SVGGeometry.parseXHeight(from: components[1])
            case "viewBox": frame = SVGGeometry.parseViewBox(from: components[1])
            default: continue
            }
        }
        
        guard let unwrappedVerticalAlignment = verticalAlignment, let unwrappedWidth = width, let unwrappedHeight = height, let unwrappedFrame = frame else {
            throw ParsingError.missingGeometry
        }
        
        self.verticalAlignment = unwrappedVerticalAlignment
        self.width = unwrappedWidth
        self.height = unwrappedHeight
        self.frame = unwrappedFrame
    }
    
}

// MARK: Static methods

extension SVGGeometry {
    
    /// Parses the alignment from the style attribute.
    ///
    /// "vertical-align: -1.602ex;"
    ///
    /// - Parameter string: The input string.
    /// - Returns: The alignment's x-height.
    static func parseAlignment(from string: String) -> XHeight? {
        let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\";"))
        let components = trimmed.components(separatedBy: CharacterSet(charactersIn: ":"))
        guard components.count == 2 else { return nil }
        let value = components[1].trimmingCharacters(in: .whitespaces)
        return XHeight(stringValue: value)
    }
    
    /// Parses the x-height value from an attribute.
    ///
    /// "2.127ex"
    ///
    /// - Parameter string: The input string.
    /// - Returns: The x-height.
    static func parseXHeight(from string: String) -> XHeight? {
        let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        return XHeight(stringValue: trimmed)
    }
    
    /// Parses the view-box from an attribute.
    ///
    /// "0 -1342 940 2050"
    ///
    /// - Parameter string: The input string.
    /// - Returns: The view-box.
    static func parseViewBox(from string: String) -> CGRect? {
        let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let components = trimmed.components(separatedBy: CharacterSet.whitespaces)
        guard components.count == 4 else { return nil }
        guard let x = Double(components[0]),
              let y = Double(components[1]),
              let width = Double(components[2]),
              let height = Double(components[3]) else {
            return nil
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
}

extension SVGGeometry.XHeight {
    
    /// Initializes a x-height value.
    ///
    /// "2.127ex"
    ///
    /// - Parameter stringValue: The x-height.
    init?(stringValue: String) {
        let trimmed = stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "ex"))
        if let value = Double(trimmed) {
            self = CGFloat(value)
        }
        else {
            return nil
        }
    }
    
    /// Converts the x-height to points.
    ///
    /// - Parameter xHeight: The height of 1 x-height unit.
    /// - Returns: The points.
    func toPoints(_ xHeight: CGFloat) -> CGFloat {
        xHeight * self * 0.5
    }
    
    /// Converts the x-height to points.
    ///
    /// - Parameter font: The font.
    /// - Returns: The points.
    func toPoints(_ font: _Font) -> CGFloat {
        toPoints(font.xHeight)
    }
    
    /// Converts the x-height to points.
    ///
    /// - Parameter font: The font.
    /// - Returns: The points.
    func toPoints(_ font: Font) -> CGFloat {
#if os(iOS)
        toPoints(_Font.preferredFont(from: font))
#else
        toPoints(_Font.preferredFont(from: font))
#endif
    }
    
}


