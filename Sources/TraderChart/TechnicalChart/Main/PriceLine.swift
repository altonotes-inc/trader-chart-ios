//
//  PriceLine.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/24.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 終値のラインチャート
open class PriceLine: SimpleTechnicalChart {
    
    /// 標準のラインの色
    static let defaultLineColor: UIColor = UIColor(rgbHex: "FFFFFF")
    /// 標準の塗りつぶしの色
    static let defaultFillColor: UIColor = UIColor(argbHex: "#40FFFFFF")

    /// ラインの色
    open var lineColor: UIColor = defaultLineColor
    /// 塗りつぶしの色
    open var fillColor: UIColor = defaultFillColor

    /// ラインの幅
    open var lineWidth: CGFloat = 1
    
    /// ラインチャートの描画
    open var line: LineChartDrawer = LineChartDrawer()
    /// 塗りつぶし
    open var filling: FillingAreaDrawer?

    /// 初期化
    public init(fillBottom: Bool = false) {
        self.line = LineChartDrawer()
        
        if fillBottom {
            self.filling = FillingAreaDrawer()
        }
    }
    
    open override func reflectColorConfig(_ colorConfig: ColorConfig) {
        lineColor = colorConfig["price_line.line"] ?? PriceLine.defaultLineColor
        fillColor = colorConfig["price_line.fill"] ?? PriceLine.defaultFillColor
    }

    open override func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.updateRangeAll(data?.closeList, span: visibleSpan)
    }

    open override func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        line.draw(context: context,
                  rect: rect,
                  yAxis: yAxis,
                  visibleSpan: visibleSpan,
                  data: data?.closeList,
                  lineWidth: lineWidth,
                  color: lineColor)
        
        filling?.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      dataValues1: data?.closeList,
                      dataValue2: yAxis.bottom,
                      color: fillColor)
    }
}
