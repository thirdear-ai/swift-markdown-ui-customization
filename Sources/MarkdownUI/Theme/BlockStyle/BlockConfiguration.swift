import SwiftUI

/// The properties of a Markdown block.
///
/// Most theme ``BlockStyle`` instances receive a `BlockConfiguration` input in their
/// `body` closure. The configuration ``BlockConfiguration/label-swift.property``
/// property reflects the block's content.
public struct BlockConfiguration {
  /// A type-erased view of a Markdown block.
  public struct Label: View {
    init<L: View>(_ label: L) {
      self.body = AnyView(label)
    }

    public let body: AnyView
  }

  /// The Markdown block view.
  public let label: Label
    // 列表中第几个
    public var index: Int = 0
    // 列表中总个数
    public var total: Int = 0
    // 当前列表的层级
    public var level: Int = 0

  /// The content of the Markdown block.
  ///
  /// This property provides access to different representations of the block content.
  /// For example, you can use ``MarkdownContent/renderMarkdown()``
  /// to get the Markdown formatted text or ``MarkdownContent/renderPlainText()``
  /// to get the plain text of the block content.
  public let content: MarkdownContent
}
