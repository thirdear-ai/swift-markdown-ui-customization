//
//  File.swift
//  swift-markdown-ui
//
//  Created by 唐海 on 11/5/24.
//

import Foundation
import MathJaxSwift
import UIKit
import SVGCore

extension LatexRenderer {
    enum RendererError: Error {
        case rendererEmpty
        case latexToSvg(Error)
        case svgToImageFial
        case svgGeometryFial(SVGGeometry.ParsingError)
    }
}

struct LatexRenderer {
    static var renderer: MathJax? = {
      do {
        return try MathJax(preferredOutputFormat: .svg)
      }
      catch {
        debugPrint("Error creating MathJax instance: \(error)")
        return nil
      }
    }()
    private static let outputOptions = SVGOutputProcessorOptions(displayAlign: SVGOutputProcessorOptions.DisplayAlignments.left)
    
    private static let convOptions = ConversionOptions(display: true)
    
    private static let loadPackages: TeXInputProcessorOptions = {
        let packages = TeXInputProcessorOptions.Packages.all
        return TeXInputProcessorOptions(loadPackages: packages)
    }()
    
    @ReadWriteLock
    private static var rendererTask: [String: Task<UIImage, Error>] = [:]
}

extension LatexRenderer {
    
    @MainActor
    static func image(with latex: String, fontSize: CGFloat) async throws -> UIImage {
        let cacheKey = "\(latex)-\(fontSize)"
        if let image = SVGCache.shared.read(key: latex, fontSize: fontSize) {
            return image
        }
        if let task = rendererTask[cacheKey] {
            return try await task.value
        }
        let task = Task.detached {
            do {
                guard let mathjax = LatexRenderer.renderer else { throw RendererError.rendererEmpty }
                let svg: String
                do {
                    svg = try mathjax.tex2svg(
                        latex,
                        conversionOptions: convOptions,
                        inputOptions: loadPackages,
                        outputOptions: outputOptions).replacingOccurrences(of: "\"serif\"", with: "\"PingFang SC\"")
                } catch let error {
                    throw RendererError.latexToSvg(error)
                }
                guard let svgData = svg.data(using: .utf8) else { throw RendererError.rendererEmpty }
                do {
                    let geometry = try SVGGeometry(svg: svg)
                    let width = geometry.width.toPoints(fontSize)
                    let height = geometry.height.toPoints(fontSize)
                    let size = CGSize(width: width, height: height)
                    guard let image = SVGConverter.shared().convertSVG(toImage: svgData, targetSize: size, preserveAspectRatio: true) else { throw RendererError.svgToImageFial }
                    SVGCache.shared.set(key: latex, fontSize: fontSize, image: image)
                    return image
                } catch let error {
                    SVGCache.shared.setError(key: latex)
                    if let parsingError = error as? SVGGeometry.ParsingError {
                        throw RendererError.svgGeometryFial(parsingError)
                    } else {
                        debugPrint(error)
                        assertionFailure()
                        throw RendererError.rendererEmpty
                    }
                }
            } catch let error {
                rendererTask.removeValue(forKey: cacheKey)
                throw error
            }
        }
        rendererTask[cacheKey] = task
        let image = try await task.value
        rendererTask.removeValue(forKey: cacheKey)
        return image
     }
}
