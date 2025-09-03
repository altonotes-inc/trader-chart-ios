//
//  DMIADX.swift
//  TraderChart
//
//  Created by altonotes on 2019/06/13.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// DMI/ADX
open class DMIADX: TechnicalChart {

    /// 標準のDIプラスの線の色
    static let defaultDiPlusColor: UIColor = UIColor(rgbHex: "FF7774")
    /// 標準のDIマイナスの線の色
    static let defaultDiMinusColor: UIColor = UIColor(rgbHex: "83FF92")
    /// 標準のADXの線の色
    static let defaultAdxColor: UIColor = UIColor(rgbHex: "E070FF")
    /// 標準のADXRの線の色
    static let defaultAdxrColor: UIColor = UIColor(rgbHex: "8DFAFF")
    
    open var isVisible: Bool = true
    
    /// DIプラスの線の色
    open var diPlusColor: UIColor = defaultDiPlusColor
    /// DIマイナスの線の色
    open var diMinusColor: UIColor = defaultDiMinusColor
    /// ADXの線の色
    open var adxColor: UIColor = defaultAdxColor
    /// ADXRの線の色
    open var adxrColor: UIColor = defaultAdxrColor
    
    /// ラインの幅
    open var lineWidth: CGFloat = 1
    
    /// パラメータ
    open var param = Param()

    /// 直近の計算に使ったDIスパン
    public var latestDiSpan: Int?
    /// 直近の計算に使ったADXスパン
    public var latestAdxSpan: Int?
    /// 直近の計算に使ったADXRスパン
    public var latestAdxrSpan: Int?

    /// DMI/ADXの計算結果
    open var results: DMICalculator.Results?
    
    /// ラインチャートの描画
    open var line = LineChartDrawer()
    
    /// DMI/ADXの計算
    open var calculater = DMICalculator()

    /// カスタムの凡例
    open var customLegend: ((DMIADX, Int?) -> Legend?)?

    /// 標準の凡例
    open var defaultLegend: Legend? {
        return Legend([
            ColorText("+DI:\(param.diSpan)", diPlusColor, visible: param.diOn),
            ColorText("-DI:\(param.diSpan)", diMinusColor, visible: param.diOn),
            ColorText("ADX:\(param.adxSpan)", adxColor, visible: param.adxOn),
            ColorText("ADXR:\(param.adxrSpan)", adxrColor, visible: param.adxrOn),
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
        diPlusColor = colorConfig["dmi_adx.di_plus"] ?? DMIADX.defaultDiPlusColor
        diMinusColor = colorConfig["dmi_adx.di_minus"] ?? DMIADX.defaultDiMinusColor
        adxColor = colorConfig["dmi_adx.adx"] ?? DMIADX.defaultAdxColor
        adxrColor = colorConfig["dmi_adx.adxr"] ?? DMIADX.defaultAdxrColor
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        if param.diOn || param.adxOn || param.adxrOn {
            results?.removeLastFrom(updatedFrom)
            results = calculater.update(averageSpan: param.diSpan,
                                        adxSpan: param.adxSpan,
                                        adxrSpan: param.adxrSpan,
                                        highList: data?.highList,
                                        lowList: data?.lowList,
                                        closeList: data?.closeList,
                                        results: results)
            latestDiSpan = param.diSpan
            latestAdxSpan = param.adxSpan
            latestAdxrSpan = param.adxrSpan
        }
    }

    public func removeOldData(count: Int) {
        results?.removeFirst(count)
    }

    public func onParameterChanged() {
        if param.diSpan != latestDiSpan
            || param.adxSpan != latestAdxSpan
            || param.adxrSpan != latestAdxrSpan {
            results = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.setMinMax(min: 0, max: 100)
    }
    
    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        if param.diOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.plus,
                      lineWidth: lineWidth,
                      color: diPlusColor)
            
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.minus,
                      lineWidth: lineWidth,
                      color: diMinusColor)
        }
        
        if param.adxOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.adx,
                      lineWidth: lineWidth,
                      color: adxColor)
        }
        
        if param.adxrOn {
            line.draw(context: context,
                      rect: rect,
                      yAxis: yAxis,
                      visibleSpan: visibleSpan,
                      data: results?.adxr,
                      lineWidth: lineWidth,
                      color: adxrColor)
        }
    }

    public func clear() {
        results = nil
    }
    
    /// DMI/ADXのパラメータ
    public class Param {
        public var diOn = true
        public var adxOn = true
        public var adxrOn = false
        public var diSpan = 14
        public var adxSpan = 9
        public var adxrSpan = 9
        
        public init() {}
    }
}
