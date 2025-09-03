//
//  Volume.swift
//  TraderChart
//
//  Created by altonotes on 2019/07/01.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 出来高
open class Volume: TechnicalChart {
    
    /// 標準の棒グラフの色
    static let defaultBarColor: UIColor = UIColor(rgbHex: "FFF97D")
    /// 標準の移動平均線の色
    static let defaultSmaColor: UIColor = UIColor(rgbHex: "8DFAFF")
    
    open var isVisible: Bool = true

    /// 棒グラフの色
    open var barColor: UIColor = defaultBarColor
    /// 移動平均線の色
    open var smaColor: UIColor = defaultSmaColor
    
    /// X軸の間隔に対する棒グラフ幅の割合
    open var widthScale: CGFloat = 0.6
    /// ラインの幅
    open var lineWidth: CGFloat = 1
    
    /// パラメータ
    open var param = Param()
    
    /// 直近の計算に使ったスパン
    public var latestSmaSpan: Int?
    
    /// 移動平均線の計算結果
    open var sma: NumberArray?
    
    /// 棒グラフの描画
    open var bar = BarChartDrawer()
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// 移動平均の計算
    open var calculater = SMACalculator()
    
    /// カスタムの凡例
    open var customLegend: ((Volume, Int?) -> Legend?)?
    
    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("出来高", barColor, visible: true),
            ColorText("移動平均", smaColor, visible: param.smaOn),
        ])
    }
    
    public func legend(selectedIndex: Int?) -> Legend? {
        if let customLegend = customLegend {
            return customLegend(self, selectedIndex)
        }
        return defaultLegend
    }

    open func reflectColorConfig(_ colorConfig: ColorConfig) {
        barColor = colorConfig["volume.bar"] ?? Volume.defaultBarColor
        smaColor = colorConfig["volume.sma"] ?? Volume.defaultSmaColor
    }
    
    open func updateData(_ data: ChartData?, updatedFrom: Int?) {
        if param.smaOn {
            sma?.removeLastFrom(updatedFrom)
            sma = calculater.calculate(span: param.smaSpan, src: data?.volumeList, existingSMA: sma)
            latestSmaSpan = param.smaSpan
        }
    }
    
    public func removeOldData(count: Int) {
        sma?.removeFirst(count)
    }
    
    public func onParameterChanged() {
        if param.smaSpan != latestSmaSpan {
            sma = nil
        }
    }
    
    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        guard let max = data?.volumeList?.max(from: visibleSpan.lowerBound, span: visibleSpan.count) else { return }
        yAxis.setMinMax(min: 0.0, max: max)
        
        if param.smaOn {
            yAxis.updateRangeAll(sma, span: visibleSpan)
        }
    }
    
    open func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        bar.draw(context: context,
                 rect: rect,
                 yAxis: yAxis,
                 visibleSpan: visibleSpan,
                 fromValue: 0.0,
                 toValues: data?.volumeList,
                 color: barColor,
                 widthScale: widthScale)
        
        if param.smaOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: sma,
                      lineWidth: lineWidth,
                      color: smaColor)
        }
    }
    
    public func clear() {
        sma = nil
    }
    
    /// 出来高移動平均のパラメータ
    public class Param {
        public var smaOn = false
        public var smaSpan = 25
        
        public init() {}
    }
}
