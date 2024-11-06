//
//  File.swift
//  swift-markdown-ui
//
//  Created by 唐海 on 11/6/24.
//

import Foundation

class LatexValidator {
    // LaTeX 常用命令列表
    static let latexCommands = [
        "\\frac", "\\sqrt", "\\sum", "\\int", "\\prod",
        "\\alpha", "\\beta", "\\gamma", "\\delta", "\\theta",
        "\\pi", "\\sigma", "\\omega", "\\infty", "\\partial",
        "\\left", "\\right", "\\begin", "\\end", "\\text",
        "\\mathbf", "\\mathrm", "\\times", "\\div", "\\pm",
        "\\leq", "\\geq", "\\neq", "\\approx", "\\cdot", "\\boxed", "\\dfrac"
    ]
    
    // 数学公式中允许的特殊字符
    static let allowedSpecialChars = Set<Character>([
        "+", "-", "*", "/", "=", ">", "<", "±", "∑", "∫",
        "≠", "≈", "≤", "≥", "∞", "∂", "→", "←", "↑", "↓",
        "^", "_", "(", ")", "[", "]", "{", "}", "\\", ".",
        "|", "′", "″", "‴", "!", " ", "2", "3", "4", "5",
        "6", "7", "8", "9", "0", "1"  // 允许数字作为公式的一部分
    ])
    
    static func isMathFormula(_ text: String) -> Bool {
        // 去掉首尾的 $ 符号
        let formula = text.trimmingCharacters(in: CharacterSet(charactersIn: "$"))
        
        // 如果字符串全是数字和普通文本，不是数学公式
        let hasOnlyNumbersAndText = formula.allSatisfy { char in
            char.isNumber || char.isLetter || char == " " || char == "," || char == "." || char == "。" || char == "，"
        }
        if hasOnlyNumbersAndText {
            return false
        }
        
        // 1. 检查是否包含 LaTeX 命令
        let hasLatexCommand = latexCommands.contains { formula.contains($0) }
        
        // 2. 分析字符串中的各个部分
        var currentVariable = ""
        var inBraces = false
        var hasInvalidChar = false
        var hasLetter = false
        var hasMathOperator = false
        
        for char in formula {
            if char == "{" {
                inBraces = true
                continue
            } else if char == "}" {
                inBraces = false
                continue
            }
            
            // 如果在花括号内，继续下一个字符
            if inBraces {
                continue
            }
            
            // 检查是否包含数学运算符
            if ["+", "-", "*", "/", "=", "<", ">", "±", "≠", "≈", "≤", "≥"].contains(char) {
                hasMathOperator = true
            }
            
            if char.isLetter {
                hasLetter = true
                currentVariable.append(char)
            } else {
                // 检查变量长度
                if currentVariable.count > 7 {
                    return false
                }
                currentVariable = ""
                
                // 检查非字母字符是否合法
                if !allowedSpecialChars.contains(char) {
                    hasInvalidChar = true
                    break
                }
            }
        }
        
        // 检查最后一个变量的长度
        if currentVariable.count > 7 {
            return false
        }
        
        // 如果有非法字符且不在花括号内，则不是公式
        if hasInvalidChar {
            return false
        }
        
        // 必须满足以下条件之一：
        // 1. 包含 LaTeX 命令
        // 2. 包含数学运算符和字母（变量）
        return hasLatexCommand || (hasMathOperator && hasLetter)
    }
}
