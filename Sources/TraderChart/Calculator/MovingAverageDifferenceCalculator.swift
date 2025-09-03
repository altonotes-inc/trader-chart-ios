//
//  MovingAverageDifferenceCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/09/04.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 移動平均乖離率の計算
public class MovingAverageDifferenceCalculator {

    let smaCalculator = SMACalculator()

    public func calculate(span: Int, src: NumberArray?) -> NumberArray? {
        guard let src = src,
            let sma = smaCalculator.calculate(span: span, src: src) else {
                return nil
        }

        let result = NumberArray()
        for index in src.indicies {
            guard let value = src[index], !value.isNaN,
                let smaValue = sma[index], !smaValue.isNaN else {
                    result.append(nil)
                    continue
            }

            if 1 < span {
                let diff = (value - smaValue) / smaValue
                result.append(diff * 100)
            } else {
                result.append(0)
            }
        }
        return result
    }

    public func update(span: Int, src: NumberArray?, oldResults: NumberArray? = nil) -> NumberArray? {
        guard let src = src else { return oldResults }
        guard let oldResults = oldResults else {
            return calculate(span: span, src: src)
        }
        let remainingData = src.subArray(from: max(0, oldResults.count - span))
        let result = calculate(span: span, src: remainingData)
        let additionalData = result?.last(size: src.count - oldResults.count)
        let list = oldResults.copy()
        list.append(other: additionalData)
        return list
    }
}
