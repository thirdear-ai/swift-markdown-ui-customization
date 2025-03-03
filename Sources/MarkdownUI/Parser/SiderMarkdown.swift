//
//  SiderMarkdown.swift
//  swift-markdown-ui
//
//  Created by Avery on 2025/2/21.
//

import Foundation

public enum SiderMarkdown {
    public static let siderLinkPrefix = "sider_"
    
    public static let referenceScheme = "reference"
}

extension SiderMarkdown {
    static func preprocessMarkdown(_ text: String) -> String {
        var result = LatexParser.preprocess(in: text)
        // 首先，替换序号链接的情况 [^1](http://...) -> [sider_1](http://...)
        replaceSerialLink(&result)
        // 然后，替换自由序号的情况 [^1] -> [1](reference://)
        replaceSerialNumberToLink(&result)
        return result
    }
    
    private static func replaceSerialLink(_ markdown: inout String) {
        let options: NSRegularExpression.Options = [.caseInsensitive]
        let pattern = #"(?:(?:【\^|【C_|\^【)(\d{1,2})】|(?:\[\^|\[C_|\^\[)(\d{1,2})\])(?=\(.+\:\/\/.+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            assertionFailure("正则表达式不正确")
            return
        }
        let range = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        markdown = regex.stringByReplacingMatches(in: markdown, range: range, withTemplate: "[\(siderLinkPrefix)$1$2]")
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
