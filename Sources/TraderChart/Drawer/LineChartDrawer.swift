//
//  LineChartDrawer.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/23.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 線グラフの描画
open class LineChartDrawer {

    /// ラインの折れ目に点を描画するか
    var drawDot: Bool = false

    public init(drawDot: Bool = false) {
        self.drawDot = drawDot
    }

    /// ラインチャートを描画する
    ///
    /// - Parameters:
    ///   - context: 描画コンテキスト。CGContextなどを保持する
    ///   - rect: 描画するグラフの範囲
    ///   - yAxis: Y軸。Y座標の計算に使われる
    ///   - visibleSpan: 描画するインデックスの範囲
    ///   - data: 描画するプロットのデータ
    ///   - lineWidth: ラインの幅
    ///   - dotSize: 折れ目に描画する点のサイズ
    ///   - color: ラインおよび点の色
    func draw(context: ChartDrawingContext,
              rect: CGRect,
              yAxis: YAxis,
              visibleSpan: ClosedRange<Int>,
              data: NumberArray?,
              lineWidth: CGFloat,
              dotSize: CGFloat = 6.0,
              color: UIColor) {
        guard let data = data else { return }

        let cgContext = context.cgContext

        cgContext.saveGState()
        cgContext.setShouldAntialias(true)
        cgContext.clip(to: rect)
        cgContext.setLineWidth(lineWidth)
        cgContext.setLineJoin(.bevel) // ラインの折れ方
        color.setStroke()

        // 描画開始
        cgContext.beginPath()

        var x = rect.maxX + context.rightOffset + context.xAxisInterval - context.xAxisInterval / 2.0

        var allPoints: [CGPoint?] = []
        
        // 端までラインを引くため表示範囲の一つ隣まで範囲を伸ばす
        let span = (visibleSpan.lowerBound - 1)...(visibleSpan.upperBound + 1)
        for i in span.reversed() {
            if let value = data[i], !value.isNaN {
                let y = yAxis.position(value)
                allPoints.append(CGPoint(x: x, y: y))
            } else {
                allPoints.append(nil)
            }
            
            x -= context.xAxisInterval
        }
        
        var tempPoints: [CGPoint] = []
        for point in allPoints {
            if let point = point {
                tempPoints.append(point)
            } else if 0 < tempPoints.count {
                cgContext.addLines(between: tempPoints)
                tempPoints.removeAll()
            }
        }

        if 2 <= tempPoints.count {
            cgContext.addLines(between: tempPoints)
        }

        // ラインを描画
        cgContext.strokePath()
        
        if drawDot {
            let halfDotSize = dotSize / 2
            allPoints.compactMap { $0 }.forEach { point in
                cgContext.addEllipse(in: CGRect(x: point.x - halfDotSize, y: point.y - halfDotSize, width: dotSize, height: dotSize))
            }
            color.setFill()
            cgContext.fillPath()
        }
        // コンテキストの状態を戻す
        cgContext.restoreGState()
    }
}
