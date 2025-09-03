//
//  DMICalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// DMI(ADX)の計算
public class DMICalculator {

    private let smaCalculator = SMACalculator()

    /// 計算する
    ///
    /// - Parameters:
    ///   - averageSpan:平均のスパン
    ///   - adxSpan: ADXのスパン
    ///   - adxrSpan: ADXRのスパン
    ///   - highList: 高値の配列
    ///   - lowList: 安値の配列
    ///   - closeList: 終値の配列
    /// - Returns: 計算結果
    public func calculate(averageSpan: Int, adxSpan: Int, adxrSpan: Int, highList: NumberArray?, lowList: NumberArray?, closeList: NumberArray?) -> Results? {
        guard let highList = highList, let lowList = lowList, let closeList = closeList else { return nil }
        
        //   高値更新 = 前日高値 < 当日高値 ? 当日高値 - 前日高値 : 0
        //   安値更新 = 前日安値 > 当日安値 ? 前日安値 - 当日安値 : 0
        //   +DM = 高値更新 > 安値更新 ? 高値更新 : 0
        //   -DM = 安値更新 > 高値更新 ? 安値更新 : 0
        //   TR = MAX( 当日高値 - 当日安値, 当日高値 - 前日終値, 前日終値 - 当日安値 )
        //   AV(+DM) = +DMのn日間平均値
        //   AV(-DM) = -DMのn日間平均値
        //   AV( TR) =  TRのn日間平均値
        //   +DI = AV(+DM) / AV(TR)
        //   -DI = AV(-DM) / AV(TR)
        //   DX = ABS(+DI - -DI) / (+DI + -DI)
        //   ADX = DXのn日間平均値
        //   ADXR = ADXのn日間平均値
        
        let plusDMList = NumberArray()
        let minusDMList = NumberArray()
        let trList = NumberArray()
        
        for i in 0..<highList.count {
            var plusDM: CGFloat? = nil
            var minusDM: CGFloat? = nil
            var tr: CGFloat? = nil
            
            if 0 < i,
                let high = highList[i], !high.isNaN, let low = lowList[i], !low.isNaN,
                let lastHigh = highList[i - 1], !lastHigh.isNaN, let lastLow = lowList[i - 1], !lastLow.isNaN,
                let lastClose = closeList[i - 1], !lastClose.isNaN {
                
                // +DM, -DMの算出
                let plusDMVal = max(high - lastHigh, 0)
                let minusDMVal = max(lastLow - low, 0)
                
                plusDM = minusDMVal < plusDMVal ? plusDMVal : 0
                minusDM = plusDMVal < minusDMVal ? minusDMVal : 0
                
                // TrueRangeの算出
                tr = max(high - low, high - lastClose, lastClose - low)
            }
            
            plusDMList.append(plusDM)
            minusDMList.append(minusDM)
            trList.append(tr)
        }
        
        // +DI、-DIの算出
        guard let avPDMList = smaCalculator.calculate(span: averageSpan, src: plusDMList) else { return nil }
        guard let avMDMList = smaCalculator.calculate(span: averageSpan, src: minusDMList) else { return nil }
        guard let avTrList = smaCalculator.calculate(span: averageSpan, src: trList) else { return nil }
        
        let plusDIList = NumberArray()
        let minusDIList = NumberArray()
        let dxList = NumberArray()
        
        for i in 0..<avTrList.count {
            var plusDI: CGFloat?
            var minusDI: CGFloat?
            
            if let avPlusDM = avPDMList[i],
                let avMinusDM = avMDMList[i],
                let avTR = avTrList[i] {
                
                if avTR != 0.0 {
                    plusDI = 100.0 * avPlusDM / avTR
                    minusDI = 100.0 * avMinusDM / avTR
                } else {
                    plusDI = 0.0
                    minusDI = 0.0
                }
            }
            
            plusDIList.append(plusDI)
            minusDIList.append(minusDI)
            
            // DX = ABS(+DI - -DI) / (+DI + -DI)
            var dx: CGFloat?
            if let plusDI = plusDI, let minusDI = minusDI {
                let dx1 = abs(plusDI - minusDI)
                let dx2 = plusDI + minusDI
                if dx2 != 0.0 {
                    dx = 100.0 * dx1 / dx2
                } else {
                    dx = 0.0
                }
            }
            
            dxList.append(dx)
        }
        
        guard let adxList = smaCalculator.calculate(span: adxSpan, src: dxList) else { return nil }
        guard let adxrList = smaCalculator.calculate(span: adxrSpan, src: adxList) else { return nil }
        
        return Results(plus: plusDIList, minus: minusDIList, adx: adxList, adxr: adxrList)
    }
    
    public func update(averageSpan: Int, adxSpan: Int, adxrSpan: Int, highList: NumberArray?, lowList: NumberArray?, closeList: NumberArray?, results: Results? = nil) -> Results? {
        guard let highList = highList, let lowList = lowList, let closeList = closeList else { return results }
        guard let results = results?.copy() else { return calculate(averageSpan: averageSpan, adxSpan: adxSpan, adxrSpan: adxrSpan, highList: highList, lowList: lowList, closeList: closeList) }
            
        let remainingCount = highList.count - results.plus.count
        if 0 < remainingCount {
            let start = max(0, highList.count - remainingCount - averageSpan - adxSpan - adxrSpan + 1)
            guard let remainingHighList = highList.subArray(range: start...(highList.count - 1)) else { return results }
            guard let remainingLowList = lowList.subArray(range: start...(lowList.count - 1)) else { return results }
            guard let remainingCloseList = closeList.subArray(range: start...(closeList.count - 1)) else { return results }
            
            guard let updateResults = calculate(averageSpan: averageSpan, adxSpan: adxSpan, adxrSpan: adxrSpan, highList: remainingHighList, lowList: remainingLowList, closeList: remainingCloseList) else {
                return results
            }
            results.plus.append(contentsOf: Array(updateResults.plus.floatArray[(remainingHighList.count - remainingCount)...]))
            results.minus.append(contentsOf: Array(updateResults.minus.floatArray[(remainingHighList.count - remainingCount)...]))
            results.adx.append(contentsOf: Array(updateResults.adx.floatArray[(remainingHighList.count - remainingCount)...]))
            results.adxr.append(contentsOf: Array(updateResults.adxr.floatArray[(remainingHighList.count - remainingCount)...]))
        }
        return results
    }

    /// DMI/ADXの計算結果
    public struct Results {
        public let plus: NumberArray
        public let minus: NumberArray
        public let adx: NumberArray
        public let adxr: NumberArray

        public init(plus: NumberArray, minus: NumberArray, adx: NumberArray, adxr: NumberArray) {
            self.plus = plus
            self.minus = minus
            self.adx = adx
            self.adxr = adxr
        }

        public func removeLastFrom(_ index: Int?) {
            plus.removeLastFrom(index)
            minus.removeLastFrom(index)
            adx.removeLastFrom(index)
            adxr.removeLastFrom(index)
        }

        public func removeFirst(_ count: Int) {
            plus.removeFirst(count)
            minus.removeFirst(count)
            adx.removeFirst(count)
            adxr.removeFirst(count)
        }

        func copy() -> Results {
            return Results(plus: plus.copy(), minus: minus.copy(), adx: adx.copy(), adxr: adxr.copy())
        }
    }
}
