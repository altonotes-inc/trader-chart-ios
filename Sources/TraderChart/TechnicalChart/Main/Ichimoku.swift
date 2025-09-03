//
//  Ichimoku.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/03.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 一目均衡表
open class Ichimoku: TechnicalChart {

    /// 標準の先行線1の色
    static let defaultSenko1Color: UIColor = UIColor(rgbHex: "#FFB575")
    /// 標準の先行線2の色
    static let defaultSenko2Color: UIColor = UIColor(rgbHex: "#E070FF")
    /// 標準の遅行線の色
    static let defaultChikoColor: UIColor = UIColor(rgbHex: "#FFF97D")
    /// 標準の基準線の色
    static let defaultKijunColor: UIColor = UIColor(rgbHex: "#83FF92")
    /// 標準の転換線の色
    static let defaultTenkanColor: UIColor = UIColor(rgbHex: "#FF7774")
    /// 標準の雲の色
    static let defaultCloudColor: UIColor = UIColor(argbHex: "#40FFFFFF")
    
    open var isVisible: Bool = true

    /// 先行線1の色
    open var senko1Color: UIColor = defaultSenko1Color
    /// 先行線2の色
    open var senko2Color: UIColor = defaultSenko2Color
    /// 遅行線の色
    open var chikoColor: UIColor = defaultChikoColor
    /// 基準線の色
    open var kijunColor: UIColor = defaultKijunColor
    /// 転換線の色
    open var tenkanColor: UIColor = defaultTenkanColor
    /// 雲の色
    open var cloudColor: UIColor = defaultCloudColor
    
    /// ラインの幅
    open var lineWidth: CGFloat = 1
    
    /// パラメータ
    open var param = Param()

    /// 直近の計算に使った転換スパン
    public var latestTenkanSpan: Int?
    /// 直近の計算に使った基準スパン
    public var latestKijunSpan: Int?
    /// 直近の計算に使ったスパン
    public var latestSpan: Int?

    /// 一目均衡表の計算結果
    open var results: IchimokuCalculator.Results?
    
    /// ラインの描画
    open var line = LineChartDrawer()
    /// 塗りつぶし
    open var filling = FillingAreaDrawer()
    
    /// 一目均衡表の計算
    open var calculater = IchimokuCalculator()

    /// カスタムの凡例
    open var customLegend: ((Ichimoku, Int?) -> Legend?)?

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend(lines: [
            [
                ColorText("基準線:\(param.kijunSpan)", kijunColor, visible: param.kijunOn),
                ColorText("転換線:\(param.tenkanSpan)", tenkanColor, visible: param.tenkanOn)
            ],
            [
                ColorText("先行線1:\(param.span)", senko1Color, visible: param.senkoChikoOn),
                ColorText("先行線2:\(param.span * 2)", senko2Color, visible: param.senkoChikoOn),
                ColorText("遅行線", chikoColor, visible: param.senkoChikoOn)
            ],
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
        senko1Color = colorConfig["ichimoku.senkosen1"] ?? Ichimoku.defaultSenko1Color
        senko2Color = colorConfig["ichimoku.senkosen2"] ?? Ichimoku.defaultSenko2Color
        chikoColor = colorConfig["ichimoku.chikosen"] ?? Ichimoku.defaultChikoColor
        kijunColor = colorConfig["ichimoku.kijunsen"] ?? Ichimoku.defaultKijunColor
        tenkanColor = colorConfig["ichimoku.tenkansen"] ?? Ichimoku.defaultTenkanColor
        cloudColor = colorConfig["ichimoku.cloud"] ?? Ichimoku.defaultCloudColor
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {

        if let updatedFrom = updatedFrom {
            results?.tenkan.removeLastFrom(updatedFrom)
            results?.kijun.removeLastFrom(updatedFrom)
            results?.chiko.removeLastFrom(updatedFrom)
            results?.senko2.removeLastFrom(updatedFrom + param.span - 1)
            results?.senko1.removeLastFrom(updatedFrom + param.span - 1)
        }

        results = calculater.update(span: param.span,
                                    tenkanSpan: param.tenkanSpan,
                                    kijunSpan: param.kijunSpan,
                                    highList: data?.highList,
                                    lowList: data?.lowList,
                                    closeList: data?.closeList,
                                    results: results)

        latestSpan = param.span
        latestTenkanSpan = param.tenkanSpan
        latestKijunSpan = param.kijunSpan
    }

    public func removeOldData(count: Int) {
        results?.removeFirst(count)
    }

    public func onParameterChanged() {
        if param.span != latestSpan || param.tenkanSpan != latestTenkanSpan || param.kijunSpan != latestKijunSpan {
            results = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {
        guard let data = data else { return }
        // Span分X軸を伸ばす
        let additionalTime = Array(repeating: "", count: param.span)
        var axisData = Array(data.timeList)
        axisData.append(contentsOf: additionalTime)
        xAxis.dataList = axisData
    }

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        if param.tenkanOn {
            yAxis.updateRangeAll(results?.tenkan, span: visibleSpan)
        }
        if param.kijunOn {
            yAxis.updateRangeAll(results?.kijun, span: visibleSpan)
        }
        if param.senkoChikoOn {
            yAxis.updateRangeAll(results?.senko1, span: visibleSpan)
            yAxis.updateRangeAll(results?.senko2, span: visibleSpan)
            yAxis.updateRangeAll(results?.chiko, span: visibleSpan)
        }
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        if param.tenkanOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.tenkan,
                      lineWidth: lineWidth,
                      color: tenkanColor)
        }
        
        if param.kijunOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.kijun,
                      lineWidth: lineWidth,
                      color: kijunColor)
        }
        
        if param.senkoChikoOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.senko1,
                      lineWidth: lineWidth,
                      color: senko1Color)
            
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.senko2,
                      lineWidth: lineWidth,
                      color: senko2Color)
            
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.chiko,
                      lineWidth: lineWidth,
                      color: chikoColor)
            
            filling.draw(context: context,
                         rect: rect,
                         yAxis: yAxis,
                         visibleSpan: visibleSpan,
                         dataValues1: results?.senko1,
                         dataValues2: results?.senko2,
                         color: cloudColor)
        }
    }

    public func clear() {
        results = nil
    }

    /// 一目均衡表のパラメータ
    public class Param {
        public var tenkanOn = true
        public var kijunOn = true
        public var senkoChikoOn = true
        public var tenkanSpan = 9
        public var kijunSpan = 26
        public var span = 26
        
        public init() {}
    }
}
