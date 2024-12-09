import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct TableCell: View {
    @Environment(\.theme.tableCell) private var tableCell
    @Environment(\.textStyle) private var textStyle
    private let row: Int
    private let column: Int
    private let cell: RawTableCell
    
    init(row: Int, column: Int, cell: RawTableCell) {
        self.row = row
        self.column = column
        self.cell = cell
    }
    
    private var attributes: AttributeContainer {
        var attributes = AttributeContainer()
        self.textStyle._collectAttributes(in: &attributes)
        return attributes
    }
    
    var body: some View {
        self.tableCell.makeBody(
            configuration: .init(
                row: self.row,
                column: self.column,
                label: .init(self.label),
                content: .init(block: .paragraph(content: cell.content))
            )
        )
        .tableCellBounds(forRow: self.row, column: self.column)
    }
    
    @ViewBuilder private var label: some View {
        if let imageFlow = ImageFlow(self.cell.content) {
            imageFlow
        } else {
            InlineText(self.cell.content, fontSize: attributes.fontProperties?.size ?? 16)
        }
    }
}
