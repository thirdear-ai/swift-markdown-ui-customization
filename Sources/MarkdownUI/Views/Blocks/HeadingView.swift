import SwiftUI

struct HeadingView: View {
    @Environment(\.theme.headings) private var headings
    @Environment(\.textStyle) private var textStyle
    private let level: Int
    private let content: [InlineNode]
    
    init(level: Int, content: [InlineNode]) {
        self.level = level
        self.content = content
    }
    
    private var attributes: AttributeContainer {
        var attributes = AttributeContainer()
        self.textStyle._collectAttributes(in: &attributes)
        return attributes
    }
    
    var body: some View {
        self.headings[self.level - 1].makeBody(
            configuration: .init(
                label: .init(InlineText(self.content, fontSize: attributes.fontProperties?.size ?? 16)),
                content: .init(block: .heading(level: self.level, content: self.content))
            )
        )
        .id(content.renderPlainText().kebabCased())
    }
}
