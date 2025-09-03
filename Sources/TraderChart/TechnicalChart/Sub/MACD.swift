//
//  MACD.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/03.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// MACD
open class MACD: TechnicalChart {

    /// 標準のMACD線の色
    static let defaultMacdColor: UIColor = UIColor(rgbHex: "83FF92")
    /// 標準のシグナル線の色
    static let defaultSignalColor: UIColor = UIColor(rgbHex: "FFF97D")
    /// 標準のオシレータ（棒グラフ）正の色
    static let defaultPositiveBarColor: UIColor = UIColor(rgbHex: "C45A58")
    /// 標準のオシレータ（棒グラフ）負の色
    static let defaultNegativeBarColor: UIColor = UIColor(rgbHex: "54B6BF")
    
    open var isVisible: Bool = true
    
    /// MACD線の色
    open var macdColor: UIColor = defaultMacdColor
    /// シグナル線の色
    open var signalColor: UIColor = defaultSignalColor
    /// オシレータ（棒グラフ）正かつ上昇の色
    open var positiveUpBarColor: UIColor = defaultPositiveBarColor
    /// オシレータ（棒グラフ）正かつ下降の色
    open var positiveDownBarColor: UIColor = defaultPositiveBarColor
    /// オシレータ（棒グラフ）負かつ下降の色
    open var negativeDownBarColor: UIColor = defaultNegativeBarColor
    /// オシレータ（棒グラフ）負かつ上昇の色
    open var negativeUpBarColor: UIColor = defaultNegativeBarColor

    /// ラインの幅
    open var lineWidth: CGFloat = 1
    /// X軸間隔に対するオシレータ棒グラフの幅の割合
    open var widthScale: CGFloat = 0.6

    /// パラメータ
    open var param = Param()

    /// 直近の計算に使った短期EMAスパン
    public var latestShortSpan: Int?
    /// 直近の計算に使った長期EMAスパン
    public var latestLongSpan: Int?
    /// 直近の計算に使ったシグナルスパン
    public var latestSignalSpan: Int?
    
    /// MACDの計算結果
    open var results: MACDCalculator.Results?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    /// バーチャートの描画
    open var bar = BarChartDrawer()
    
    /// MACDの計算
    open var calculater = MACDCalculator()

    /// カスタムの凡例
    open var customLegend: ((MACD, Int?) -> Legend?)?

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("MACD:\(param.shortSpan),\(param.longSpan)", macdColor),
            ColorText("シグナル:\(param.signalSpan)", signalColor, visible: param.signalOn)
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
        macdColor = colorConfig["macd.macd"] ?? MACD.defaultMacdColor
        signalColor = colorConfig["macd.signal"] ?? MACD.defaultSignalColor
        positiveUpBarColor = colorConfig["macd.positive_up_bar"] ?? MACD.defaultPositiveBarColor
        positiveDownBarColor = colorConfig["macd.positive_down_bar"] ?? MACD.defaultPositiveBarColor
        negativeDownBarColor = colorConfig["macd.negative_down_bar"] ?? MACD.defaultNegativeBarColor
        negativeUpBarColor = colorConfig["macd.negative_up_bar"] ?? MACD.defaultNegativeBarColor
    }
    
    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        results?.removeLastFrom(updatedFrom)
        results = calculater.update(shortSpan: param.shortSpan, longSpan: param.longSpan, signalSpan: param.signalSpan, src: data?.closeList, results: results)
        latestShortSpan = param.shortSpan
        latestLongSpan = param.longSpan
        latestSignalSpan = param.signalSpan
    }

    public func removeOldData(count: Int) {
        results?.removeFirst(count)
    }

    public func onParameterChanged() {
        if param.shortSpan != latestShortSpan || param.longSpan != latestLongSpan || param.signalSpan != latestSignalSpan {
            results = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.updateRange(0)
        yAxis.updateRangeAll(results?.macd, span: visibleSpan)
        yAxis.updateRangeAll(results?.osc, span: visibleSpan)

        if param.signalOn {
            yAxis.updateRangeAll(results?.signal, span: visibleSpan)
        }
    }
    
    // オシレータの描画色のパターンは以下の通りとする
    // 1."正の値"かつ１つ前の値から"上昇"した場合
    // 2."正の値"かつ１つ前の値から"下降"した場合
    // 3."負の値"かつ１つ前の値から"下降"した場合
    // 4."負の値"かつ１つ前の値から"上昇"した場合
    // ※例外として一番最初のオシレータについては、１つ前の値が存在しない為「正の値は上昇」「負の値は下降」扱いとしている
    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        
        bar.draw(context: context,
                 rect: rect,
                 yAxis: yAxis,
                 visibleSpan: visibleSpan,
                 fromValue: 0.0,
                 toValues: results?.osc,
                 color: positiveUpBarColor,
                 widthScale: widthScale,
                 condition: isPositiveUp)
        
        bar.draw(context: context,
                 rect: rect,
                 yAxis: yAxis,
                 visibleSpan: visibleSpan,
                 fromValue: 0.0,
                 toValues: results?.osc,
                 color: positiveDownBarColor,
                 widthScale: widthScale,
                 condition: isPositiveDown)
        
        bar.draw(context: context,
                 rect: rect,
                 yAxis: yAxis,
                 visibleSpan: visibleSpan,
                 fromValue: 0.0,
                 toValues: results?.osc,
                 color: negativeDownBarColor,
                 widthScale: widthScale,
                 condition: isNegativeDown)
        
        bar.draw(context: context,
                 rect: rect,
                 yAxis: yAxis,
                 visibleSpan: visibleSpan,
                 fromValue: 0.0,
                 toValues: results?.osc,
                 color: negativeUpBarColor,
                 widthScale: widthScale,
                 condition: isNegativeUp)
        
        line.draw(context: context,
                  rect: rect,
                  yAxis: yAxis,
                  visibleSpan: visibleSpan,
                  data: results?.macd,
                  lineWidth: lineWidth,
                  color: macdColor)
        
        if param.signalOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.signal,
                      lineWidth: lineWidth,
                      color: signalColor)
        }
    }
    
    func isPositive(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        guard let to = to else { return false }
        return 0 < to
    }
    
    func isPositiveUp(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        return isPositive(index: index, from: from, to: to) && isUp(index: index, to: to)
    }
    
    func isPositiveDown(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        return isPositive(index: index, from: from, to: to) && isDown(index: index, to: to)
    }
    
    func isNegative(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        guard let to = to else { return false }
        return to < 0
    }
    
    func isNegativeUp(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        return isNegative(index: index, from: from, to: to) && isUp(index: index, to: to)
    }
    
    func isNegativeDown(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        return isNegative(index: index, from: from, to: to) && isDown(index: index, to: to)
    }
    
    func isUp(index: Int, to: CGFloat?) -> Bool {
        guard let to = to else { return false }
        let prev = results?.osc[index - 1] ?? 0
        return prev <= to
    }
    
    func isDown(index: Int, to: CGFloat?) -> Bool {
        guard let to = to else { return false }
        let prev = results?.osc[index - 1] ?? 0
        return to < prev
    }

    public func clear() {
        results = nil
    }

    /// MACDのパラメータ
    public class Param {
        public var signalOn = true
        public var shortSpan = 12
        public var longSpan = 26
        public var signalSpan = 9
        
        public init() {}
    }
}
