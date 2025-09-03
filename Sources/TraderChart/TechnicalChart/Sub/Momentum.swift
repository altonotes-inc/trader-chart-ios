//
//  Momentum.swift
//  TraderChart
//
//  Created by altonotes on 2019/08/30.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// モメンタム
open class Momentum: TechnicalChart {
    
    /// 標準のラインの色
    static let defaultLineColor: UIColor = UIColor(rgbHex: "FFF97D")
    
    open var isVisible: Bool = true
    
    /// ラインの色
    open var lineColor: UIColor = defaultLineColor
    
    /// ラインの幅
    open var lineWidth: CGFloat = 1
    
    /// パラメータ
    open var param = Param()
    
    /// 直近の計算に使ったスパン
    public var latestSpan: Int?
    
    /// 結果
    open var results: NumberArray?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// モメンタムの計算
    open var calculater = MomentumCalculator(type: .subtract)
    
    /// カスタムの凡例
    open var customLegend: ((Momentum, Int?) -> Legend?)?
    
    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([ColorText("モメンタム:\(param.span)", lineColor)])
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
        lineColor = colorConfig["momentum.line"] ?? Momentum.defaultLineColor
    }
    
    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        results?.removeLastFrom(updatedFrom)
        results = calculater.update(span: param.span, src: data?.closeList, momentumList: results)
        latestSpan = param.span
    }
    
    public func removeOldData(count: Int) {
        results?.removeFirst(count)
    }
    
    public func onParameterChanged() {
        if param.span != latestSpan {
            results = nil
        }
    }
    
    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}
    
    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.updateRangeAll(results, span: visibleSpan)
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
    
    public func clear() {
        results = nil
    }
    
    /// モメンタムのパラメータ
    public class Param {
        public var span = 25
        
        public init() {}
    }
}
