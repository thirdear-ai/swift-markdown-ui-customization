import SwiftUI

extension View {
  /// Sets the soft break mode for inline texts in a view hierarchy.
  ///
  /// - parameter softBreakMode: If set to `space`, treats all soft breaks as spaces, keeping sentences whole. If set to `lineBreak`, treats soft breaks as full line breaks
  ///
  /// - Returns: A view that uses the specified soft break mode for itself and its child views.
  public func markdownSoftBreakMode(_ softBreakMode: SoftBreak.Mode) -> some View {
    self.environment(\.softBreakMode, softBreakMode)
  }
}

extension EnvironmentValues {
  var softBreakMode: SoftBreak.Mode {
    get { self[SoftBreakModeKey.self] }
    set { self[SoftBreakModeKey.self] = newValue }
  }
}

private struct SoftBreakModeKey: EnvironmentKey {
  static let defaultValue: SoftBreak.Mode = .space
}

//MARK: Commit e65ee7b - removed
//extension View {
//    public func markdownParagraphLineSpacing(_ spacing: CGFloat) -> some View {
//    self.environment(\.paragraphLineSpacing, spacing)
//  }
//}
//
//extension EnvironmentValues {
//    var paragraphLineSpacing: CGFloat {
//    get { self[ParagraphLineSpacingKey.self] }
//    set { self[ParagraphLineSpacingKey.self] = newValue }
//  }
//}
//
//private struct ParagraphLineSpacingKey: EnvironmentKey {
//    static let defaultValue: CGFloat = 0.0
//}
