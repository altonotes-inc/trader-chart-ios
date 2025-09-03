//
//  StickDrawer.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/23.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 縦線の描画
open class StickChartDrawer {
    
    /// 棒グラフを描画する
    ///
    /// - Parameters:
    ///   - context: 描画コンテキスト。CGContextなどを保持する
    ///   - rect: 描画するグラフの範囲
    ///   - yAxis: Y軸。Y座標の計算に使われる
    ///   - visibleSpan: 描画するインデックスの範囲
    ///   - fromValues: 棒の始点価格の配列
    ///   - toValues: 棒の終点価格の配列
    ///   - color: 棒の色
    ///   - lineWidth: 棒の幅
    ///   - condition: 指定位置に棒を描画するかの判定。 (インデックス、始点価格、終点価格) -> 描画するか
    open func draw(context: ChartDrawingContext,
                   rect: CGRect,
                   yAxis: YAxis,
                   visibleSpan: ClosedRange<Int>,
                   fromValues: NumberArray?,
                   toValues: NumberArray?,
                   color: UIColor,
                   lineWidth: CGFloat,
                   condition: ((Int, CGFloat?, CGFloat?) -> Bool)? = nil) {
        guard let fromValues = fromValues, let toValues = toValues else {
            return
        }

        let cgContext = context.cgContext
        cgContext.saveGState()
        cgContext.clip(to: rect)

        color.setStroke()
        cgContext.setLineWidth(lineWidth)

        let halfInterval = context.xAxisInterval / 2.0

        cgContext.beginPath()
        var x = rect.maxX + context.rightOffset - context.xAxisInterval
        for i in visibleSpan.reversed() {
            if let from = fromValues[i], let to = toValues[i] {
                if condition?(i, from, to) ?? true {
                    let top = yAxis.position(to)
                    let bottom = yAxis.position(from)
                    let stickX = x + halfInterval
                    cgContext.addLines(between: [
                        CGPoint(x: stickX, y: top),
                        CGPoint(x: stickX, y: bottom)
                    ])
                }
            }

            x -= context.xAxisInterval
        }

        cgContext.strokePath()
        cgContext.restoreGState()
    }
}
