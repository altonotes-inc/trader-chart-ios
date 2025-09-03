//
//  EMA.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 指数平滑移動平均
open class EMA: TechnicalChart {

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

    /// 計算のパラメータ
    open var param = Param()

    /// 直近の計算に使った短期スパン
    public var latestShortSpan: Int?
    /// 直近の計算に使った中期スパン
    public var latestMiddleSpan: Int?
    /// 直近の計算に使った長期スパン
    public var latestLongSpan: Int?

    /// 短期線の計算結果
    open var shortEMA: NumberArray?
    /// 中期線の計算結果
    open var middleEMA: NumberArray?
    /// 長期線の計算結果
    open var longEMA: NumberArray?
    
    /// ラインの描画
    open var line = LineChartDrawer()
    
    /// 指数平滑移動平均の計算
    open var calculater = EMACalculator()

    /// カスタムの凡例
    open var customLegend: ((EMA, Int?) -> Legend?)?

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("EMA:\(param.shortSpan)", shortColor, visible: param.shortOn),
            ColorText("EMA:\(param.middleSpan)", middleColor, visible: param.middleOn),
            ColorText("EMA:\(param.longSpan)", longColor, visible: param.longOn),
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
        shortColor = colorConfig["ema.short"] ?? SMA.defaultShortColor
        middleColor = colorConfig["ema.middle"] ?? SMA.defaultMiddleColor
        longColor = colorConfig["ema.long"] ?? SMA.defaultLongColor
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        if param.shortOn {
            shortEMA?.removeLastFrom(updatedFrom)
            shortEMA = calculater.update(span: param.shortSpan, src: data?.closeList, emaList: shortEMA)
            latestShortSpan = param.shortSpan
        }
        if param.middleOn {
            middleEMA?.removeLastFrom(updatedFrom)
            middleEMA = calculater.update(span: param.middleSpan, src: data?.closeList, emaList: middleEMA)
            latestMiddleSpan = param.middleSpan
        }
        if param.longOn {
            longEMA?.removeLastFrom(updatedFrom)
            longEMA = calculater.update(span: param.longSpan, src: data?.closeList, emaList: longEMA)
            latestLongSpan = param.longSpan
        }
    }

    public func removeOldData(count: Int) {
        shortEMA?.removeFirst(count)
        middleEMA?.removeFirst(count)
        longEMA?.removeFirst(count)
    }

    public func onParameterChanged() {
        if param.shortSpan != latestShortSpan {
            shortEMA = nil
        }
        if param.middleSpan != latestMiddleSpan {
            middleEMA = nil
        }
        if param.longSpan != latestLongSpan {
            longEMA = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        if param.shortOn {
            yAxis.updateRangeAll(shortEMA, span: visibleSpan)
        }
        
        if param.middleOn {
            yAxis.updateRangeAll(middleEMA, span: visibleSpan)
        }
        
        if param.longOn {
            yAxis.updateRangeAll(longEMA, span: visibleSpan)
        }
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        if param.shortOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: shortEMA,
                      lineWidth: lineWidth,
                      color: shortColor)
        }
        
        if param.middleOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: middleEMA,
                      lineWidth: lineWidth,
                      color: middleColor)
        }
        
        if param.longOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: longEMA,
                      lineWidth: lineWidth,
                      color: longColor)
        }
    }

    public func clear() {
        shortEMA = nil
        middleEMA = nil
        longEMA = nil
    }

    /// 指数平滑移動平均のパラメータ
    public class Param {
        public var shortOn = true
        public var middleOn = true
        public var longOn = true
        public var shortSpan = 5
        public var middleSpan = 25
        public var longSpan = 75
        
        public init() {}
    }
}
