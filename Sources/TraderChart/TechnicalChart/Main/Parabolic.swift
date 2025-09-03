//
//  Parabolic.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/09/04.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

open class Parabolic: TechnicalChart {
    /// 標準のドット色
    static let defaultDotColor: UIColor = UIColor.gray

    public var isVisible: Bool = true

    /// ドットの色
    open var dotColor: UIColor = defaultDotColor

    /// ラインの太さ
    open var lineWidth: CGFloat = 1

    /// 計算パラメータ
    open var param = Param()

    open var defaultLegend: Legend? {
        return Legend([
            ColorText("パラボリック", dotColor),
            ColorText("加速因子：\(param.accelerationFactor)", dotColor),
            ColorText("極大値：\(param.accelerationFactorLimit)", dotColor),
        ])
    }

    /// カスタムの凡例
    open var customLegend: ((Parabolic, Int?) -> Legend?)?

    public func legend(selectedIndex: Int?) -> Legend? {
        if let customLegend = customLegend {
            return customLegend(self, selectedIndex)
        }
        return defaultLegend
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int?) {
        // TODO
    }

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        // TODO
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func clear() {
        // TODO
    }

    public func onParameterChanged() {
        // TODO
    }

    public func removeOldData(count: Int) {
        // TODO
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        // TODO
    }

    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        // TODO
    }

    /// パラボリックのパラメータ
    public class Param {
        public var accelerationFactor: CGFloat = 0.02
        public var accelerationFactorLimit: CGFloat = 0.2
        public init() {}
    }
}
