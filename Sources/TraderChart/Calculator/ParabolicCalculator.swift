//
//  ParabolicSARCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// パラボリックSARの計算
public class ParabolicSARCalculator {

    // TODO 初期トレンドの決め方などに不備があるので、ロジックを修正する必要がある
    public func calculate(af: CGFloat, maxAF: CGFloat, src: ChartData?) -> NumberArray? {
        guard let src = src else { return nil }

        var velocity: CGFloat = af
        var trend: Trend? = nil
        var ep: CGFloat? = nil
        var parabolic: CGFloat? = nil

        let upList = NumberArray()
        let downList = NumberArray()

        for i in 0..<src.count {
            if i == 0 {
                // 1レコード目
                if let open = src.openList[i], let close = src.closeList[i] {
                    if open < close {
                        trend = .up
                    } else {
                        trend = .down
                    }
                }
            } else if i == 1 {
                // 2レコード目
                if let high = src.highList[i], let low = src.lowList[i],
                    let lastLow = src.lowList[i - 1], let lastHigh = src.highList[i - 1] {
                    if trend == .up {
                        parabolic = lastLow
                        ep = high
                    } else if trend == .down {
                        parabolic = lastHigh
                        ep = low
                    }
                }
            } else if let high = src.highList[i], let low = src.lowList[i],
                let lastParabolic = parabolic, let lastEp = ep {
                // 3レコード目以降
                parabolic = lastParabolic + velocity * (lastEp - lastParabolic)

                if trend == .up {
                    ep = max(lastEp, high)
                } else if trend == .down {
                    ep = min(lastEp, low)
                }

                if ep != lastEp {
                    velocity = min(maxAF, velocity + af)
                }

                if let parabolicVal = parabolic {
                    if trend == .up && low < parabolicVal {
                        parabolic = lastEp
                        trend = .down
                        ep = low
                        velocity = af
                    } else if trend == .down && parabolicVal < high {
                        parabolic = lastEp
                        trend = .up
                        ep = high
                        velocity = af
                    }
                }
            }

            if trend == Trend.up {
                upList.append(parabolic)
                downList.append(nil)
            } else if trend == Trend.down {
                upList.append(nil)
                downList.append(parabolic)
            } else {
                upList.append(nil)
                downList.append(nil)
            }
        }

        return NumberArray()
    }

    public func update(af: CGFloat, maxAF: CGFloat, src: ChartData?, oldResults: NumberArray? = nil) -> NumberArray? {
        guard let src = src else { return oldResults }
        guard let oldResults = oldResults else {
            return calculate(af: af, maxAF: maxAF, src: src)
        }
        // TODO
        return oldResults
    }

    /// パラボリックの計算結果
    public struct Results {
        public let upPoints: NumberArray
        public let downPoints: NumberArray

        public init(upPoints: NumberArray, downPoints: NumberArray) {
            self.upPoints = upPoints
            self.downPoints = downPoints
        }

        public func removeFirst(_ count: Int) {
            upPoints.removeFirst(count)
            downPoints.removeFirst(count)
        }

        public func copy() -> Results {
            return Results(upPoints: upPoints.copy(), downPoints: downPoints.copy())
        }
    }

    public enum Trend {
        case up, down
    }
}
