//
//  File.swift
//  swift-markdown-ui
//
//  Created by 唐海 on 10/31/24.
//

import Foundation

public struct LatexParser {
    let range: Range<String.Index>
    let tag: Substring
}

extension LatexParser {
    
    func isBlock(parser: LatexParser, text: String) -> Bool {
        let latex = text[self.range.upperBound..<parser.range.lowerBound]
        let bool = self.range.lowerBound == text.startIndex && parser.range.upperBound == text.endIndex
        return bool || latex.count > 40
    }
    
    func pairing(parser: LatexParser) -> Bool {
        if self.tag == "$$" && parser.tag == "$$" {
            return true
        }
        if self.tag == "$" && parser.tag == "$" {
            return true
        }
        if self.tag == "\\(" && parser.tag == "\\)" {
            return true
        }
        if self.tag == "\\[" && parser.tag == "\\]" {
            return true
        }
        return false
    }
}

extension LatexParser {
    
    static let latexSpecialCharacters: CharacterSet = {
        return CharacterSet(charactersIn: "{}[]+-*=<>∈∉∋∌∏∑−∓∔∕∗√∝∞∧∨∩∪∫∬∭∮∯∰∱∲∳ℵℏℑℜ℘ℓ∂∇")
    }()

    static let combinedCharacterSet: CharacterSet = {
        return CharacterSet.letters.union(CharacterSet.decimalDigits).union(latexSpecialCharacters)
    }()
    
    static func containsLatexSpecialCharacters(in string: String) -> Bool {
        return string.rangeOfCharacter(from: latexSpecialCharacters) != nil
    }
    
    // 定义一个函数来查找特殊字符的范围
    static func findLatexRanges(in text: String) -> [Range<String.Index>] {
        do {
            // 使用原始字符串定义正则表达式模式
            let pattern = #"\$\$"#
            
            // 编译正则表达式
            let regex = try NSRegularExpression(pattern: pattern)
            
            // 将整个字符串的范围转换为 NSRange
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            
            // 查找所有匹配项
            let matches = regex.matches(in: text, options: [], range: nsRange)
            
            // 将 NSRange 转换为 Range<String.Index>
            return matches.compactMap { match in
                guard let range = Range(match.range, in: text) else { return nil }
                return range
            }
        } catch {
            print("正则表达式错误: \(error)")
            return []
        }
    }
    
    // 定义一个函数来查找特殊字符的范围
    static func findSpecialCharacterRanges(in text: String) -> [Range<String.Index>] {
        do {
            // 使用原始字符串定义正则表达式模式
            let pattern = #"\$\$|\$|\\\(|\\\)|\\\[|\\\]"#
            
            // 编译正则表达式
            let regex = try NSRegularExpression(pattern: pattern)
            
            // 将整个字符串的范围转换为 NSRange
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            
            // 查找所有匹配项
            let matches = regex.matches(in: text, options: [], range: nsRange)
            
            // 将 NSRange 转换为 Range<String.Index>
            return matches.compactMap { match in
                guard let range = Range(match.range, in: text) else { return nil }
                return range
            }
        } catch {
            print("正则表达式错误: \(error)")
            return []
        }
    }
    
    /// 预处理公式中的换行符，避免被识别为多个段落
    /// - Parameter text: 需要处理的字符
    static func preprocess(in text: String) -> String {
        let ranges = findSpecialCharacterRanges(in: text)
        var nextRange: Range<String.Index>?
        var parsers: [(LatexParser, LatexParser)] = []
        for (index, range) in ranges.enumerated() {
            var skip = false
            // 如果当前范围属于被包含在一个公式中就跳过
            if let nextRange = nextRange, nextRange.upperBound > range.lowerBound {
                skip = true
            }
            if skip == false {
                let tag = text[range]
                let item = LatexParser(range: range, tag: tag)
                if index < ranges.count {
                    // 寻找下一个匹配的标记
                    for laterIndex in (index+1)..<ranges.count {
                        let laterRange = ranges[laterIndex]
                        let tag = text[laterRange]
                        let later = LatexParser(range: laterRange, tag: tag)
                        if item.pairing(parser: later) {
                            let latexRange = item.range.upperBound..<later.range.lowerBound
                            let latex = text[latexRange]
                            var valid = true
                            if item.tag == "$" {
                                valid = LatexValidator.isMathFormula(String(latex))
                            }
                            if valid {
                                parsers.append((item, later))
                                nextRange = later.range
                            } else {
                                nextRange = item.range
                            }
                            if valid == false {
                                debugPrint("valid=\(latex)")
                            }
                            break
                        }
                    }
                }
            }
        }
        if parsers.isEmpty == false {
            var text = text
            parsers.reversed().forEach { (head, last) in
                let latexRange = head.range.upperBound..<last.range.lowerBound
                let latex = text[latexRange]
                if head.tag != "$$" {
                    text.replaceSubrange(last.range, with: "$$")
                }
                var newLatex = String(latex)
                if let value = newLatex.data(using: .utf8)?.base64EncodedString() {
                    newLatex = value
                }
                text.replaceSubrange(latexRange, with: newLatex)
                if head.tag != "$$" {
                    text.replaceSubrange(head.range, with: "$$")
                }
            }
            return text
        } else {
            return text
        }
    }
    
    public static func removeNewLinePlaceholder(text: String) -> String {
        if let data = Data(base64Encoded: text) {
            return String(data: data, encoding: .utf8) ?? text
        } else {
            return text
        }
    }
}
