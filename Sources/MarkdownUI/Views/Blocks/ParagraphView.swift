import SwiftUI
 
struct ParagraphView: View {
    @Environment(\.theme.paragraph) private var paragraph
    @Environment(\.textStyle) private var textStyle

    private let content: [InlineNode]
    
    init(content: String) {
        self.init(
            content: [
                .text(content.hasSuffix("\n") ? String(content.dropLast()) : content)
            ]
        )
    }
    
    init(content: [InlineNode]) {
        self.content = content
    }

    private var attributes: AttributeContainer {
        var attributes = AttributeContainer()
        self.textStyle._collectAttributes(in: &attributes)
        return attributes
    }
    
    var body: some View {
        self.paragraph.makeBody(
            configuration: .init(
                label: .init(self.label),
                content: .init(block: .paragraph(content: self.content))
            )
        )
    }
    
    @ViewBuilder private var label: some View {
        if let imageView = ImageView(content) {
            imageView
        } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
                  let imageFlow = ImageFlow(content)
        {
            imageFlow
        } else {
            InlineText(content, fontSize: attributes.fontProperties?.size ?? 16)
        }
    }
}
