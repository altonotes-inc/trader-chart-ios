//
//  TurningPointCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 転換点の計算
public class TurningPointCalculator {
    public static let defaultReversalRate: CGFloat = 0.5

    //    ■転換点の判定方法
    //    ●対象の足(x)が過去10本、未来10本の中で最高値の場合、以下の基準で「天」の転換点になり得るかどうかを判定する。
    //
    //    ①.直近の転換点が底：直近の転換点のリバーサル値(*)を超えている→天としての新しい転換点として追加。
    //    ②.直近の転換点が天：直近の転換点の値を超えている→直近の天を更新した新しい天として直近の転換点を上書きする。
    //
    //    ●対象の足(x)が過去10本、未来10本の中で最安値の場合、以下の基準で「底」の転換点になり得るかどうかを判定する。
    //
    //    ①.直近の転換点が天：直近の転換点のリバーサル値(*)を下回っている → 底としての新しい転換点として追加。
    //    ②.直近の転換点が底：直近の転換点の値を下回っている → 直近の底を更新した新しい底として直近の転換点を上書きする。
    //
    //    ■(*)リバーサル値の算出式
    //
    //    ・転換点が底の場合
    //    リバーサル値 ＝ 転換点の値＋(転換点直前10本の最高値－転換点の値)×0.5
    //
    //    ・転換点が天の場合
    //    リバーサル値 ＝ 転換点の値＋(転換点直前10本の最安値－転換点の値)×0.5
    //
    //    ■最初の転換点の決め方
    //    計算の一番最初には直近の転換点が存在しないため、その足が過去10本、未来10本の中で最高値であるならば無条件に天として扱い、最安値であれば底として扱う。

    // NOTE: 転換点の仕様の問題
    // 現在の転換点の実装には以下の問題があるが、インパクトが小さいためいったん現状のままとする。
    //
    // # 更新時に古い転換点が消えない
    // 転換点には未来10本の中で最高値・最安値という条件があるが、今まで条件を満たしていた点が、最新足の価格更新により、最高値・最安値ではなくなる場合がある。
    // その場合、本来であれば条件を満たさなくなった転換点は消えるのが良いが、現在の実装ではそのまま残ってしまう。
    //
    // # 天かつ底の点が考慮されていない
    // 高値、安値がともに飛び抜けた足は、天かつ底になるのが自然に思われるが、現在の仕様は天と底が交互に発生する前提で、天かつ底が考慮されない。
    // 天と底両方の条件を満たす場合は、無条件で天として扱われてしまう。

    /// 計算する
    ///
    /// - Parameters:
    ///   - span: 平均算出スパン
    ///   - reversalRate: 計算元の数値配列
    ///   - highList: 高値の配列
    ///   - lowList: 安値の配列
    ///   - results: 既存の計算結果
    /// - Returns: 転換点の計算結果
    public func calculate(span: Int,
                          reversalRate: CGFloat = defaultReversalRate,
                          highList: NumberArray?,
                          lowList: NumberArray?,
                          results: Results? = nil) -> Results? {
        guard let highList = highList, let lowList = lowList else { return nil }
        
        var points: [PointData] = results?.points ?? []
        let doubleSpan = span * 2
        
        if highList.count <= doubleSpan {
            return Results(points: [], calculateDataCount: 0)
        }
        
        let start = max(results?.calculatedCount ?? 0, doubleSpan)
        for i in start..<highList.count {
            let target = (i - span)
            
            guard let max = highList.max(from: target - span, span: doubleSpan + 1),
                let min = lowList.min(from: target - span, span: doubleSpan + 1),
                let high = highList[target], let low = lowList[target] else {
                    continue
            }
            
            // 転換点種類判定
            var type = PointType.undefined
            if high == max {
                type = .top
            } else if low == min {
                type = .bottom
            }
            
            if type != .undefined {
                let value = (type == .top) ? high : low
                let point = PointData(index: target, value: value, reversal: 0, type: type)
                
                // リバーサル値を算出
                if type == .top {
                    // 天
                    if let min = lowList.min(from: target - span - 1, span: span) {
                        point.reversal = value + (min - value) * reversalRate
                    }
                } else {
                    // 底
                    if let max = highList.max(from: target - span - 1, span: span) {
                        point.reversal = value + (max - value) * reversalRate
                    }
                }
                
                // 初期点の場合
                if points.isEmpty {
                    points.append(point)
                }
                // 天の判定
                else if type == .top {
                    guard let lastPoint = points.last else {
                        continue
                    }
                    if lastPoint.type == .top {
                        let lastValue = turningValue(index: lastPoint.index, type: lastPoint.type, highList: highList, lowList: lowList)
                        if lastValue < value {
                            points.removeLast()
                            points.append(point)
                        }
                    } else if lastPoint.type == .bottom {
                        if lastPoint.reversal < value {
                            points.append(point)
                        }
                    }
                }
                    // 底の判定
                else if type == .bottom {
                    guard let lastPoint = points.last else {
                        continue
                    }
                    
                    if lastPoint.type == .bottom {
                        let lastValue = turningValue(index: lastPoint.index, type: lastPoint.type, highList: highList, lowList: lowList)
                        if value < lastValue {
                            points.removeLast()
                            points.append(point)
                        }
                    } else if lastPoint.type == .top {
                        if value < lastPoint.reversal {
                            points.append(point)
                        }
                    }
                }
            }
        }
        return Results(points: points, calculateDataCount: highList.count)
    }
    
    public func update(span: Int, reversalRate: CGFloat = defaultReversalRate, highList: NumberArray?, lowList: NumberArray?, results: Results? = nil) -> Results? {
        guard let highList = highList, let lowList = lowList else { return results }
        return calculate(span: span, reversalRate: reversalRate, highList: highList, lowList: lowList, results: results)
    }
    
    private func turningValue(index: Int, type: PointType, highList: NumberArray, lowList: NumberArray) -> CGFloat {
        var value: CGFloat? = nil
        if type == .top {
            value = highList[index]
        } else if type == .bottom {
            value = lowList[index]
        }
        return value ?? 0
    }

    public enum PointType {
        case undefined, top, bottom
    }

    public class PointData {
        public var index: Int
        public var value: CGFloat
        public var reversal: CGFloat
        public var type: PointType

        public init(index: Int, value: CGFloat, reversal: CGFloat, type: PointType) {
            self.index = index
            self.value = value
            self.reversal = reversal
            self.type = type
        }
    }

    /// 転換点の計算結果
    public class Results {
        public var points: [PointData]
        // 計算済みのデータ数
        public var calculatedCount: Int
        public var count: Int {
            return points.count
        }
        
        public init(points: [PointData] = [], calculateDataCount: Int) {
            self.points = points
            self.calculatedCount = calculateDataCount
        }
        
        public func removeLastFrom(_ index: Int?) {
            guard let index = index else { return }
            points = points.filter { return $0.index < index }
            calculatedCount = index
        }
        
        public func copy() -> Results {
            return Results(points: points, calculateDataCount: calculatedCount)
        }

        public func removeOldData(removedCount: Int) {
            points.forEach {
                $0.index -= removedCount
            }
            points = points.filter { removedCount <= $0.index }
        }
    }
}
