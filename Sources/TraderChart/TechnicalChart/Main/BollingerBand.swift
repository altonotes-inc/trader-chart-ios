//
//  BollingerBand.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/03.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// ボリンジャーバンド
open class BollingerBand: TechnicalChart {

    /// 標準の移動平均線の色
    static let defaultSmaColor: UIColor = UIColor(rgbHex: "FFFFFF")
    /// 標準の1つめのシグマ乖離線（プラス・マイナス）の色
    static let defaultSigma1Color: UIColor = UIColor(rgbHex: "5E6EC7")
    /// 標準の2つめのシグマ乖離線（プラス・マイナス）の色
    static let defaultSigma2Color: UIColor = UIColor(rgbHex: "8DFAFF")
    /// 標準の3つめのシグマ乖離線（プラス・マイナス）の色
    static let defaultSigma3Color: UIColor = UIColor(rgbHex: "83FF92")
    
    open var isVisible: Bool = true

    /// 移動平均線の色
    open var smaColor: UIColor = defaultSmaColor
    /// 1つめのシグマ乖離線（プラス・マイナス）の色
    open var sigma1Color: UIColor = defaultSigma1Color
    /// 1つめのシグマ乖離線（プラス・マイナス）の色
    open var sigma2Color: UIColor = defaultSigma2Color
    /// 1つめのシグマ乖離線（プラス・マイナス）の色
    open var sigma3Color: UIColor = defaultSigma3Color
    /// シグマ乖離線の色の配列
    open var sigmaColors: [UIColor] {
        return [sigma1Color, sigma2Color, sigma3Color]
    }
    /// ラインの太さ
    open var lineWidth: CGFloat = 1
    
    /// 計算パラメータ
    open var param = Param()
    
    /// 計算結果
    open var results: BollingerBandCalculator.Results?

    /// 直近の計算に使ったスパン
    open var latestSpan: Int?
    /// 直近の計算に使ったシグマ1のレート
    open var latestSigma1Rate: CGFloat?
    /// 直近の計算に使ったシグマ2のレート
    open var latestSigma2Rate: CGFloat?
    /// 直近の計算に使ったシグマ3のレート
    open var latestSigma3Rate: CGFloat?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// ボリンジャーバンドの計算
    open var calculater = BollingerBandCalculator()

    /// カスタムの凡例
    open var customLegend: ((BollingerBand, Int?) -> Legend?)?

    open var defaultLegend: Legend? {
        return Legend([
            ColorText("ボリンジャー", UIColor.white),
            ColorText("±\(param.sigma1Rate.stringValue(decimalLength: 1))σ", sigma1Color, visible: param.sigma1On),
            ColorText("±\(param.sigma2Rate.stringValue(decimalLength: 1))σ", sigma2Color, visible: param.sigma2On),
            ColorText("±\(param.sigma3Rate.stringValue(decimalLength: 1))σ", sigma3Color, visible: param.sigma3On),
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
        smaColor = colorConfig["bollinger_band.sma"] ?? BollingerBand.defaultSmaColor
        sigma1Color = colorConfig["bollinger_band.sigma1"] ?? BollingerBand.defaultSigma1Color
        sigma2Color = colorConfig["bollinger_band.sigma2"] ?? BollingerBand.defaultSigma2Color
        sigma3Color = colorConfig["bollinger_band.sigma3"] ?? BollingerBand.defaultSigma3Color
    }
    
    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        results?.removeLastFrom(updatedFrom)
        results = calculater.update(span: param.span,
                                    closeList: data?.closeList,
                                    sigmaRates: [param.sigma1Rate, param.sigma2Rate, param.sigma3Rate],
                                    results: results)
        latestSpan = param.span
        latestSigma1Rate = param.sigma1Rate
        latestSigma2Rate = param.sigma2Rate
        latestSigma3Rate = param.sigma3Rate
    }

    public func removeOldData(count: Int) {
        results?.removeFirst(count)
    }

    public func onParameterChanged() {
        if param.span != latestSpan
            || param.sigma1Rate != latestSigma1Rate || param.sigma2Rate != latestSigma2Rate || param.sigma3Rate != latestSigma3Rate {
            results = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        if param.smaOn {
            yAxis.updateRangeAll(results?.sma, span: visibleSpan)
        }

        let sigmaOnList = [param.sigma1On, param.sigma2On, param.sigma3On]
        results?.plus.enumerated().forEach { (offset, element) in
            if sigmaOnList[offset] {
                yAxis.updateRangeAll(element, span: visibleSpan)
            }
        }
        results?.minus.enumerated().forEach { (offset, element) in
            if sigmaOnList[offset] {
                yAxis.updateRangeAll(element, span: visibleSpan)
            }
        }
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        
        if param.smaOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.sma,
                      lineWidth: lineWidth,
                      color: smaColor)
        }
        
        let sigmaOnList = [param.sigma1On, param.sigma2On, param.sigma3On]
        if let plusList = results?.plus, let minusList = results?.minus {
            zip(plusList, minusList).enumerated().forEach { offset, element in
                if sigmaOnList[offset] {
                    let color = sigmaColors[offset]
                    line.draw(context: context,
                              rect: rect,
                              yAxis: yAxis,
                              visibleSpan: visibleSpan,
                              data: element.0,
                              lineWidth: lineWidth,
                              color: color)
                    line.draw(context: context,
                              rect: rect,
                              yAxis: yAxis,
                              visibleSpan: visibleSpan,
                              data: element.1,
                              lineWidth: lineWidth,
                              color: color)
                }
            }
        }
    }

    public func clear() {
        results = nil
    }

    /// ボリンジャーバンドのパラメータ
    public class Param {
        public var smaOn = true
        public var span = 20
        public var sigma1Rate: CGFloat = 1.0
        public var sigma2Rate: CGFloat = 2.0
        public var sigma3Rate: CGFloat = 3.0
        public var sigma1On = true
        public var sigma2On = true
        public var sigma3On = false
        
        public init() {}
    }
}
