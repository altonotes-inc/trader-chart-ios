//
//  StochasticsCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// ストキャスティクスの計算
public class StochasticsCalculator {

    /// 計算する
    ///
    /// - Parameters:
    ///   - kSpan: %Kのスパン
    ///   - dSpan: %Dのスパン
    ///   - sdSpan: Slow%Dのスパン
    ///   - closeList: 終値の配列
    ///   - highList: 高値の配列
    ///   - lowList: 安値の配列
    /// - Returns: 計算結果
    public func calculate(kSpan: Int,
                          dSpan: Int,
                          sdSpan: Int,
                          closeList: NumberArray?,
                          highList: NumberArray?,
                          lowList: NumberArray?) -> Results? {
        //   %K = ( 当日の終値 - K日間の最安値 ) / ( K日間の最高値 - K日間の最安値 ) * 100
        //   %D = ( 当日の終値 - K日間の最安値 )のD日間の合計 / ( K日間の最高値 - K日間の最安値 )のD日間の合計 * 100
        //   Slow %D = %DのSD日間の移動平均
        guard let closeList = closeList, let highList = highList, let lowList = lowList else { return nil }
        
        // ゼロ（付近）除算防止のためのリミット
        let eps: CGFloat = 0.000001
        
        let upList = NumberArray()
        let rangeList = NumberArray()
        let kList = NumberArray()
        
        // %K
        for i in 0..<closeList.count {
            var up: CGFloat? = nil
            var range: CGFloat? = nil
            var k: CGFloat? = nil
            
            if kSpan - 1 <= i {
                if let close = closeList[i], !close.isNaN,
                    let low = lowList.min(from: i - kSpan + 1, span: kSpan), !low.isNaN,
                    let high = highList.max(from: i - kSpan + 1, span: kSpan), !high.isNaN {
                    up = close - low
                    range = high - low
                    if eps < abs(high - low) {
                        k = ((close - low) / (high - low)) * 100.0
                    }
                }
            }
            upList.append(up)
            rangeList.append(range)
            kList.append(k)
        }
        
        // %D
        guard let upSmaList = SMACalculator().calculate(span: dSpan, src: upList) else { return nil }
        guard let rangeSmaList = SMACalculator().calculate(span: dSpan, src: rangeList) else { return nil }
        let dList = NumberArray()
        
        for i in 0..<upSmaList.count {
            var d: CGFloat? = nil
            if let upSma = upSmaList[i], let rangeSma = rangeSmaList[i], eps < abs(rangeSma) {
                d = upSma / rangeSma * 100.0
            }
            dList.append(d)
        }
        
        // Slow %D
        guard let sdList = SMACalculator().calculate(span: sdSpan, src: dList) else { return nil }
        
        return Results(upList: upList, rangeList: rangeList, kList: kList, dList: dList, sdList: sdList)
    }
    
    public func update(kSpan: Int, dSpan: Int, sdSpan: Int, closeList: NumberArray?, highList: NumberArray?, lowList: NumberArray?, results: Results? = nil) -> Results? {
        guard let closeList = closeList, let highList = highList, let lowList = lowList, closeList.count == highList.count, closeList.count == lowList.count else { return results }
        guard let results = results?.copy() else { return calculate(kSpan: kSpan, dSpan: dSpan, sdSpan: sdSpan, closeList: closeList, highList: highList, lowList: lowList) }
        
        let remainingCount = closeList.count - results.upList.count
        if 0 < remainingCount {
            let start = max(0, closeList.count - remainingCount - kSpan - dSpan - sdSpan + 1)
            guard let remainingCloseList = closeList.subArray(range: start...(closeList.count - 1)) else { return results }
            guard let remainingHighList = highList.subArray(range: start...(highList.count - 1)) else { return results }
            guard let remainingLowList = lowList.subArray(range: start...(lowList.count - 1)) else { return results }
            
            guard let updateResults = calculate(kSpan: kSpan, dSpan: dSpan, sdSpan: sdSpan, closeList: remainingCloseList, highList: remainingHighList, lowList: remainingLowList) else {
                return results
            }
            results.upList.append(contentsOf: Array(updateResults.upList.floatArray[(remainingCloseList.count - remainingCount)...]))
            results.rangeList.append(contentsOf: Array(updateResults.rangeList.floatArray[(remainingCloseList.count - remainingCount)...]))
            results.dList.append(contentsOf: Array(updateResults.dList.floatArray[(remainingCloseList.count - remainingCount)...]))
            results.kList.append(contentsOf: Array(updateResults.kList.floatArray[(remainingCloseList.count - remainingCount)...]))
            results.sdList.append(contentsOf: Array(updateResults.sdList.floatArray[(remainingCloseList.count - remainingCount)...]))
        }
        return results
    }

    /// ストキャスティクスの計算結果
    public struct Results {
        public let upList: NumberArray
        public let rangeList: NumberArray
        public let kList: NumberArray
        public let dList: NumberArray
        public let sdList: NumberArray

        public init(upList: NumberArray, rangeList: NumberArray, kList: NumberArray, dList: NumberArray, sdList: NumberArray) {
            self.upList = upList
            self.rangeList = rangeList
            self.kList = kList
            self.dList = dList
            self.sdList = sdList
        }
        
        public func removeLastFrom(_ index: Int?) {
            upList.removeLastFrom(index)
            rangeList.removeLastFrom(index)
            kList.removeLastFrom(index)
            dList.removeLastFrom(index)
            sdList.removeLastFrom(index)
        }

        public func removeFirst(_ count: Int) {
            upList.removeFirst(count)
            rangeList.removeFirst(count)
            kList.removeFirst(count)
            dList.removeFirst(count)
            sdList.removeFirst(count)
        }

        public func copy() -> Results {
            return Results(upList: upList.copy(), rangeList: rangeList.copy(), kList: kList.copy(), dList: dList.copy(), sdList: sdList.copy())
        }
    }
}
