import SwiftUI

extension Sequence where Element == InlineNode {
    func renderText(
        baseURL: URL?,
        textStyles: InlineTextStyles,
        images: [String: Image],
        latexImages: [String: (Image, CGSize)],
        softBreakMode: SoftBreak.Mode,
        attributes: AttributeContainer
    ) -> Text {
        var renderer = TextInlineRenderer(
            baseURL: baseURL,
            textStyles: textStyles,
            images: images,
            latexImages: latexImages,
            softBreakMode: softBreakMode,
            attributes: attributes
        )
        renderer.render(self)
        return renderer.result
    }
}

private struct TextInlineRenderer {
    var result = Text("")
    
    private let baseURL: URL?
    private let textStyles: InlineTextStyles
    private let images: [String: Image]
    private let latexImages: [String: (Image, CGSize)]
    private let softBreakMode: SoftBreak.Mode
    private let attributes: AttributeContainer
    private var shouldSkipNextWhitespace = false
    
    init(
        baseURL: URL?,
        textStyles: InlineTextStyles,
        images: [String: Image],
        latexImages: [String: (Image, CGSize)],
        softBreakMode: SoftBreak.Mode,
        attributes: AttributeContainer
    ) {
        self.baseURL = baseURL
        self.textStyles = textStyles
        self.images = images
        self.softBreakMode = softBreakMode
        self.attributes = attributes
        self.latexImages = latexImages
    }
    
    mutating func render<S: Sequence>(_ inlines: S) where S.Element == InlineNode {
        for inline in inlines {
            self.render(inline)
        }
    }
    
    private mutating func render(_ inline: InlineNode) {
        switch inline {
        case .text(let content):
            self.renderText(content)
        case .softBreak:
            self.renderSoftBreak()
        case .html(let content):
            self.renderHTML(content)
        case .image(let source, _):
            self.renderImage(source)
        case .latex(_, let nodes):
            nodes.forEach { latexNode in
                switch latexNode {
                case .text(let text):
                    self.renderText(text)
                case .latex(let content, _):
                    self.renderLatex(content)
                }
            }
        case .strong(let nodes), .emphasis(let nodes), .strikethrough(let nodes):
            let isContains = nodes.contains { node in
                switch node {
                case .latex: return true
                default: return false
                }
            }
            if isContains {
                nodes.forEach { node in
                    switch node {
                    case .latex:
                        render(node)
                    default:
                        self.defaultRender(node)
                    }
                }
            } else {
                self.defaultRender(inline)
            }
        default:
            self.defaultRender(inline)
        }
    }
    
    private mutating func renderText(_ text: String) {
        var text = text
        
        if self.shouldSkipNextWhitespace {
            self.shouldSkipNextWhitespace = false
            text = text.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
        }
        
        self.defaultRender(.text(text))
    }
    
    private mutating func renderSoftBreak() {
        switch self.softBreakMode {
        case .space where self.shouldSkipNextWhitespace:
            self.shouldSkipNextWhitespace = false
        case .space:
            self.defaultRender(.softBreak)
        case .lineBreak:
            self.shouldSkipNextWhitespace = true
            self.defaultRender(.lineBreak)
        }
    }
    
    private mutating func renderLatex(_ latex: String) {
        if let image = self.latexImages[latex] {
            let fontSize = (attributes.fontProperties?.size ?? 16)
            let height = image.1.height
            var baselineOffset = height / 3
            if height <= fontSize {
                baselineOffset = 0
            }
            self.result = self.result + Text(image.0.renderingMode(.template).antialiased(true).interpolation(.high)) .baselineOffset(-baselineOffset)
        } else {
            self.result = self.result + Text(latex).foregroundColor(Color.clear)
        }
    }
    
    private mutating func renderHTML(_ html: String) {
        let tag = HTMLTag(html)
        
        switch tag?.name.lowercased() {
        case "br":
            self.defaultRender(.lineBreak)
            self.shouldSkipNextWhitespace = true
        default:
            self.defaultRender(.html(html))
        }
    }
    
    private mutating func renderImage(_ source: String) {
        if let image = self.images[source] {
            self.result = self.result + Text(image)
        }
    }
    
    private mutating func defaultRender(_ inline: InlineNode) {
        self.result =
        self.result
        + Text(
            inline.renderAttributedString(
                baseURL: self.baseURL,
                textStyles: self.textStyles,
                softBreakMode: self.softBreakMode,
                attributes: self.attributes
            )
        )
    }
}
