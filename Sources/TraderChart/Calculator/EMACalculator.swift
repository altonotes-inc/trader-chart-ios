//
//  EMACalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 指数平滑移動平均の計算
public class EMACalculator {
    /// 計算する
    ///
    /// - Parameters:
    ///   - span: 平均算出スパン
    ///   - src: 計算元の数値配列
    /// - Returns: 指数平滑移動平均
    public func calculate(span: Int, src: NumberArray?) -> NumberArray? {
        // 計算式
        //   初日 = ( C(n) + C(n-1) + C(n-2) + ... + C(n-(S-2)) + C(n-(S-1)) ) / S
        //   以降 = EMA(n-1) + ( 2 / (S+1) ) * ( C(n) - EMA(n-1) )
        guard let src = src else { return nil }
        assert(0 < span, "span must be greater than 0")

        let emaList = NumberArray()
        var sum: CGFloat = 0.0
        var lastEMA: CGFloat? = nil
        var dataCount: Int = 0

        for i in 0..<src.count {

            var ema: CGFloat? = nil

            if let value = src[i], !value.isNaN {
                if dataCount < span - 1 {
                    // 序盤
                    sum += value
                } else if dataCount == span - 1 {
                    // 初回
                    sum += value
                    ema = sum / CGFloat(span)
                } else if let last = lastEMA {
                    // 通常
                    ema = last + ( 2.0 / ( CGFloat(span) + 1.0 ) ) * ( value - last )
                }
                dataCount += 1
            } else {
                sum = 0
                dataCount = 0
            }

            emaList.append(ema)
            lastEMA = ema
        }

        return emaList
    }
    
    public func update(span: Int, src: NumberArray?, emaList: NumberArray? = nil) -> NumberArray? {
        guard let src = src else { return emaList }
        guard let emaList = emaList?.copy() else { return calculate(span: span, src: src) }
        
        for index in emaList.count..<src.count {
            guard let newValue = src[index], !newValue.isNaN, let lastEMA = emaList.last else { break }
            emaList.append(lastEMA + ( 2.0 / ( CGFloat(span) + 1.0 ) ) * (newValue - lastEMA ))
        }
        let remainingCount = src.count - emaList.count
        if 0 < remainingCount {
            let start = max(0, src.count - remainingCount - span)
            guard let remainingData = src.subArray(range: start...(src.count - 1)) else { return emaList }
            guard let updateResults = calculate(span: span, src: remainingData) else { return emaList }
            emaList.append(contentsOf: Array(updateResults.floatArray[(remainingData.count - remainingCount)...]))
        }
        return emaList
    }
}
