//
//  RSICalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// RSIの計算
public class RSICalculator {

    /// 計算する
    ///
    /// - Parameters:
    ///   - span: スパン
    ///   - src:数値配列
    /// - Returns: 計算結果
    public func calculate(span: Int, src: NumberArray?) -> Results? {
        guard let src = src else { return nil }
        
        //   A = データn件の値上がり幅の平均
        //   B = データn件の値下がり幅の平均
        //   RSI = A / ( A + B ) * 100
        
        let rsiList = NumberArray()
        
        var preValue: CGFloat? = nil
        var gainSum: CGFloat = 0
        var lossSum: CGFloat = 0
        var gains: [CGFloat] = []
        var losses: [CGFloat] = []
        
        for i in src.indicies {
            var rsi: CGFloat? = nil
            let value = src[i]
            
            var gain: CGFloat = 0
            var loss: CGFloat = 0
            if let value = value, let preValue = preValue, !value.isNaN, !preValue.isNaN {
                gain = max(0, value - preValue)
                loss = max(0, preValue - value)
            }
            
            if i <= span {
                gainSum += gain
                lossSum += loss
            } else {
                gainSum += (gain - gains[i - span])
                lossSum += (loss - losses[i - span])
            }
            
            if span <= i {
                let d = gainSum + lossSum
                if d != 0 {
                    rsi = (gainSum / d) * 100
                }
            }
            
            rsiList.append(rsi)
            
            gains.append(gain)
            losses.append(loss)
            preValue = value
        }
        return Results(rsi: rsiList, gains: NumberArray(array: gains), losses: NumberArray(array: losses))
    }
    
    public func update(span: Int, src: NumberArray?, results: Results? = nil) -> Results? {
        guard let src = src else { return results }
        guard let results = results?.copy() else { return calculate(span: span, src: src) }
        
        let remainingCount = src.count - results.count
        if 0 < remainingCount {
            var preValue: CGFloat? = src[results.count - 1]
            var gainSum: CGFloat = results.gainSum(range: (results.gains.count - span)...(results.count - 1))
            var lossSum: CGFloat = results.lossSum(range: (results.losses.count - span)...(results.count - 1))
            
            (0..<remainingCount).forEach { i in
                var rsi: CGFloat? = nil
                let value = src[src.count - (remainingCount - i)]
                
                var gain: CGFloat = 0
                var loss: CGFloat = 0
                if let value = value, let preValue = preValue, !value.isNaN, !preValue.isNaN {
                    gain = max(0, value - preValue)
                    loss = max(0, preValue - value)
                }
                
                if results.count <= span {
                    gainSum += gain
                    lossSum += loss
                } else {
                    gainSum += (gain - (results.gains[results.count - span] ?? 0))
                    lossSum += (loss - (results.losses[results.count - span] ?? 0))
                }
                
                if span <= results.count {
                    let d = gainSum + lossSum
                    if d != 0 {
                        rsi = (gainSum / d) * 100
                    }
                }
                
                results.rsi.append(rsi)
                
                results.gains.append(gain)
                results.losses.append(loss)
                preValue = value
            }
        }
        return results
    }

    /// RSIの計算結果
    public struct Results {
        public let rsi: NumberArray
        public let gains: NumberArray
        public let losses: NumberArray

        public init(rsi: NumberArray, gains: NumberArray, losses: NumberArray) {
            self.rsi = rsi
            self.gains = gains
            self.losses = losses
        }
        
        public var count: Int {
            return rsi.count
        }
        
        public func removeLastFrom(_ index: Int?) {
            rsi.removeLastFrom(index)
            gains.removeLastFrom(index)
            losses.removeLastFrom(index)
        }

        public func removeFirst(_ count: Int) {
            rsi.removeFirst(count)
            gains.removeFirst(count)
            losses.removeFirst(count)
        }
        
        public func gainSum(range: CountableClosedRange<Int>) -> CGFloat {
            guard let gains = gains.subArray(range: limitRange(range))?.floatArray else { return 0.0 }
            return gains.compactMap { $0 }.reduce(0.0, +)
        }
        
        public func lossSum(range: CountableClosedRange<Int>) -> CGFloat {
            guard let losses = losses.subArray(range: limitRange(range))?.floatArray else { return 0.0 }
            return losses.compactMap { $0 }.reduce(0.0, +)
        }
        
        public func copy() -> Results {
            return Results(rsi: rsi.copy(), gains: gains.copy(), losses: losses.copy())
        }

        public func limitRange(_ range: CountableClosedRange<Int>) -> CountableClosedRange<Int> {
            var start = min(range.lowerBound, count - 1)
            var end = min(range.upperBound, count - 1)
            start = max(start, 0)
            end = max(end, 0)
            return start...end
        }
    }
}
