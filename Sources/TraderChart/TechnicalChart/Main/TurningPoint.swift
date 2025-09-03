//
//  TurningPoint.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/11.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 転換点
open class TurningPoint: TechnicalChart, UsesFontContext {

    /// 標準のフォントサイズ
    nonisolated(unsafe) public static var defaultFontSize: CGFloat = 12

    open var isVisible: Bool = true
    
    /// 数値の小数点以下桁数。nilの場合はY軸の小数点以下桁数と同様となる
    open var decimalLength: Int?
    
    /// フォントの色
    open var fontColor: UIColor = UIColor.lightGray

    /// フォント
    open var font: UIFont = UIFont.systemFont(ofSize: defaultFontSize)
    
    /// パラメータ
    open var param = Param()

    /// 直近の計算に使ったスパン
    public var latestSpan: Int?
    /// 直近の計算に使ったリバーサルレート
    public var latestReversalRate: CGFloat?

    /// 転換点の計算
    open var calculater = TurningPointCalculator()
    
    /// 転換点の結果
    open var results: TurningPointCalculator.Results?

    /// 値をテキストに変換する (数値, 小数点以下桁数) -> テキスト
    open var format: (CGFloat, Int) -> String = defaultFormat

    public func legend(selectedIndex: Int?) -> Legend? {
        return nil
    }

    public init() {}

    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        fontColor = colorConfig["turning_point.font"] ?? fontColor
    }

    public func reflectFontContext(_ fontContext: FontContext) {
        font = fontContext.numericFont(size: TurningPoint.defaultFontSize)
    }

    public func updateData(_ data: ChartData?, updatedFrom: Int? = nil) {
        results?.removeLastFrom(updatedFrom)
        results = calculater.update(span: param.span, reversalRate: param.reversalRate, highList: data?.highList, lowList: data?.lowList, results: results)
        latestSpan = param.span
        latestReversalRate = param.reversalRate
    }

    public func removeOldData(count: Int) {
        results?.removeOldData(removedCount: count)
    }

    public func onParameterChanged() {
        if param.span != latestSpan || param.reversalRate != latestReversalRate {
            results = nil
        }
    }

    public func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}

    public func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        guard let data = data else { return }
        guard let max = data.highList.max(from: visibleSpan.lowerBound, span: visibleSpan.count) else { return }
        guard let min = data.lowList.min(from: visibleSpan.lowerBound, span: visibleSpan.count) else { return }
        
        let fontSize = "0123456789.,".size(withAttributes: [.font: font])
        let marginSum = fontSize.height + fontSize.height
        let priceRange = yAxis.max - yAxis.min
        let additionalPrice = marginSum * priceRange / (height - marginSum)
        let marginPrice = additionalPrice * fontSize.height / marginSum

        yAxis.updateRange(max + marginPrice)
        yAxis.updateRange(min - marginPrice)
    }

    public func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {
        guard let results = results else { return }
        context.cgContext.saveGState()
        
        let decimalLength = self.decimalLength ?? yAxis.decimalLength
        let visiblePoints = results.points.filter { visibleSpan.contains($0.index) }
        let baseX = rect.maxX + context.rightOffset - (context.xAxisInterval / 2)
        for i in 0..<visiblePoints.count {
            let point = visiblePoints[i]
            let x = baseX - (context.xAxisInterval * (CGFloat(visibleSpan.upperBound - point.index)))
            if rect.minX < x && x < rect.maxX {
                let y = yAxis.position(point.value)
                let text = format(point.value, decimalLength)
                let fontSize = text.size(withAttributes: [.font: font])
                let xOffset = -(fontSize.width / 2)
                let yOffset = point.type == .top ? -fontSize.height : 0
                text.draw(at: CGPoint(x: x + xOffset, y: y + yOffset), withAttributes: [.font: font, .foregroundColor: fontColor])
            }
        }
        context.cgContext.restoreGState()
    }

    /// 標準のテキストフォーマット
    public static func defaultFormat(value: CGFloat, decimalLength: Int) -> String {
        return value.decimalNumber.stringValue(decimalLength: decimalLength).numberFormat
    }

    public func clear() {
        results = nil
    }

    /// 転換点のパラメータ
    public class Param {
        var span = 10
        var reversalRate: CGFloat = 0.5
        
        public init() {}
    }
}
