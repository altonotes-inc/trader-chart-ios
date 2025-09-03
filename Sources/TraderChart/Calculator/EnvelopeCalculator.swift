//
//  EnvelopeCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// エンベロープの計算
public class EnvelopeCalculator {
    
    let calculator = SMACalculator()
    
    /// 計算する
    ///
    /// - Parameters:
    ///   - span: 移動平均算出スパン
    ///   - src: 計算元の数値配列
    ///   - rates: 乖離率の配列
    /// - Returns: 計算結果
    public func calculate(span: Int, src: NumberArray?, rates: [CGFloat]) -> [NumberArray]? {
        guard let sma = calculator.calculate(span: span, src: src) else {
            return nil
        }
        return rates.map { rate -> NumberArray in
            let array = sma.map { value -> CGFloat? in
                guard let value = value, !value.isNaN else { return nil }
                return value * rate
            }
            return NumberArray(array: array)
        }
    }
    
    public func update(span: Int, rates: [CGFloat], src: NumberArray?, results: [NumberArray]? = nil) -> [NumberArray]? {
        guard let src = src else { return results }
        guard let results = results else {
            return calculate(span: span, src: src, rates: rates)
        }
        // NOTE:移動平均の差分計算による最適化はしていないが、移動平均の計算は比較的軽いので一旦現状のままとする
        let arrayCount = results.first?.count ?? 0
        let remaingData = src.subArray(from: max(0, arrayCount - span))
        let result = calculate(span: span, src: remaingData, rates: rates)
        let additionalDataList = result?.map {
            $0.last(size: src.count - arrayCount)
        }
        return results.enumerated().map { offset, array in
            if let other = additionalDataList?[offset] {
                array.append(other: other)
            }
            return array
        }
    }
}
