//
//  FillingAreaDrawer.swift
//  TraderChart
//
//  Created by altonotes on 2019/06/20.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// ２つの線の間を塗りつぶす
open class FillingAreaDrawer {

    /// 初期化
    public init() {}

    /// dataValues1のラインとdataValue2位置の直線間を塗りつぶす
    public func draw(context: ChartDrawingContext,
                     rect: CGRect,
                     yAxis: YAxis,
                     visibleSpan: ClosedRange<Int>,
                     dataValues1: NumberArray?,
                     dataValue2: CGFloat?,
                     color: UIColor) {
        draw(context: context,
             rect: rect,
             yAxis: yAxis,
             visibleSpan: visibleSpan,
             dataValues1: dataValues1,
             getDataValue2: { _ in dataValue2 },
             color: color)
    }
    
    /// dataValues1のラインとdataValues2の間を塗りつぶす
    public func draw(context: ChartDrawingContext, rect: CGRect, yAxis: YAxis, visibleSpan: ClosedRange<Int>, dataValues1: NumberArray?, dataValues2: NumberArray?, color: UIColor) {
        draw(context: context,
             rect: rect,
             yAxis: yAxis,
             visibleSpan: visibleSpan,
             dataValues1: dataValues1,
             getDataValue2: { offset in dataValues2?[offset] },
             color: color)
    }
    
    /// 二つのラインの間を塗りつぶす
    ///
    /// - Parameters:
    ///   - context: 描画コンテキスト。CGContextなどを保持する
    ///   - rect: 描画するグラフの範囲
    ///   - yAxis: Y軸。Y座標の計算に使われる
    ///   - visibleSpan: 描画するインデックスの範囲
    ///   - dataValues1: 塗りつぶし範囲の片方のラインのプロットデータ
    ///   - getDataValue2:　塗りつぶし範囲のもう片方のラインのプロットを取得する
    ///   - color: 棒の色
    public func draw(context: ChartDrawingContext,
                     rect: CGRect,
                     yAxis: YAxis,
                     visibleSpan: ClosedRange<Int>,
                     dataValues1: NumberArray?,
                     getDataValue2: ((Int) -> CGFloat?),
                     color: UIColor) {
        guard let dataValues1 = dataValues1 else { return }
        
        let cgContext = context.cgContext
        cgContext.saveGState()
        cgContext.setShouldAntialias(true)
        cgContext.clip(to: rect)
        cgContext.setLineJoin(.bevel)
        color.setFill()
        
        // 描画開始
        cgContext.beginPath()
        
        var x = rect.maxX + context.rightOffset + context.xAxisInterval - context.xAxisInterval / 2.0

        var points: [CGPoint] = []
        
        let span = (visibleSpan.lowerBound - 1)...(visibleSpan.upperBound + 1) // 右端足の一つ先まで描画する必要がある
        for i in span.reversed() {
            if let value1 = dataValues1[i], !value1.isNaN, let value2 = getDataValue2(i), !value2.isNaN {
                let y = yAxis.position(value1)
                points += [CGPoint(x: x, y: y)]
            }
            
            x -= context.xAxisInterval
        }
        
        x += context.xAxisInterval
        
        for i in span {
            if let value2 = getDataValue2(i), !value2.isNaN, let value1 = dataValues1[i], !value1.isNaN {
                let y = yAxis.position(value2)
                points += [CGPoint(x: x, y: y)]
            }
            
            x += context.xAxisInterval
        }
        
        // 塗りつぶし
        if 2 <= points.count {
            cgContext.addLines(between: points)
            cgContext.fillPath()
        }
        
        // コンテキストの状態を戻す
        cgContext.restoreGState()
    }
}
