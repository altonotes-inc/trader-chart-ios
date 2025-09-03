//
//  RCI.swift
//  TraderChart
//
//  Created by altonotes on 2019/06/13.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// RCI
open class RCI: TechnicalChart {

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

    /// 直近の計算に使用した短期スパン
    public var latestShortSpan: Int?
    /// 直近の計算に使用した中期スパン
    public var latestMiddleSpan: Int?
    /// 直近の計算に使用した長期スパン
    public var latestLongSpan: Int?
    
    /// 短期線の計算結果
    open var shortRCI: NumberArray?
    /// 中期線の計算結果
    open var middleRCI: NumberArray?
    /// 長期線の計算結果
    open var longRCI: NumberArray?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// RCIの計算
    open var calculater = RCICalculator()

    /// カスタムの凡例
    open var customLegend: ((RCI, Int?) -> Legend?)?

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("RCI:\(param.shortSpan)", shortColor, visible: param.shortOn),
            ColorText("RCI:\(param.middleSpan)", middleColor, visible: param.middleOn),
            ColorText("RCI:\(param.longSpan)", longColor, visible: param.longOn),
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
        shortColor = colorConfig["rci.short"] ?? SMA.defaultShortColor
        middleColor = colorConfig["rci.middle"] ?? SMA.defaultMiddleColor
        longColor = colorConfig["rci.long"] ?? SMA.defaultLongColor
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        if param.shortOn {
            shortRCI?.removeLastFrom(updatedFrom)
            shortRCI = calculater.update(span: param.shortSpan, src: data?.closeList, rciList: shortRCI)
            latestShortSpan = param.shortSpan
        }
        if param.middleOn {
            middleRCI?.removeLastFrom(updatedFrom)
            middleRCI = calculater.update(span: param.middleSpan, src: data?.closeList, rciList: middleRCI)
            latestMiddleSpan = param.middleSpan
        }
        if param.longOn {
            longRCI?.removeLastFrom(updatedFrom)
            longRCI = calculater.update(span: param.longSpan, src: data?.closeList, rciList: longRCI)
            latestLongSpan = param.longSpan
        }
    }

    public func removeOldData(count: Int) {
        shortRCI?.removeFirst(count)
        middleRCI?.removeFirst(count)
        longRCI?.removeFirst(count)
    }

    public func onParameterChanged() {
        if param.shortSpan != latestShortSpan {
            shortRCI = nil
        }
        if param.middleSpan != latestMiddleSpan {
            middleRCI = nil
        }
        if param.longSpan != latestLongSpan {
            longRCI = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.setMinMax(min: -100, max: 100)
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        if param.shortOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: shortRCI,
                      lineWidth: lineWidth,
                      color: shortColor)
        }
        
        if param.middleOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: middleRCI,
                      lineWidth: lineWidth,
                      color: middleColor)
        }
        
        if param.longOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: longRCI,
                      lineWidth: lineWidth,
                      color: longColor)
        }
    }

    public func clear() {
        shortRCI = nil
        middleRCI = nil
        longRCI = nil
    }

    /// RCIのパラメータ
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
