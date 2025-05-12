import SwiftUI

struct TextStyleAttributesReader<Content: View>: View {
  @Environment(\.textStyle) private var textStyle

  private let content: (AttributeContainer) -> Content

  init(@ViewBuilder content: @escaping (_ attributes: AttributeContainer) -> Content) {
    self.content = content
  }

  var body: some View {
    self.content(self.attributes)
//          .fixedSize(horizontal: false, vertical: true) // Commit ef2bc27 - removed.
  }

  private var attributes: AttributeContainer {
    var attributes = AttributeContainer()
    self.textStyle._collectAttributes(in: &attributes)
    return attributes
  }
}
