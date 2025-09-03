//
//  StandardDeviationCalculator.swift
//  TraderChart
//
//  Created by altonotes on 2019/08/29.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 標準偏差の計算
public class StandardDeviationCalculator {
    
    /// 計算する
    ///
    /// - Parameters:
    ///   - span: 移動平均算出スパン
    ///   - src: 計算元の数値配列
    /// - Returns: 計算結果
    public func calculate(span: Int, src: NumberArray?) -> NumberArray? {
        guard let src = src else { return nil }
        guard let smaList = SMACalculator().calculate(span: span, src: src) else { return nil }
        
        let results = NumberArray()
        for i in 0..<smaList.count {
            if let sma = smaList[i] {
                var sigma: CGFloat = 0.0
                
                // 標準偏差の計算
                for j in (i - span + 1)...i {
                    guard let value = src[j] else { continue }
                    sigma += pow(value - sma, 2)
                }
                results.append(sqrt(sigma / CGFloat(span)))
            } else {
                results.append(nil)
            }
        }
        return results
    }
    
    public func update(span: Int, src: NumberArray?, results: NumberArray? = nil) -> NumberArray? {
        guard let src = src else { return results }
        guard let results = results else {
            return calculate(span: span, src: src)
        }
        let remaingData = src.subArray(from: max(0, results.count - span))
        let result = calculate(span: span, src: remaingData)
        let additionalData = result?.last(size: src.count - results.count)
        let list = results.copy()
        list.append(other: additionalData)
        return list
    }
}
