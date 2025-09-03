//
//  BollingerBandCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// ボリンジャーバンドの計算
public class BollingerBandCalculator {

    /// 計算する
    ///
    /// - Parameters:
    ///   - span: 移動平均算出スパン
    ///   - closeList: 終値の配列
    /// - Returns: 計算結果
    public func calculate(span: Int, closeList: NumberArray?, sigmaRates: [CGFloat]) -> Results? {
        guard let closeList = closeList else { return nil }
        guard let smaList = SMACalculator().calculate(span: span, src: closeList) else { return nil }
        
        let plusList: [NumberArray] = sigmaRates.map { _ in NumberArray() }
        let minusList: [NumberArray] = sigmaRates.map { _ in NumberArray() }
        
        // SMAを標準偏差のX倍上下にずらす
        //   P(n) = ( C(n) + C(n-1) + ... + C(n-(S-2)) + C(n-(S-1)) ) / S
        //   B(n) = sqrt( ( ((C(n) - P(n))^2 + ((C(n-1) - P(n))^2 + ... + ((C(n-(S-2)) - P(n))^2 + ((C(n-(S-1)) - P(n))^2 ) / S )
        //   +σ1 = P(n) + B(n)
        //   -σ1 = P(n) - B(n)
        
        for i in 0..<smaList.count {
            if let sma = smaList[i] {
                var sigma: CGFloat = 0.0
                
                // 標準偏差の計算
                for j in (i - span + 1)...i {
                    guard let close = closeList[j] else { continue }
                    sigma += pow(close - sma, 2)
                }
                sigma = sqrt(sigma / CGFloat(span))
                
                sigmaRates.enumerated().forEach { offset, element in
                    plusList[offset].append(sma + sigma * element)
                    minusList[offset].append(sma - sigma * element)
                }
            } else {
                sigmaRates.enumerated().forEach { offset, _ in
                    plusList[offset].append(nil)
                    minusList[offset].append(nil)
                }
            }
        }
        return Results(sma: smaList, plus: plusList, minus: minusList)
    }
    
    public func update(span: Int, closeList: NumberArray?, sigmaRates: [CGFloat], results: Results? = nil) -> Results? {
        guard let closeList = closeList else { return results }
        guard let results = results?.copy() else { return calculate(span: span, closeList: closeList, sigmaRates: sigmaRates) }
        
        let remainingCount = closeList.count - results.sma.count
        if 0 < remainingCount {
            let start = max(0, closeList.count - remainingCount - span)
            guard let remainingData = closeList.subArray(range: start...(closeList.count - 1)) else { return results }
            let from = remainingData.count - remainingCount
            guard let updateResults = calculate(span: span, closeList: remainingData, sigmaRates: sigmaRates) else { return results }
            results.sma.append(contentsOf: Array(updateResults.sma.floatArray[from...]))
            updateResults.plus.enumerated().forEach { offset, element in
                results.plus[offset].append(contentsOf: Array(element.floatArray[from...]))
            }
            updateResults.minus.enumerated().forEach { offset, element in
                results.minus[offset].append(contentsOf: Array(element.floatArray[from...]))
            }
        }
        return results
    }

    /// ボリンジャーバンドの計算結果
    public struct Results {
        public let sma: NumberArray
        public let plus: [NumberArray]
        public let minus: [NumberArray]

        public init(sma: NumberArray, plus: [NumberArray], minus: [NumberArray]) {
            self.sma = sma
            self.plus = plus
            self.minus = minus
        }
        
        public func removeLastFrom(_ index: Int?) {
            sma.removeLastFrom(index)
            plus.forEach { $0.removeLastFrom(index) }
            minus.forEach { $0.removeLastFrom(index) }
        }

        public func removeFirst(_ count: Int) {
            sma.removeFirst(count)
            plus.forEach { $0.removeFirst(count) }
            minus.forEach { $0.removeFirst(count) }
        }
        
        public func copy() -> Results {
            return Results(sma: sma.copy(), plus: plus.map { $0.copy() }, minus: minus.map { $0.copy() })
        }
    }
}
