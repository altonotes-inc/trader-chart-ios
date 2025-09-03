//
//  Candle.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// ローソク足
open class Candle: SimpleTechnicalChart {

    /// 標準の上昇足の色
    static let defaultUpColor: UIColor = UIColor(rgbHex: "FF5050")
    /// 標準の下降足の色
    static let defaultDownColor: UIColor = UIColor(rgbHex: "28A0FF")
    /// 標準の変化なし足の色
    static let defaultStayColor: UIColor = UIColor(rgbHex: "E0E0E0")

    /// 上昇足の色
    open var upColor: UIColor = defaultUpColor
    /// 下降足の色
    open var downColor: UIColor = defaultDownColor
    /// 変化なし足の色
    open var stayColor: UIColor = defaultStayColor

    /// ヒゲの幅
    open var stickWidth: CGFloat = 1
    /// X軸の間隔に対する足の太さの割合
    open var widthScale: CGFloat = 0.8
    
    /// ヒゲの描画
    public let stick = StickChartDrawer()
    /// 棒グラフの描画
    public let bar = BarChartDrawer(minThickness: 1)

    open override func reflectColorConfig(_ colorConfig: ColorConfig) {
        upColor = colorConfig["candle.up"] ?? Candle.defaultUpColor
        downColor = colorConfig["candle.down"] ?? Candle.defaultDownColor
        stayColor = colorConfig["candle.stay"] ?? Candle.defaultStayColor
    }

    open override func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {
        yAxis.updateRangeAll(data?.highList, span: visibleSpan)
        yAxis.updateRangeAll(data?.lowList, span: visibleSpan)
    }

    open override func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {

        stick.draw(context: context,
                   rect: rect,
                   yAxis: yAxis,
                   visibleSpan: visibleSpan,
                   fromValues: data?.lowList,
                   toValues: data?.highList,
                   color: upColor,
                   lineWidth: stickWidth,
                   condition: {index, _, _ in
                    guard let open = data?.openList[index], let close = data?.closeList[index] else {
                        return false
                    }
                    return open < close
        })

        stick.draw(context: context,
                   rect: rect,
                   yAxis: yAxis,
                   visibleSpan: visibleSpan,
                   fromValues: data?.lowList,
                   toValues: data?.highList,
                   color: downColor,
                   lineWidth: stickWidth,
                   condition: {index, _, _ in
                    guard let open = data?.openList[index], let close = data?.closeList[index] else {
                        return false
                    }
                    return close < open
        })

        stick.draw(context: context,
                   rect: rect,
                   yAxis: yAxis,
                   visibleSpan: visibleSpan,
                   fromValues: data?.lowList,
                   toValues: data?.highList,
                   color: stayColor,
                   lineWidth: stickWidth,
                   condition: {index, _, _ in
                    guard let open = data?.openList[index], let close = data?.closeList[index] else {
                        return false
                    }
                    return close == open
        })

        bar.draw(context: context,
                 rect: rect,
                 yAxis: yAxis,
                 visibleSpan: visibleSpan,
                 fromValues: data?.openList,
                 toValues: data?.closeList,
                 color: upColor,
                 widthScale: widthScale,
                 condition: isUp)

        bar.draw(context: context,
                 rect: rect,
                 yAxis: yAxis,
                 visibleSpan: visibleSpan,
                 fromValues: data?.openList,
                 toValues: data?.closeList,
                 color: downColor,
                 widthScale: widthScale,
                 condition: isDown)

        bar.draw(context: context,
                 rect: rect,
                 yAxis: yAxis,
                 visibleSpan: visibleSpan,
                 fromValues: data?.openList,
                 toValues: data?.closeList,
                 color: stayColor,
                 widthScale: widthScale,
                 condition: isSame)
    }

    func isUp(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        guard let from = from, let to = to else { return false }
        return from < to
    }

    func isDown(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        guard let from = from, let to = to else { return false }
        return to < from
    }

    func isSame(index: Int, from: CGFloat?, to: CGFloat?) -> Bool {
        guard let from = from, let to = to else { return false }
        return from == to
    }

}
