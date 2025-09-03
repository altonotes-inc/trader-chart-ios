//
//  RSI.swift
//  TraderChart
//
//  Created by altonotes on 2019/06/13.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// RSI
open class RSI: TechnicalChart {

    /// 標準の短期線の色
    static let defaultShortColor: UIColor = UIColor(rgbHex: "FFF97D")
    /// 標準の中期線の色
    static let defaultMiddleColor: UIColor = UIColor(rgbHex: "FF7774")
    /// 標準の長期線の色
    static let defaultLongColor: UIColor = UIColor(rgbHex: "8DFAFF")
    
    open var isVisible: Bool = true

    /// 短期線の色
    open var shortColor: UIColor = defaultShortColor
    /// 中期線の色
    open var middleColor: UIColor = defaultMiddleColor
    /// 長期線の色
    open var longColor: UIColor = defaultLongColor
    
    /// ラインの幅
    open var lineWidth: CGFloat = 1
    
    /// パラメータ
    open var param = Param()

    /// 直近の計算に使った短期スパン
    public var latestShortSpan: Int?
    /// 直近の計算に使った中期スパン
    public var latestMiddleSpan: Int?
    /// 直近の計算に使った長期スパン
    public var latestLongSpan: Int?

    /// 短期線の結果
    open var shortResults: RSICalculator.Results?
    /// 中期線の結果
    open var middleResults: RSICalculator.Results?
    /// 長期線の結果
    open var longResults: RSICalculator.Results?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// RSIの計算
    open var calculater = RSICalculator()

    /// カスタムの凡例
    open var customLegend: ((RSI, Int?) -> Legend?)?

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("RSI:\(param.shortSpan)", shortColor, visible: param.shortOn),
            ColorText("RSI:\(param.middleSpan)", middleColor, visible: param.middleOn),
            ColorText("RSI:\(param.longSpan)", longColor, visible: param.longOn),
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
        shortColor = colorConfig["rsi.short"] ?? RSI.defaultShortColor
        middleColor = colorConfig["rsi.middle"] ?? RSI.defaultMiddleColor
        longColor = colorConfig["rsi.long"] ?? RSI.defaultLongColor
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        if param.shortOn {
            shortResults?.removeLastFrom(updatedFrom)
            shortResults = calculater.update(span: param.shortSpan, src: data?.closeList, results: shortResults)
            latestShortSpan = param.shortSpan
        }
        if param.middleOn {
            middleResults?.removeLastFrom(updatedFrom)
            middleResults = calculater.update(span: param.middleSpan, src: data?.closeList, results: middleResults)
            latestMiddleSpan = param.middleSpan
        }
        if param.longOn {
            longResults?.removeLastFrom(updatedFrom)
            longResults = calculater.update(span: param.longSpan, src: data?.closeList, results: longResults)
            latestLongSpan = param.longSpan
        }
    }

    public func removeOldData(count: Int) {
        shortResults?.removeFirst(count)
        middleResults?.removeFirst(count)
        longResults?.removeFirst(count)
    }

    public func onParameterChanged() {
        if param.shortSpan != latestShortSpan {
            shortResults = nil
        }
        if param.middleSpan != latestMiddleSpan {
            middleResults = nil
        }
        if param.longSpan != latestLongSpan {
            longResults = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.setMinMax(min: 0, max: 100)
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        if param.shortOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: shortResults?.rsi,
                      lineWidth: lineWidth,
                      color: shortColor)
        }
        
        if param.middleOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: middleResults?.rsi,
                      lineWidth: lineWidth,
                      color: middleColor)
        }
        
        if param.longOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: longResults?.rsi,
                      lineWidth: lineWidth,
                      color: longColor)
        }
    }

    public func clear() {
        shortResults = nil
        middleResults = nil
        longResults = nil
    }
    
    /// RSIのパラメータ
    public class Param {
        public var shortOn = true
        public var middleOn = true
        public var longOn = true
        public var shortSpan = 9
        public var middleSpan = 14
        public var longSpan = 22
        
        public init() {}
    }
}
