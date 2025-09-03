//
//  BarChartDrawer.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/23.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 棒グラフの描画
open class BarChartDrawer {
    /// バーの最小厚さ。高さゼロでも線を引きたい場合に設定する
    open var minThickness: CGFloat = 0

    /// 初期化
    init(minThickness: CGFloat = 0) {
        self.minThickness = minThickness
    }

    /// 棒の始点と終点を配列で指定して棒グラフを描画する
    open func draw(context: ChartDrawingContext,
                   rect: CGRect,
                   yAxis: YAxis,
                   visibleSpan: ClosedRange<Int>,
                   fromValues: NumberArray?,
                   toValues: NumberArray?,
                   color: UIColor,
                   widthScale: CGFloat,
                   condition: ((Int, CGFloat?, CGFloat?) -> Bool)? = nil) {
        draw(context: context,
             rect: rect,
             yAxis: yAxis,
             visibleSpan: visibleSpan,
             getFromValue: { index in fromValues?[index] },
             toValues: toValues,
             color: color,
             widthScale: widthScale,
             condition: condition)
    }
    
    /// 棒の始点を固定値で指定して棒グラフを描画する
    open func draw(context: ChartDrawingContext,
                   rect: CGRect,
                   yAxis: YAxis,
                   visibleSpan: ClosedRange<Int>,
                   fromValue: CGFloat?,
                   toValues: NumberArray?,
                   color: UIColor,
                   widthScale: CGFloat,
                   condition: ((Int, CGFloat?, CGFloat?) -> Bool)? = nil) {
        draw(context: context,
             rect: rect,
             yAxis: yAxis,
             visibleSpan: visibleSpan,
             getFromValue: { _ in fromValue },
             toValues: toValues,
             color: color,
             widthScale: widthScale,
             condition: condition)
    }

    /// 棒グラフを描画する
    ///
    /// - Parameters:
    ///   - context: 描画コンテキスト。CGContextなどを保持する
    ///   - rect: 描画するグラフの範囲
    ///   - yAxis: Y軸。Y座標の計算に使われる
    ///   - visibleSpan: 描画するインデックスの範囲
    ///   - getFromValue: 引数のインデックス位置の棒の始点価格を取得する関数 (インデックス) -> 始点価格
    ///   - toValues: 棒の終点価格の配列
    ///   - color: 棒の色
    ///   - widthScale: 棒の幅のプロット間隔に対する割合
    ///   - condition: 指定位置に棒を描画するかの判定。 (インデックス、始点価格、終点価格) -> 描画するか
    open func draw(context: ChartDrawingContext,
                   rect: CGRect,
                   yAxis: YAxis,
                   visibleSpan: ClosedRange<Int>,
                   getFromValue: ((Int) -> CGFloat?),
                   toValues: NumberArray?,
                   color: UIColor,
                   widthScale: CGFloat,
                   condition: ((Int, CGFloat?, CGFloat?) -> Bool)? = nil) {
        
        guard let toValues = toValues else {
            return
        }
        
        let cgContext = context.cgContext
        cgContext.saveGState()
        cgContext.clip(to: rect)
        
        color.setFill()
        
        let barW = context.xAxisInterval * widthScale
        let xOffset = (context.xAxisInterval - barW) / 2.0
        
        cgContext.beginPath()
        var x = rect.maxX + context.rightOffset - context.xAxisInterval
        for i in visibleSpan.reversed() {
            if let from = getFromValue(i), let to = toValues[i] {
                if condition?(i, from, to) ?? true {
                    var top = yAxis.position(to)
                    let bottom = yAxis.position(from)
                    var height = bottom - top
                    let absHeight = abs(height)
                    if absHeight < minThickness {
                        let offset = (minThickness - absHeight) / 2
                        top = (top < bottom) ? top - offset : bottom - offset
                        height = minThickness
                    }
                    cgContext.addRect(CGRect(x: x + xOffset, y: top, width: barW, height: height))
                }
            }
            
            x -= context.xAxisInterval
        }
        
        cgContext.fillPath()
        cgContext.restoreGState()
    }
}
