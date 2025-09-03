//
//  Psychological.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/09/04.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// サイコロジカル
open class Psychological: TechnicalChart {
    public var isVisible: Bool = true

    /// 標準のラインの色
    static let defaultLineColor: UIColor = UIColor(rgbHex: "ff6347")

    /// ラインチャートの描画
    open var line = LineChartDrawer()

    /// ラインの色
    open var lineColor: UIColor = defaultLineColor

    /// ラインの幅
    open var lineWidth: CGFloat = 1

    /// パラメータ
    open var param = Param()

    /// カスタムの凡例
    open var customLegend: ((Psychological, Int?) -> Legend?)?

    /// 計算結果
    public var results: NumberArray?

    var calculator = PsychologicalCalculator()

    var latestSpan: Int?

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("サイコロジカル:\(param.span)", lineColor)
        ])
    }

    public func legend(selectedIndex: Int?) -> Legend? {
        if let customLegend = customLegend {
            return customLegend(self, selectedIndex)
        }
        return defaultLegend
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int?) {
        results?.removeLastFrom(updatedFrom)
        results = calculator.update(span: param.span, src: data?.closeList, oldResults: results)
        latestSpan = param.span
    }

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.setMinMax(min: 0, max: 100)
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) { }

    public func clear() {
        results = nil
    }

    public func onParameterChanged() {
        if param.span != latestSpan {
            results = nil
        }
    }

    public func removeOldData(count: Int) {
        results?.removeFirst(count)
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        line.draw(context: context,
                  rect: rect,
                  yAxis: yAxis,
                  visibleSpan: visibleSpan,
                  data: results,
                  lineWidth: lineWidth,
                  color: lineColor)
    }

    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        lineColor = colorConfig["psychological.line"] ?? Psychological.defaultLineColor
    }

    public class Param {
        public var span = 12
        public init() {}
    }
}
