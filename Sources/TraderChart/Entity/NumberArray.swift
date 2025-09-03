//
//  ValueArray.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 数値の配列
open class NumberArray: Sequence {
    private var array: [CGFloat?] = []

    /// ラップする内部数値配列
    open var floatArray: [CGFloat?] {
        return array
    }

    /// 配列の数
    open var count: Int {
        return array.count
    }

    /// 最初の要素
    open var first: CGFloat? {
        return array.first as? CGFloat
    }

    /// 最後の要素
    open var last: CGFloat? {
        return array.last as? CGFloat
    }

    /// 保持するインデックス範囲
    open var indicies: Range<Int> {
        return array.indices
    }

    /// 初期化
    public init() {}

    /// CGFloatの配列を指定して初期化
    public init(array: [CGFloat?]) {
        self.array = array
    }

    /// 固定値と数を指定して初期化
    public init(value: CGFloat?, count: Int) {
        if 0 < count {
            self.array = (1...count).map { _ in value }
        }
    }

    /// インデックスの要素を取得。なければnilを返す
    open subscript(index: Int) -> CGFloat? {
        get {
            if 0 <= index && index < count {
                return array[index]
            }
            return nil
        }
        set(newValue) {
            if 0 <= index && index < count {
                array[index] = newValue
            }
        }
    }

    /// 要素を追加する
    public static func += ( left: inout NumberArray, right: CGFloat?) {
        left.append(right)
    }

    open func makeIterator() -> AnyIterator<CGFloat?> {

        var index = 0
        let limit = array.count

        return AnyIterator {
            if index < limit {
                let nextItem = self.array[index]
                index += 1
                return nextItem
            }
            return nil
        }
    }

    /// 要素を追加する
    open func append(_ value: CGFloat?) {
        array.append(value)
    }

    /// 配列の要素を追加する
    open func append(contentsOf: [CGFloat?]) {
        array.append(contentsOf: contentsOf)
    }
    
    /// 指定した数値の配列の要素を追加する
    open func append(other: NumberArray?) {
        guard let other = other else { return }
        array.append(contentsOf: other.floatArray)
    }

    /// 先頭の指定数の要素を削除する
    func removeFirst(_ count: Int) {
        let count = Swift.min(count, self.count)
        array.removeFirst(count)
    }

    /// 末尾の要素を削除する
    open func removeLast() {
        if !array.isEmpty {
            array.removeLast()
        }
    }

    /// 末尾の指定数の要素を削除する
    open func removeLast(count: Int) {
        let removeFrom = self.count - count
        removeLastFrom(removeFrom)
    }

    /// 指定したインデックス以降の要素を削除する
    open func removeLastFrom(_ index: Int?) {
        guard let index = index else { return }
        if array.count <= index {
            return
        }
        let upTo = Swift.max(index, 0)
        array = Array(array.prefix(upTo: upTo))
    }

    /// 保持する要素を全て削除する
    open func clear() {
        array.removeAll()
    }

    /// 指定したインデックスからspan分の範囲のうちの最大値
    open func max(from: Int, span: Int) -> CGFloat? {
        let to = from + span - 1
        var result: CGFloat?

        for index in (from...to) {
            guard let value = self[index], !value.isNaN else { continue }
            if let maxValue = result {
                result = Swift.max(maxValue, value)
            } else {
                result = value
            }
        }
        return result
    }

    /// 指定したインデックスからspan分の範囲のうちの最小値
    open func min(from: Int, span: Int) -> CGFloat? {
        let to = from + span - 1
        var result: CGFloat?

        for index in (from...to) {
            guard let value = self[index], !value.isNaN else { continue }
            if let minValue = result {
                result = Swift.min(minValue, value)
            } else {
                result = value
            }
        }
        return result
    }
    
    /// 指定した範囲の値を保持した新しいNumberArray
    open func subArray(range: CountableClosedRange<Int>) -> NumberArray? {
        if count <= range.upperBound {
            return nil
        }
        return NumberArray(array: Array(array[range.lowerBound...range.upperBound]))
    }
    
    /// 指定したインデックス以降の値を保持した新しい NumberArray
    open func subArray(from: Int) -> NumberArray? {
        if from < 0 || count <= from {
            return nil
        }
        return NumberArray(array: Array(array.suffix(from: from)))
    }

    /// 最初の引数の数の要素を取得する
    public func first(size: Int) -> NumberArray? {
        if size < 0 || count < size {
            return nil
        }
        return NumberArray(array: Array(array[0..<size]))
    }

    /// 最後の引数の数の要素を取得する
    public func last(size: Int) -> NumberArray? {
        if size < 0 || count < size {
            return nil
        }
        return NumberArray(array: Array(array[(count - size)..<count]))
    }

    /// コピーする
    open func copy() -> NumberArray {
        return NumberArray(array: floatArray)
    }
}
