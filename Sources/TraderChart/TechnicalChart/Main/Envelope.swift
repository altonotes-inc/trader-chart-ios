//
//  Envelope.swift
//  TraderChart
//
//  Created by altonotes on 2019/08/29.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// エンベロープ
open class Envelope: TechnicalChart {
    
    /// 標準の移動平均線の色
    static let defaultSmaColor: UIColor = UIColor(rgbHex: "7F7F7F")
    /// 標準の上方乖離線の色
    static let defaultUpperColor: UIColor = UIColor(rgbHex: "FFE67F")
    /// 標準の上方乖離線（2倍）の色
    static let defaultUpperDoubleColor: UIColor = UIColor(rgbHex: "FF9047")
    /// 標準の下方乖離線の色
    static let defaultLowerColor: UIColor = UIColor(rgbHex: "FFE67F")
    /// 標準の下方乖離線（2倍）の色
    static let defaultLowerDoubleColor: UIColor = UIColor(rgbHex: "FF9047")
    
    open var isVisible: Bool = true
    
    /// 移動平均線の色
    open var smaColor: UIColor = defaultSmaColor
    /// 上方乖離線の色
    open var upperColor: UIColor = defaultUpperColor
    /// 上方乖離線（2倍）の色
    open var upperDoubleColor: UIColor = defaultUpperDoubleColor
    /// 下方乖離線の色
    open var lowerColor: UIColor = defaultLowerColor
    /// 下方乖離線（2倍）の色
    open var lowerDoubleColor: UIColor = defaultLowerDoubleColor

    /// ラインの太さ
    open var lineWidth: CGFloat = 1
    
    /// 計算パラメータ
    open var param = Param()
    
    /// 移動平均の計算結果
    open var smaList: NumberArray?
    /// 上方乖離線の計算結果
    open var upperList: [NumberArray]?
    /// 下方乖離線の計算結果
    open var lowerList: [NumberArray]?
    
    /// 直近の計算に使ったスパン
    open var latestSpan: Int?
    /// 直近の計算に使った上方乖離率
    open var latestUpperPercentage: CGFloat?
    /// 直近の計算に使った下方乖離率
    open var latestLowerPercentage: CGFloat?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// 移動平均の計算
    open var smaCalculater = SMACalculator()
    /// エンベロープの計算
    open var envelopeCalculater = EnvelopeCalculator()
    
    /// カスタムの凡例
    open var customLegend: ((Envelope, Int?) -> Legend?)?
    
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("期間：\(param.span)", UIColor.gray),
            ColorText("上方乖離率：\(param.upperPercentage)", upperColor, visible: param.upperOn),
            ColorText("下方乖離率：\(param.lowerPercentage)", lowerColor, visible: param.lowerOn),
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
        smaColor = colorConfig["envelope.sma"] ?? Envelope.defaultSmaColor
        upperColor = colorConfig["envelope.upper"] ?? Envelope.defaultUpperColor
        upperDoubleColor = colorConfig["envelope.upper_double"] ?? Envelope.defaultUpperDoubleColor
        lowerColor = colorConfig["envelope.lower"] ?? Envelope.defaultLowerColor
        lowerDoubleColor = colorConfig["envelope.lower_double"] ?? Envelope.defaultLowerDoubleColor
    }
    
    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        smaList?.removeLastFrom(updatedFrom)
        smaList = smaCalculater.calculate(span: param.span, src: data?.closeList, existingSMA: smaList)
        
        let upperRate = param.upperPercentage / 100
        let upperRates = param.doubleOn ? [1.0 + upperRate, 1.0 + upperRate * 2] : [1.0 + upperRate]
        upperList?.forEach { $0.removeLastFrom(updatedFrom) }
        upperList = envelopeCalculater.update(span: param.span, rates: upperRates, src: data?.highList, results: upperList)
        
        let lowerRate = param.lowerPercentage / 100
        let lowerRates = param.doubleOn ? [1.0 - lowerRate, 1.0 - lowerRate * 2] : [1.0 - lowerRate]
        lowerList?.forEach { $0.removeLastFrom(updatedFrom) }
        lowerList = envelopeCalculater.update(span: param.span, rates: lowerRates, src: data?.lowList, results: lowerList)

        latestSpan = param.span
        latestUpperPercentage = param.upperPercentage
        latestLowerPercentage = param.lowerPercentage
    }
    
    public func removeOldData(count: Int) {
        smaList?.removeFirst(count)
        upperList?.forEach { $0.removeFirst(count) }
        lowerList?.forEach { $0.removeFirst(count) }
    }
    
    public func onParameterChanged() {
        if param.span != latestSpan {
            smaList = nil
            upperList = nil
            lowerList = nil
        }
        if param.upperPercentage != latestUpperPercentage {
            upperList = nil
        }
        if param.lowerPercentage != latestLowerPercentage {
            lowerList = nil
        }
    }
    
    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}
    
    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        if param.smaOn {
            yAxis.updateRangeAll(smaList, span: visibleSpan)
        }
        
        if param.upperOn {
            yAxis.updateRangeAll(upperList?.last, span: visibleSpan)
        }
        
        if param.lowerOn {
            yAxis.updateRangeAll(lowerList?.last, span: visibleSpan)
        }
    }
    
    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        if param.smaOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: smaList,
                      lineWidth: lineWidth,
                      color: smaColor)
        }
        if param.upperOn {
            let colors = [upperColor, upperDoubleColor]
            upperList?.enumerated().forEach { offset, data in
                line.draw(context: context,
                          rect: rect,
                          yAxis: yAxis,
                          visibleSpan: visibleSpan,
                          data: data,
                          lineWidth: lineWidth,
                          color: colors[offset])
            }
        }
        if param.lowerOn {
            let colors = [lowerColor, lowerDoubleColor]
            lowerList?.enumerated().forEach { offset, data in
                line.draw(context: context,
                          rect: rect,
                          yAxis: yAxis,
                          visibleSpan: visibleSpan,
                          data: data,
                          lineWidth: lineWidth,
                          color: colors[offset])
            }
        }
    }
    
    public func clear() {
        smaList = nil
        upperList = nil
        lowerList = nil
    }
    
    /// エンベロープのパラメータ
    public class Param {
        public var upperPercentage: CGFloat = 0.5
        public var lowerPercentage: CGFloat = 0.5
        public var smaOn = true
        public var upperOn = true
        public var lowerOn = true
        public var doubleOn = true
        public var span = 25
        
        public init() {}
    }
}
