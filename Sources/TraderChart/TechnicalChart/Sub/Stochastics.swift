//
//  Stochastics.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/03.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// ストキャスティクス
open class Stochastics: TechnicalChart {

    /// 標準の%K線の色
    static let defaultKColor: UIColor = UIColor(rgbHex: "E070FF")
    /// 標準の%D線の色
    static let defaultDColor: UIColor = UIColor(rgbHex: "FFF97D")
    /// 標準のSlow%D線の色
    static let defaultSlowDColor: UIColor = UIColor(rgbHex: "83FF92")
    
    open var isVisible: Bool = true
    
    /// %K線の色
    open var kColor: UIColor = defaultKColor
    /// %D線の色
    open var dColor: UIColor = defaultDColor
    /// Slow%D線の色
    open var slowDColor: UIColor = defaultSlowDColor
    
    /// ラインの幅
    open var lineWidth: CGFloat = 1
    
    /// パラメータ
    open var param = Param()

    /// 直近の計算に使用した%Kスパン
    public var latestKSpan: Int?
    /// 直近の計算に使用した%Dスパン
    public var latestDSpan: Int?
    /// 直近の計算に使用したSlow%Dスパン
    public var latestSlowDSpan: Int?

    /// ストキャスティクスの計算結果
    open var results: StochasticsCalculator.Results?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// ストキャスティクスの計算
    open var calculater = StochasticsCalculator()

    /// カスタムの凡例
    open var customLegend: ((Stochastics, Int?) -> Legend?)?

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("%K:\(param.kSpan)", kColor, visible: param.kOn),
            ColorText("%D:\(param.dSpan)", dColor, visible: param.dOn),
            ColorText("Slow%D:\(param.slowDSpan)", slowDColor, visible: param.slowDOn),
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
        kColor = colorConfig["stochastics.k"] ?? Stochastics.defaultKColor
        dColor = colorConfig["stochastics.d"] ?? Stochastics.defaultDColor
        slowDColor = colorConfig["stochastics.slowD"] ?? Stochastics.defaultSlowDColor
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        if param.kOn || param.dOn || param.slowDOn {
            results?.removeLastFrom(updatedFrom)
            results = calculater.update(kSpan: param.kSpan, dSpan: param.dSpan, sdSpan: param.slowDSpan, closeList: data?.closeList, highList: data?.highList, lowList: data?.lowList, results: results)
            latestKSpan = param.kSpan
            latestDSpan = param.dSpan
            latestSlowDSpan = param.slowDSpan
        }
    }

    public func removeOldData(count: Int) {
        results?.removeFirst(count)
    }

    public func onParameterChanged() {
        if param.kSpan != latestKSpan
            || param.dSpan != latestDSpan
            || param.slowDSpan != latestSlowDSpan {
            results = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.setMinMax(min: 0, max: 100)
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        if param.kOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.kList,
                      lineWidth: lineWidth,
                      color: kColor)
        }
        
        if param.dOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.dList,
                      lineWidth: lineWidth,
                      color: dColor)
        }
        
        if param.slowDOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.sdList,
                      lineWidth: lineWidth,
                      color: slowDColor)
        }
    }

    public func clear() {
        results = nil
    }
    
    /// ストキャスティクスのパラメータ
    public class Param {
        public var kOn = true
        public var dOn = true
        public var slowDOn = false
        public var kSpan = 5
        public var dSpan = 3
        public var slowDSpan = 3
        
        public init() {}
    }
}
