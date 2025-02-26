//
//  SiderMarkdown.swift
//  swift-markdown-ui
//
//  Created by Avery on 2025/2/21.
//

import Foundation

public enum SiderMarkdown {
    public static let referenceScheme = "reference"
    
}

extension SiderMarkdown {
    static func preprocessMarkdown(_ text: String) -> String {
        var result = LatexParser.preprocess(in: text)
        replaceSerialNumberToLink(&result)
        return result
    }
    
    private static func replaceSerialNumberToLink(_ markdown: inout String) {
        let options: NSRegularExpression.Options = [.caseInsensitive]
        let pattern = #"(?:(?:【\^|【C_|\^【)(\d{1,2})】|(?:\[\^|\[C_|\^\[)(\d{1,2})\])"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            assertionFailure("正则表达式不正确")
            return
        }
        let range = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        markdown = regex.stringByReplacingMatches(in: markdown, range: range, withTemplate: "[$1$2](\(referenceScheme)://$1$2)")
    }
}
