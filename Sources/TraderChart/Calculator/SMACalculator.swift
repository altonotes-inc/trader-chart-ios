//
//  SMACalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 移動平均の計算
public class SMACalculator {

    /// 単純移動平均を計算する
    /// 差分計算時は１つ前の移動平均を元に計算するが、誤差が蓄積されるため、一度に計算した結果と差分計算を繰り返した結果は完全一致しない場合がある。
    /// ただし、誤差が蓄積されても充分に小さい為、許容できる範囲と判断し現状のままとしている。
    /// - Parameters:
    ///   - span: 平均算出スパン
    ///   - src: 計算元の数値配列
    ///   - smaList: 既に計算済みの移動平均
    /// - Returns: 移動平均
    public func calculate(span: Int, src: NumberArray?, existingSMA: NumberArray? = nil) -> NumberArray? {
        guard let src = src else { return existingSMA }
        assert(0 < span, "span must be greater than 0")

        let results = existingSMA?.copy() ?? NumberArray()

        var startIndex = existingSMA?.count ?? 0
        var lastSMA: CGFloat? = existingSMA?.last

        if lastSMA == nil && 0 < startIndex {
            for index in (0..<startIndex).reversed() {
                if let value = src[index], !value.isNaN {
                    startIndex -= 1
                    results.removeLast()
                } else {
                    break
                }
            }
        }

        var firstSum: CGFloat = 0
        var firstCount = 0

        for index in startIndex..<src.count {
            var sma: CGFloat? = nil

            // 新規データありの場合
            if let value = src[index], !value.isNaN {
                // 直近のSMAをベースに計算
                if let baseSMA = lastSMA, let oldValue = src[index - span] {
                    sma = baseSMA + (value - oldValue) / CGFloat(span)
                }
                // 初期SMAの計算
                else {
                    firstCount += 1
                    firstSum += value

                    if span <= firstCount {
                        sma = firstSum / CGFloat(span)
                    }
                }
            }
            // データ無しの場合
            else {
                firstSum = 0
                firstCount = 0
                sma = nil
            }

            results.append(sma)
            lastSMA = sma
        }

        return results
    }
}
