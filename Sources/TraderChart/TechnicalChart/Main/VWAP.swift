//
//  VWAP.swift
//  TraderChart
//
//  Created by altonotes on 2019/08/28.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// VWAP
open class VWAP: SimpleTechnicalChart {
    
    /// 標準のラインの色
    static let defaultLineColor: UIColor = UIColor(rgbHex: "FFCC4D")
    
    /// ラインの色
    open var lineColor: UIColor = defaultLineColor
    
    /// ラインの幅
    open var lineWidth: CGFloat = 1
    
    /// ラインチャートの描画
    open var line: LineChartDrawer = LineChartDrawer()
    
    /// カスタムの凡例
    open var customLegend: ((VWAP, Int?) -> Legend?)?
    
    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([ColorText("VWAP", lineColor)])
    }
    
    public override func legend(selectedIndex: Int?) -> Legend? {
        if let customLegend = customLegend {
            return customLegend(self, selectedIndex)
        }
        return defaultLegend
    }
    
    open override func reflectColorConfig(_ colorConfig: ColorConfig) {
        lineColor = colorConfig["vwap.line"] ?? VWAP.defaultLineColor
    }
    
    open override func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.updateRangeAll(data?.vwapList, span: visibleSpan)
    }
    
    open override func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        line.draw(context: context,
                  rect: rect,
                  yAxis: yAxis,
                  visibleSpan: visibleSpan,
                  data: data?.vwapList,
                  lineWidth: lineWidth,
                  color: lineColor)
    }
}
