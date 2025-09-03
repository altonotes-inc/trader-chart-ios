//
//  PinchInOut.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// ピンチイン・ピンチアウトの処理
open class PinchInOut {
    /// 最小のX軸刻み（プロット）間隔
    public var minXAxisInterval: CGFloat = 1
    /// 最大のX軸刻み（プロット）間隔
    public var maxXAxisInterval: CGFloat = 300

    /// タッチを開始した位置
    public var startPoints: [CGPoint]?

    /// タッチを開始したときのレコード幅
    public var pinchStartXAxisInterval: CGFloat = 0
    /// タッチを開始したときのスクロール位置
    public var pinchStartScrollOffset: CGFloat = 0

    /// ピンチイン・アウトコールバック(recrodWidth, scrollOffset) -> Void
    public var onPinchInOut: ((CGFloat, CGFloat) -> Void)?

    /// ピンチイン・ピンチアウト中か
    open var isPinching: Bool = false

    open func touchesBegan(points: [CGPoint], xAxisInterval: CGFloat, scrollOffset: CGFloat) {
        if points.count == 2 {
            isPinching = true
            pinchStartXAxisInterval = xAxisInterval
            pinchStartScrollOffset = scrollOffset
        }
    }

    open func touchesMoved(points: [CGPoint], xAxisInterval: CGFloat, scrollOffset: CGFloat, xAxisRect: CGRect) {
        if points.count != 2 {
            return
        }

        isPinching = true

        if let startPoints = startPoints, startPoints.count == 2 {

            let oldXs = startPoints.map { $0.x }
            let newXs = points.map { $0.x }
            let oldWidth = abs(oldXs[0] - oldXs[1])
            let newWidth = abs(newXs[0] - newXs[1])
            // FIXME XAxisのRectから計算するのは直感的ではない
            // グラフ右端からタッチ中心点までのX座標距離を算出
            let newCenterX = toGraphRightX(rect: xAxisRect, viewX: (newXs[0] + newXs[1]) / 2)
            let oldCenterX = toGraphRightX(rect: xAxisRect, viewX: (oldXs[0] + oldXs[1]) / 2)

            // 0除算回避のため最低値を設ける
            if oldWidth < 1 {
                return
            }
            var newInterval = pinchStartXAxisInterval * (newWidth / oldWidth)
            newInterval = max(newInterval, minXAxisInterval)
            newInterval = min(newInterval, maxXAxisInterval)
            let scaleRate = newInterval / pinchStartXAxisInterval
            let scrollOffset = (pinchStartScrollOffset + oldCenterX ) * scaleRate - newCenterX
            onPinchInOut?(newInterval, scrollOffset)
        } else {
            startPoints = points
            pinchStartXAxisInterval = xAxisInterval
            pinchStartScrollOffset = scrollOffset
        }
    }

    open func touchesEnded(points: [CGPoint]) {
        isPinching = false
        startPoints = nil
    }

    /// View内のX座標を図形領域の右からの座標に変換する
    open func toGraphRightX(rect: CGRect, viewX: CGFloat) -> CGFloat {
        return rect.maxX - viewX
    }
}
