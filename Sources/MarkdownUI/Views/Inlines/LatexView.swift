//
//  SwiftUIView.swift
//  swift-markdown-ui
//
//  Created by 唐海 on 11/5/24.
//

import SwiftUI

struct LatexView: View {
    @Environment(\.theme) private var theme
    @Environment(\.textStyle) private var textStyle
    @State var image: UIImage?
    let content: String
    
    private var attributes: AttributeContainer {
      var attributes = AttributeContainer()
      self.textStyle._collectAttributes(in: &attributes)
      return attributes
    }
    
    var fontSize: CGFloat {
        attributes.fontProperties?.size ?? 16
    }
    
    var cacheImage: UIImage? {
        if image != nil { return image }
        return SVGCache.shared.read(key: content, fontSize: fontSize)
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            if let image = cacheImage {
                Image(uiImage: image).renderingMode(.template)
             } else {
                Text(AttributedString(content, attributes: attributes))
                    .hidden()
            }
        }
        .task(id: content, {
            await readImage(content: content)
        })
    }
    
    func readImage(content: String) async {
        guard cacheImage == nil else {
            if cacheImage != image {
                image = cacheImage
            }
            return
        }
        if SVGCache.shared.canKey(key: content) {
            do {
                let image = try await LatexRenderer.image(with: content, fontSize: fontSize)
                if content == self.content {
                    self.image = image
                }
            } catch let error {
                debugPrint(error)
            }
        }
    }
}
