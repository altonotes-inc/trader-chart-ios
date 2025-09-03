//
//  String+Utils.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/06.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

internal extension String {
    
    subscript(nsRange: NSRange) -> String? {
        if let range = Range(nsRange, in: self) {
            return String(self[range])
        }
        return nil
    }
    
    // 0...3
    subscript(range: CountableClosedRange<Int>) -> String? {
        if self.count <= range.upperBound {
            return nil
        }
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound + 1)
        return String(self[start..<end])
    }
    
    // 0..<3
    subscript(range: CountableRange<Int>) -> String? {
        if self.count < range.upperBound {
            return nil
        }
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
    
    // MARK: - Other
    
    // 3...
    func substring(from: Int) -> String? {
        if self.count < from || from < 0 {
            return nil
        }
        let start = index(startIndex, offsetBy: from)
        let end = index(startIndex, offsetBy: self.count)
        return String(self[start..<end])
    }
    
    // ...3
    func substring(to: Int) -> String? {
        if self.count < to || to < 0 {
            return nil
        }
        let start = index(startIndex, offsetBy: 0)
        let end = index(startIndex, offsetBy: to)
        return String(self[start..<end])
    }
    
    // fromで指定されたindexからlength分の文字列を切り出す
    func substring(from: Int, length: Int) -> String? {
        if self.count < from || self.count < from + length || from < 0 || length < 0 {
            return nil
        }
        let start = index(startIndex, offsetBy: from)
        let end = index(startIndex, offsetBy: from + length)
        return String(self[start..<end])
    }
    
    // 空でなければtrue
    var isNotEmpty: Bool {
        return !isEmpty
    }
    
    // 対象の文字列を削除する
    func remove(_ item: String) -> String {
        return replacingOccurrences(of: item, with: "")
    }
    
    // 指定した文字列を先頭から削除した文字列を返す。
    // 指定した文字列が先頭にない場合は元の文字列を返す。
    func removePrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
    
    // 指定した文字列を末尾から削除する。
    // 指定した文字列が末尾にない場合は元の文字列を返す。
    func removeSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }
    
    // 空文字、改行をトリムする
    func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // 文字列をDoubleに変換する。数値でない場合は0になる
    var doubleValue: Double {
        return (self as NSString).doubleValue
    }
    
    // 文字列をCGFloatに変換する。数値でない場合は0になる
    var floatValue: CGFloat {
        return CGFloat((self as NSString).doubleValue)
    }
    
    // 文字列をIntに変換する。数値でない場合は0になる
    var integerValue: Int {
        return (self as NSString).integerValue
    }
    
    // 数字を3桁カンマ区切りにした文字列を返す
    // 連続した数字のみカンマ区切りにし、数字以外の文字は無視する
    // ex. "AAA(1234)BBB(5678)" → "AAA(1,234)BBB(5,678)"
    var numberFormat: String {
        var text = self

        // +-はいったん取り除いて後で復元
        var sign: String? = nil
        if text.hasPrefix("+") {
            sign = "+"
            text = text.removePrefix("+")
        } else if text.hasPrefix("-") {
            sign = "-"
            text = text.removePrefix("-")
        }

        let numbers = text.components(separatedBy: ".")
        let number = numbers[0]
        let decimal = (1 < numbers.count) ? numbers[1] : nil

        var builder = ""
        var numberIndex = -1
        number.reversed().forEach { c in
            if c.isNumber {
                numberIndex += 1
            } else {
                numberIndex = -1
            }
            if 0 < numberIndex && numberIndex % 3 == 0 {
                builder.append(",")
            }
            builder.append(c)
        }
        builder = String(builder.reversed())

        if let sign = sign {
            builder = sign + builder
        }

        if let decimal = decimal {
            builder.append(".")
            builder.append(decimal)
        }

        return builder
    }
    
    // 数字を+-符号付き3桁カンマ区切りにした文字列を返す
    // ex. "+123456.789" -> "+123,456.789"
    // ex. "-123456.789" -> "-123,456.789"
    // ex. "-0.00" -> "0.00"
    var signedNumberFormat: String {
        let result = removePrefix("+").removePrefix("-")
        let doubleValue = self.doubleValue
        var sign = ""
        if 0 < doubleValue {
            sign = "+"
        } else if doubleValue < 0 {
            sign = "-"
        }
        return sign + result.numberFormat
    }
    
    // 指定した桁まで文字列の右側を特定の文字で埋める
    // 指定桁を超えている場合は何もしない
    func rightPadded(size: Int, spacer: String = " ") -> String {
        var result = self
        let add = size - count
        if 0 < add {
            (0..<add).forEach {_ in
                result += spacer
            }
        }
        return result
    }
    
    // 指定した桁まで文字列の左側を特定の文字で埋める
    // 指定桁を超えている場合は何もしない
    func leftPadded(size: Int, spacer: String = " ") -> String {
        var result = self
        let add = size - count
        if 0 < add {
            (0..<add).forEach {_ in
                result = spacer + result
            }
        }
        return result
    }
    
    // NSDecimalNumberを取得する
    var decimalNumber: NSDecimalNumber? {
        let decimalNumber = NSDecimalNumber(string: self)
        return decimalNumber == NSDecimalNumber.notANumber ? nil : decimalNumber
    }
    
}

internal extension Optional where Wrapped == String {
    
    // 空を置き換えた値を返す
    func emptyConverted(_ emptyMark: String) -> String {
        if let value = self, value.isNotEmpty {
            return value
        }
        return emptyMark
    }
}
