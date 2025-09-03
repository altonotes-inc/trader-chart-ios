//
//  IchimokuCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 一目均衡表の計算
public class IchimokuCalculator {

    /// 計算する
    ///
    /// - Parameters:
    ///   - span: 先行線、遅行線のスパン
    ///   - tenkanSpan: 転換線のスパン
    ///   - kijunSpan: 基準線のスパン
    ///   - highList: 高値の配列
    ///   - lowList: 安値の配列
    ///   - closeList: 終値の配列
    /// - Returns: 計算結果
    public func calculate(span: Int,
                          tenkanSpan: Int,
                          kijunSpan: Int,
                          highList: NumberArray?,
                          lowList: NumberArray?,
                          closeList: NumberArray?) -> Results? {
        //   H(n) = 当日を含む過去n日間の高値
        //   L(n) = 当日を含む過去n日間の安値
        //   先行スパン = スパン x 2
        //   転換線  = { H(転換線期間) + L(転換線期間) } ÷ 2
        //   基準線  = { H(基準線期間) + L(基準線期間) } ÷ 2
        //   遅行線  = (スパン - 1) 後の終値
        //   先行線1 = (スパン - 1) 前の ( 転換線 + 基準線 ) ÷ 2
        //   先行線2 = (スパン - 1) 前の { H(先行スパン) + L(先行スパン) } ÷ 2
        guard let highList = highList, let lowList = lowList, let closeList = closeList else { return nil }
        
        let tenkanList = NumberArray()
        let kijunList = NumberArray()
        let chikoList = NumberArray()
        let senko2List = NumberArray()
        
        (0..<span - 1).forEach { i in
            senko2List.append(nil)
        }
        
        let doubleSpan = span * 2
        let tenkanHighArray = highList.movingMaximum(span: tenkanSpan)
        let tenkanLowArray = lowList.movingMinimum(span: tenkanSpan)
        let kijunHighArray = highList.movingMaximum(span: kijunSpan)
        let kijunLowArray = lowList.movingMinimum(span: kijunSpan)
        let senko2HighArray = highList.movingMaximum(span: doubleSpan)
        let senko2LowArray = lowList.movingMinimum(span: doubleSpan)
        
        for i in 0..<closeList.count {
            // 転換線
            var tenkan: CGFloat? = nil
            if tenkanSpan - 1 <= i,
                let tHigh = tenkanHighArray[safe: i] as? CGFloat,
                let tLow = tenkanLowArray[safe: i] as? CGFloat {
                tenkan = (tHigh + tLow) / 2.0
            }
            tenkanList.append(tenkan)
            
            // 基準線
            var kijun: CGFloat? = nil
            if kijunSpan - 1 <= i,
                let kHigh = kijunHighArray[safe: i] as? CGFloat,
                let kLow = kijunLowArray[safe: i] as? CGFloat {
                kijun = (kHigh + kLow) / 2.0
            }
            kijunList.append(kijun)
            
            // 先行線2
            var senko2: CGFloat? = nil
            if doubleSpan - 1 <= i,
                let sHigh = senko2HighArray[safe: i] as? CGFloat,
                let sLow = senko2LowArray[safe: i] as? CGFloat {
                senko2 = (sHigh + sLow) / 2.0
            }
            senko2List.append(senko2)

            // 遅行線
            if let close = closeList[i + span - 1], !close.isNaN {
                chikoList.append(close)
            } else {
                chikoList.append(nil)
            }
        }
        
        // 先行線1
        let senko1List = NumberArray()
        (0..<span - 1).forEach { i in
            senko1List.append(nil)
        }
        for i in 0..<tenkanList.count {
            
            var senko1: CGFloat? = nil
            if let tenkan = tenkanList[i], let kijun = kijunList[i] {
                senko1 = (tenkan + kijun) / 2.0
            }
            senko1List.append(senko1)
        }
        return Results(tenkan: tenkanList, kijun: kijunList, chiko: chikoList, senko2: senko2List, senko1: senko1List)
    }
    
