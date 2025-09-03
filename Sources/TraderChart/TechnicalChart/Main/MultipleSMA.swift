//
//  MultipleSMA.swift
//  TraderChart
//
//  Created by altonotes on 2019/08/29.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 多重移動平均
open class MultipleSMA: TechnicalChart {
    
    /// 標準のラインの色
    static let defaultLineColor: UIColor = UIColor(rgbHex: "FFF97D")
    
    open var isVisible: Bool = true
    
    /// ラインの色
    open var lineColor: UIColor = defaultLineColor
    
    /// ラインの幅
    open var lineWidth: CGFloat = 0.5
    
    /// パラメータ
    open var param = Param()
    
    /// 直近の計算に使った最短スパン
    public var latestMinSpan: Int?
    /// 直近の計算に使った最長スパン
    public var latestMaxSpan: Int?
    /// 直近の計算に使った本数
    public var latestLineCount: Int?
    
    /// 計算結果
    open var results: [NumberArray?]?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// 移動平均の計算
    open var calculater = SMACalculator()
    
    /// カスタムの凡例
    open var customLegend: ((MultipleSMA, Int?) -> Legend?)?
    
    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("多重移動平均", lineColor),
            ColorText("最短期間:\(param.minSpan)", lineColor),
            ColorText("最長期間:\(param.maxSpan)", lineColor)
        ])
    }
    
    public func legend(selectedIndex: Int?) -> Legend? {
        if let customLegend = customLegend {
            return customLegend(self, selectedIndex)
        }
        return defaultLegend
    }
    
    /// 初期化
    public init() {}
    
    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        lineColor = colorConfig["multiple_sma.line"] ?? MultipleSMA.defaultLineColor
    }
    
    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        let step = Double(param.maxSpan - param.minSpan) / Double(param.lineCount - 1)
        let spanList = (0..<param.lineCount).map { index in
            Int(round(Double(param.minSpan) + step * Double(index)))
        }
        
        results?.forEach { $0?.removeLastFrom(updatedFrom) }
        results = spanList.enumerated().map { (offset, span) -> NumberArray? in
            return calculater.calculate(span: span, src: data?.closeList, existingSMA: results?[offset])
        }
        latestMinSpan = param.minSpan
        latestMaxSpan = param.maxSpan
        latestLineCount = param.lineCount
    }
    
    public func removeOldData(count: Int) {
        results?.forEach { sma in
            sma?.removeFirst(count)
        }
    }
    
    public func onParameterChanged() {
        if param.minSpan != latestMinSpan || param.maxSpan != latestMaxSpan || param.lineCount != latestLineCount {
            results = nil
        }
    }
    
    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}
    
    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        results?.forEach { sma in
            yAxis.updateRangeAll(sma, span: visibleSpan)
        }
    }
    
    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        results?.forEach { sma in
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: sma,
                      lineWidth: lineWidth,
                      color: lineColor)
        }
    }
    
    public func clear() {
        results = nil
    }
    
    /// 移動平均のパラメータ
    public class Param {
        public var minSpan = 5
        public var maxSpan = 75
        public var lineCount = 15
        
        public init() {}
    }
}
