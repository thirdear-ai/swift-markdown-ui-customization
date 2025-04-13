import Foundation

/// A text style that sets the font size.
public struct FontSize: TextStyle {
    private enum Size {
        case points(CGFloat)
        case relative(RelativeSize)
    }
    
    private let size: Size
    
    /// Creates a font size text style that sets the size to a relative value.
    /// - Parameter relativeSize: The relative size of the font.
    public init(_ relativeSize: RelativeSize) {
        self.size = .relative(relativeSize)
    }
    
    /// Creates a font size text style that sets the size to a given value.
    /// - Parameter size: The size of the font measured in points.
    public init(_ size: CGFloat) {
        self.size = .points(size)
    }
    
    public func _collectAttributes(in attributes: inout AttributeContainer) {
        guard var fontProps = attributes.fontProperties else {
            return
        }

        // 保存原始值用于后续比较
        let originalProps = fontProps
        
        switch self.size {
        case .points(let value):
            fontProps.size = value
            fontProps.scale = 1
        case .relative(let relativeSize):
            let value = relativeSize.value
            
            switch relativeSize.unit {
            case .em:
                fontProps.scale *= value
            case .rem:
                fontProps.scale = value
            }
        }
        
        // 只有当属性真正发生变化时才更新
        if fontProps != originalProps {
            attributes.fontProperties = fontProps
        }
    }
    
}
