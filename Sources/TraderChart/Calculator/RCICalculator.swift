//
//  RCICalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// RCIの計算
public class RCICalculator {

    /// 計算する
    ///
    /// - Parameters:
    ///   - span: スパン
    ///   - src: 計算元の数値配列
    /// - Returns: RCI
    public func calculate(span: Int, src: NumberArray?) -> NumberArray? {
        guard let src = src else { return nil }
        
        // A(n) = 期間n内での終値と日付の順位差
        //        終値の順位は高い方から順に1,2,3...
        //        日付の順位は新しい方から順に1,2,3...
        //        同じ終値がある場合、順位は平均値にする。（TOP2が同順1位の場合、両方1.5位とみなす）
        // RCI = ( 1 - ( 6 * ( A(n)^2 + A(n-1)^2 + ... + A(n-(S-2))^2 + A(n-(S-1))^2 ) / S * ( S^2 - 1 ) ) ) * 100
        
        let result = NumberArray()
        
        let denom = span * (span * span - 1)
        
        var orderList: [CGFloat] = Array<CGFloat>(repeating: 0, count: span)
        var enableDataCount: Int = 0
        
        for i in 0..<src.count {
            guard let rate = src[i], !rate.isNaN else {
                result.append(nil)
                orderList = Array<CGFloat>(repeating: 0, count: span)
                enableDataCount = 0
                continue
            }
            
            // 期間からはずれた順位より低い場合はマイナスする
            if span <= min(enableDataCount, i) {
                let order = orderList[i % span]
                for j in 0..<span {
                    if orderList[j] > order {
                        orderList[j] -= 1
                    } else if orderList[j] == order {
                        orderList[j] -= 0.5
                    }
                }
            }
            orderList[i % span] = 1
            enableDataCount += 1
            
            for j in 1..<span {
                if j <= min(i, enableDataCount - 1) {
                    guard let compareRate = src[i - j], !compareRate.isNaN else {
                        break
                    }
                    if compareRate > rate {
                        orderList[i % span] += 1
                    } else if compareRate < rate {
                        orderList[(i - j) % span] += 1
                    } else {
                        orderList[i % span] += 0.5
                        orderList[(i - j) % span] += 0.5
                    }
                }
            }
            
            // spanが1の場合0除算が発生するので計算不能
            // span分データがない場合も計算不能
            if span == 1 || i < span - 1 || enableDataCount < span {
                result.append(nil)
                continue
            }
            
            var sigma: CGFloat = 0
            for t in 0..<span {
                let rank = orderList[(i - (span - 1) + t) % span]
                let temp = CGFloat(span - t) - rank
                sigma += (temp * temp)
            }
            
            let rci = 1 - (6 * sigma / CGFloat(denom))
            result.append(rci * 100)
        }
        
        return result
    }

    public func update(span: Int, src: NumberArray?, rciList: NumberArray? = nil) -> NumberArray? {
        guard let src = src else { return rciList }
        guard let rciList = rciList?.copy() else { return calculate(span: span, src: src) }
        
        let remainingCount = src.count - rciList.count
        if 0 < remainingCount {
            let start = max(0, src.count - remainingCount - span + 1)
            guard let remainingData = src.subArray(range: start...(src.count - 1)) else { return rciList }
            guard let updateResults = calculate(span: span, src: remainingData) else { return rciList }
            rciList.append(contentsOf: Array(updateResults.floatArray[(remainingData.count - remainingCount)...]))
        }
        return rciList
    }
    
}