    public func update(span: Int, tenkanSpan: Int, kijunSpan: Int, highList: NumberArray?, lowList: NumberArray?, closeList: NumberArray?, results: Results? = nil) -> Results? {
        guard let highList = highList, let lowList = lowList, let closeList = closeList else { return results }
        guard let results = results?.copy() else {
            return calculate(span: span, tenkanSpan: tenkanSpan, kijunSpan: kijunSpan, highList: highList, lowList: lowList, closeList: closeList)
        }

        let dataCount = closeList.count
        let remainingCount = dataCount - results.count
        if 0 < remainingCount {
            let needSpan = max(max(tenkanSpan, kijunSpan), span * 2)
            let from = max(0, dataCount - remainingCount - needSpan + 1)
            let range = from...(dataCount - 1)
            guard let highList = highList.subArray(range: range) else { return results }
            guard let lowList = lowList.subArray(range: range) else { return results }
            guard let closeList = closeList.subArray(range: range) else { return results }
            
            guard let updateResults = calculate(span: span, tenkanSpan: tenkanSpan, kijunSpan: kijunSpan, highList: highList, lowList: lowList, closeList: closeList) else {
                return results
            }
            results.tenkan.append(contentsOf: Array(updateResults.tenkan.floatArray[(updateResults.tenkan.count - remainingCount)...]))
            results.kijun.append(contentsOf: Array(updateResults.kijun.floatArray[(updateResults.kijun.count - remainingCount)...]))
            results.senko1.append(contentsOf: Array(updateResults.senko1.floatArray[(updateResults.senko1.count - remainingCount)...]))
            results.senko2.append(contentsOf: Array(updateResults.senko2.floatArray[(updateResults.senko2.count - remainingCount)...]))

            var chikoList: [CGFloat?]
            if span < results.chiko.count {
                let base = results.chiko.floatArray[0...(results.chiko.count - span)]
                let update = updateResults.chiko.floatArray[(updateResults.chiko.count - span - remainingCount + 1)...]
                chikoList = Array(base + update)
            } else {
                chikoList = updateResults.chiko.floatArray
            }
            results.chiko.clear()
            results.chiko.append(contentsOf: chikoList)
        }
        return results
    }

    /// 一目均衡表の計算結果
    public struct Results {
        public let tenkan: NumberArray
        public let kijun: NumberArray
        public let chiko: NumberArray
        public let senko2: NumberArray
        public let senko1: NumberArray

        public init(tenkan: NumberArray, kijun: NumberArray, chiko: NumberArray, senko2: NumberArray, senko1: NumberArray) {
            self.tenkan = tenkan
            self.kijun = kijun
            self.chiko = chiko
            self.senko1 = senko1
            self.senko2 = senko2
        }

        public var count: Int {
            return kijun.count
        }

        public func removeFirst(_ count: Int) {
            tenkan.removeFirst(count)
            kijun.removeFirst(count)
            chiko.removeFirst(count)
            senko2.removeFirst(count)
            senko1.removeFirst(count)
        }

        public func copy() -> Results {
            return Results(tenkan: tenkan.copy(), kijun: kijun.copy(), chiko: chiko.copy(), senko2: senko2.copy(), senko1: senko1.copy())
        }
    }

}

private extension NumberArray {
    
    func movingMaximum(span: Int) -> [CGFloat?] {
        var beforeValue: CGFloat? = nil
        var beforeValueIndex: Int = 0
        var result: [CGFloat?] = []
        
        for index in (0..<self.count) {
            if index - span + 1 <= beforeValueIndex,
                let oldValue = beforeValue,
                let newValue = self.floatArray[index],
                !newValue.isNaN {
                let maxValue = Swift.max(oldValue, newValue)
                result.append(maxValue)
                if newValue == maxValue {
                    beforeValue = newValue
                    beforeValueIndex = index
                }
                continue
            }
            
            var maxValue: CGFloat? = nil
            if span - 1 <= index,
                let high = self.max(from: index - span + 1, span: span) {
                maxValue = high
                for i in (index - span + 1...index) {
                    if high == self.floatArray[i] {
                        beforeValue = high
                        beforeValueIndex = i
                    }
                }
            }
            result.append(maxValue)
        }
        return result
    }
    
    func movingMinimum(span: Int) -> [CGFloat?] {
        var beforeValue: CGFloat? = nil
        var beforeValueIndex: Int = 0
        var result: [CGFloat?] = []
        
        for index in (0..<self.count) {
            if index - span + 1 <= beforeValueIndex,
                let oldValue = beforeValue,
                let newValue = self.floatArray[index],
                !newValue.isNaN {
                let minValue = Swift.min(oldValue, newValue)
                result.append(minValue)
                if newValue == minValue {
                    beforeValue = newValue
                    beforeValueIndex = index
                }
                continue
            }
            
            var minValue: CGFloat? = nil
            if span - 1 <= index,
                let low = self.min(from: index - span + 1, span: span) {
                minValue = low
                for i in (index - span + 1...index) {
                    if low == self.floatArray[i] {
                        beforeValue = low
                        beforeValueIndex = i
                    }
                }
            }
            result.append(minValue)
        }
        return result
    }
    
}
