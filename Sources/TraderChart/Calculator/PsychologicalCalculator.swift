//
//  PsychologicalCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// サイコロジカルの計算
public class PsychologicalCalculator {
    public func calculate(span: Int, src: NumberArray?) -> NumberArray? {
        guard let src = src else { return nil }

        let result = NumberArray()
        for index in src.indicies {
            guard span <= index else {
                result.append(nil)
                continue
            }

            var upCount = 0
            var dataLacking = false
            for i in (index - span + 1...index) {
                guard let value = src[i], !value.isNaN,
                    let preValue = src[i - 1], !preValue.isNaN else {
                        dataLacking = true
                        break
                }

                if 0 < value - preValue {
                    upCount += 1
                }
            }

            if !dataLacking {
                result.append(CGFloat(upCount * 100) / CGFloat(span))
            } else {
                result.append(nil)
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
