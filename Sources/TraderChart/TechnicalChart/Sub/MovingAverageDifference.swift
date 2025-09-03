//
//  MovingAverageDifference.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/09/04.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 移動平均乖離率
open class MovingAverageDifference: TechnicalChart {

    public var isVisible: Bool = true

    /// 標準の短期ラインの色
    static let defaultShortColor: UIColor = UIColor(rgbHex: "ff6347")
    /// 標準の長期ラインの色
    static let defaultLongColor: UIColor = UIColor(rgbHex: "66cdaa")

    /// 短期ラインの色
    open var shortColor: UIColor = defaultShortColor
    /// 長期ラインの色
    open var longColor: UIColor = defaultLongColor

    /// ラインの幅
    open var lineWidth: CGFloat = 1

    /// カスタムの凡例
    open var customLegend: ((MovingAverageDifference, Int?) -> Legend?)?

    /// パラメータ
    open var param = Param()

    /// 短期線の計算結果
    open var shortResults: NumberArray?
    /// 長期線の計算結果
    open var longResults: NumberArray?

    /// 直近の計算に使った短期スパン
    public var latestShortSpan: Int?
    /// 直近の計算に使った長期スパン
    public var latestLongSpan: Int?

    /// ラインチャートの描画
    open var line = LineChartDrawer()

    /// 移動平均乖離率の計算
    open var calculator = MovingAverageDifferenceCalculator()

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("移動平均乖離率", UIColor.gray),
            ColorText("短期:\(param.shortSpan)", shortColor, visible: param.shortOn),
            ColorText("長期:\(param.longSpan)", longColor, visible: param.longOn),
        ])
    }

    public func legend(selectedIndex: Int?) -> Legend? {
        if let customLegend = customLegend {
            return customLegend(self, selectedIndex)
        }
        return defaultLegend
    }
    
    public func updateData(_ data: ChartData?, updatedFrom: Int?) {
        if param.shortOn {
            shortResults?.removeLastFrom(updatedFrom)
            shortResults = calculator.update(span: param.shortSpan, src: data?.closeList, oldResults: shortResults)
            latestShortSpan = param.shortSpan
        }
        if param.longOn {
            longResults?.removeLastFrom(updatedFrom)
            longResults = calculator.update(span: param.longSpan, src: data?.closeList, oldResults: longResults)
            latestLongSpan = param.longSpan
        }
    }
    
    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        if param.shortOn {
            yAxis.updateRangeAll(shortResults, span: visibleSpan)
        }
        if param.longOn {
            yAxis.updateRangeAll(longResults, span: visibleSpan)
        }
    }
    
    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}
    
    public func clear() {
        shortResults = nil
        longResults = nil
    }
    
    public func onParameterChanged() {
        if param.shortSpan != latestShortSpan {
            shortResults = nil
        }
        if param.longSpan != latestLongSpan {
            longResults = nil
        }
    }
    
    public func removeOldData(count: Int) {
        shortResults?.removeFirst(count)
        longResults?.removeFirst(count)
    }
    
    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        if param.shortOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: shortResults,
                      lineWidth: lineWidth,
                      color: shortColor)
        }

        if param.longOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: longResults,
                      lineWidth: lineWidth,
                      color: longColor)
        }
    }
    
    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        shortColor = colorConfig["moving_average_difference.short"] ?? MovingAverageDifference.defaultShortColor
        longColor = colorConfig["moving_average_difference.long"] ?? MovingAverageDifference.defaultLongColor
    }
    
    public class Param {
        public var shortSpan = 5
        public var longSpan = 25
        public var shortOn = true
        public var longOn = true

        public init() {}
    }
}
