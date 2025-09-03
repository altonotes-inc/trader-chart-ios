//
//  XAxis.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// チャートのX軸
open class XAxis: ColorConfigurable, UsesFontContext {
    /// 標準の目盛りフォントサイズ
    nonisolated(unsafe) public static var defaultFontSize: CGFloat = 12

    /// 標準の目盛りフォント色
    nonisolated(unsafe) public static var defaultFontColor: UIColor = UIColor.lightGray
    /// 標準の罫線の色
    nonisolated(unsafe) public static var defaultLineColor: UIColor = UIColor(white: 0.5, alpha: 0.5)
    
    /// 標準のタッチマーカーの色
    nonisolated(unsafe) public static var defaultTouchMarkerColor = UIColor(rgbValue: 0x5B84C7)
    /// 標準のタッチマーカーのテキスト色
    nonisolated(unsafe) public static var defaultTouchMarkerFontColor = UIColor.white
    /// 標準のタッチマーカーのライン色
    nonisolated(unsafe) public static var defaultTouchMarkerLineColor = UIColor.lightGray
    /// 標準のタッチマーカーのドラッグ表示の背景色
    nonisolated(unsafe) public static var defaultDraggingTextBackgroundColor: UIColor = UIColor(white: 0.5, alpha: 0.4)
    /// 標準のタッチマーカーのドラッグ表示のテキスト色
    nonisolated(unsafe) public static var defaultDraggingTextColor: UIColor = UIColor.white

    /// X軸の刻みの間隔（任意指定）
    open var variableInterval: CGFloat = 6 {
        didSet {
            if oldValue != variableInterval {
                onIntervalChanged?(variableInterval)
            }
        }
    }
    /// X軸の刻みの間隔
    open var interval: CGFloat {
        guard let fixedCount = fixedCount, !rect.width.isZero else {
            return variableInterval
        }
        let count = hasPlotMargin ? fixedCount : fixedCount - 1
        return rect.width / CGFloat(count)
    }
    /// プロットが両端に余白を取るか
    /// 棒グラフなどプロットに幅がある場合は`true`にし、ラインチャートを両端いっぱいまで表示する場合などは`false`にする
    open var hasPlotMargin: Bool = true

    /// 表示するか
    open var isVisible: Bool = true
    /// ドラッグ中か
    open var isDragging: Bool = false
    /// 高さ
    open var height: CGFloat = 20
    /// X軸（日時）データ
    open var dataList: [String]?
    /// タッチ時に表示するマーカー
    open var touchMarker: XAxisMarker = TimeMarker(showLine: true)
    /// 破線の間隔。線の幅、空白の幅の順に指定
    open var lineDashIntervals: [CGFloat]? = [1, 1]
    /// 目盛りテキストのフォント
    open var font: UIFont = UIFont.systemFont(ofSize: defaultFontSize)
    /// 目盛りテキストの文字サイズ
    open var fontSize: CGFloat = XAxis.defaultFontSize {
        didSet {
            font = font.withSize(fontSize)
        }
    }
    /// フォント色
    open var fontColor: UIColor = defaultFontColor
    /// 罫線の色
    open var lineColor: UIColor = defaultLineColor
    /// 罫線の幅
    open var lineWidth: CGFloat = 0.5
    /// X軸の目盛り領域
    open var rect: CGRect = CGRect.zero
    /// 目盛りテキストが重なる場合は、右側を優先して重なるテキストを非表示にする
    open var hidesOverwrappedLabel = true
    /// X軸刻みの数
    open var count: Int {
        if let fixedCount = fixedCount { return fixedCount }
        return dataList?.count ?? 0
    }
    /// 固定されたX軸刻みの数。この値を指定するとチャートのスクロール、拡大・縮小はできなくなる
    open var fixedCount: Int?

    /// チャートがタッチされたときタッチ位置のインデックスを伝えるコールバック
    public var onRecordSelected: ((Int?) -> Void)?

    /// インターバルの変更を伝えるコールバック
    public var onIntervalChanged: ((CGFloat) -> Void)?

    /// X軸目盛り線とテキストの表示方法
    public var strategy: XAxisStrategy

    /// 初期スクロール位置
    open var initialScrollPosition: CGFloat {
        return hasPlotMargin ? 0 : interval / 2
    }

    public init(strategy: XAxisStrategy = DefaultXAxisStrategy()) {
        self.strategy = strategy
        if let touchMarker = touchMarker as? TimeMarker {
            touchMarker.markerColor = XAxis.defaultTouchMarkerColor
            touchMarker.fontColor = XAxis.defaultTouchMarkerFontColor
            touchMarker.lineColor = XAxis.defaultTouchMarkerLineColor
            touchMarker.draggingTextBackgroundColor = XAxis.defaultDraggingTextBackgroundColor
            touchMarker.draggingTextColor = XAxis.defaultDraggingTextColor
        }
    }

    /// 設定を反映する
    public func setup(strategy: XAxisStrategy) {
        self.strategy = strategy
    }

    /// 色設定を反映する
    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        fontColor = colorConfig["x_axis.font"] ?? XAxis.defaultFontColor
        lineColor = colorConfig["x_axis.line"] ?? XAxis.defaultLineColor
        
        if let touchMarker = touchMarker as? TimeMarker {
            touchMarker.markerColor = colorConfig["x_axis.touch_marker.marker"] ?? touchMarker.markerColor
            touchMarker.fontColor = colorConfig["x_axis.touch_marker.font"] ?? touchMarker.fontColor
            touchMarker.lineColor = colorConfig["x_axis.touch_marker.line"] ?? touchMarker.lineColor
            touchMarker.draggingTextBackgroundColor = colorConfig["x_axis.touch_marker.dragging_text_background"] ?? touchMarker.draggingTextBackgroundColor
            touchMarker.draggingTextColor = colorConfig["x_axis.touch_marker.dragging_text"] ?? touchMarker.draggingTextColor
        }
    }

    /// フォント設定を反映する
    public func reflectFontContext(_ fontContext: FontContext) {
        font = fontContext.numericFont(size: fontSize)
    }

    /// チャート表示前の描画処理
    open func drawBeforeChart(context: ChartDrawingContext, graphRect: CGRect, visibleSpan: ClosedRange<Int>) {
        guard isVisible else { return }
        drawText(context: context, visibleSpan: visibleSpan)
        drawLines(context: context, graphRect: graphRect, visibleSpan: visibleSpan)
    }

    /// チャート表示後の描画処理
    open func drawAfterChart(context: ChartDrawingContext, graphRect: CGRect, visibleSpan: ClosedRange<Int>) {
        guard isVisible else { return }
        touchMarker.draw(context: context,
                         xAxis: self,
                         xAxisRect: rect,
                         graphRect: graphRect,
                         visibleSpan: visibleSpan,
                         font: font,
                         strategy: strategy,
                         dataList: dataList,
                         isDragging: isDragging
        )
    }

    /// 目盛りテキストを描画する
    open func drawText(context: ChartDrawingContext, visibleSpan: ClosedRange<Int>) {
        guard let timeList = dataList else { return }
        let cgContext = context.cgContext
        cgContext.saveGState()
        cgContext.setShouldAntialias(true)
        cgContext.setStrokeColor(fontColor.cgColor)

        var x = rect.maxX + context.rightOffset - context.xAxisInterval / 2
        let maxIndex = timeList.count - 1

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: fontColor
        ]

        var preFontLeft: CGFloat?

        for i in visibleSpan.reversed() {
            let time = (0 <= i && i <= maxIndex) ? timeList[i] : nil
            if strategy.isTextVisible(index: i, axisValue: time, axisValues: timeList) && rect.minX < x && x < rect.maxX {
                let text = strategy.format(index: i, axisValue: time)
                let fontSize = text.size(withAttributes: attrs)

                // NOTE: 画面内の右端のラベルを基準に表示・非表示を決めているのでスクロールによってラベルが表示される位置が変わってしまう
                // ただし、スクロールによってラベル表示箇所を変えないためには visibleSpan 以外の範囲も含めての判定が必要なので、パフォーマンスを考慮していったん現状のままとしておく。
                var overwrapped = false
                if let preFontLeft = preFontLeft, preFontLeft < x + (fontSize.width / 2) {
                    overwrapped = true
                }

                if !hidesOverwrappedLabel || !overwrapped {
                    let xOffset = -(fontSize.width / 2)
                    let yOffset = (rect.height - fontSize.height) / 2
                    text.draw(at: CGPoint(x: x + xOffset, y: rect.minY + yOffset), withAttributes: attrs)
                    preFontLeft = x + xOffset
                }
            }

            x -= context.xAxisInterval
        }

        // コンテキストの状態を戻す
        cgContext.restoreGState()
    }
    
    /// 罫線を描画する
    open func drawLines(context: ChartDrawingContext,
                        graphRect: CGRect,
                        visibleSpan: ClosedRange<Int>) {
        guard let timeList = dataList else { return }
        let cgContext = context.cgContext

        cgContext.saveGState()
        cgContext.setLineWidth(lineWidth)
        if let lineDashIntervals = lineDashIntervals {
            cgContext.setLineDash(phase: 0, lengths: lineDashIntervals)
        }

        var x = rect.maxX + context.rightOffset - context.xAxisInterval / 2
        let maxIndex = timeList.count - 1

        for i in visibleSpan.reversed() {
            let time = (0 <= i && i <= maxIndex) ? timeList[i] : nil
            if strategy.isLineVisible(index: i, axisValue: time, axisValues: timeList)
                && rect.minX < x && x < rect.maxX {
                let points = [CGPoint(x: x, y: graphRect.minY), CGPoint(x: x, y: graphRect.maxY)]
                cgContext.addLines(between: points)
            }

            x -= context.xAxisInterval
        }

        cgContext.setStrokeColor(lineColor.cgColor)
        cgContext.strokePath()

        // コンテキストの状態を戻す
        cgContext.restoreGState()
    }
    
    /// タッチ開始
    open func touchesBegan(point: CGPoint, scrollOffset: CGFloat) -> Bool {
        guard rect.contains(point) else { return false }
        touchMarker.index = indexOf(point: point, scrollOffset: scrollOffset)
        onRecordSelected?(touchMarker.index)
        isDragging = true
        return true
    }
    
    /// タッチ移動
    @discardableResult
    open func touchesMoved(point: CGPoint, scrollOffset: CGFloat) -> Bool {
        if rect.minX < point.x && point.x < rect.maxX {
            touchMarker.index = indexOf(point: point, scrollOffset: scrollOffset)
        } else {
            touchMarker.index = nil
        }
        onRecordSelected?(touchMarker.index)
        isDragging = true
        return true
    }
    
    /// タッチ終了（キャンセル含む）
    @discardableResult
    open func touchesCompleted(point: CGPoint, scrollOffset: CGFloat) -> Bool {
        if isDragging {
            isDragging = false
            return true
        }
        return false
    }
    
    /// 指定されたポイントに対応するインデックスを返す
    open func indexOf(point: CGPoint, scrollOffset: CGFloat) -> Int {
        let rightX = scrollOffset + (rect.maxX - point.x)
        let rightIndex = rightX / interval
        let index = CGFloat(count) - rightIndex
        return Int(floor(index))
    }
    
    /// クリアする
    open func clear() {
        dataList = nil
        touchMarker.index = nil
        onRecordSelected?(nil)
    }

    /// 別のChartViewの状態（チャートデータ、レコード幅、スクロール位置）を引き継ぐ
    public func importState(from: XAxis) {
        dataList = from.dataList
        variableInterval = from.variableInterval
        fixedCount = from.fixedCount
        touchMarker.index = from.touchMarker.index
    }
}

public protocol XAxisStrategy {
    /// 目盛り表示ラベルのフォーマットを行う
    func format(index: Int, axisValue: String?) -> String

    /// 目盛り表示ラベルの詳細なフォーマットを行う
    func detailedFormat(index: Int, axisValue: String?) -> String

    /// 指定インデックス、値のX軸目盛りテキストを表示するか判定する
    func isTextVisible(index: Int, axisValue: String?, axisValues: [String]) -> Bool

    /// 指定インデックス、値のX軸目盛りラインを表示するか判定する
    func isLineVisible(index: Int, axisValue: String?, axisValues: [String]) -> Bool
}

open class DefaultXAxisStrategy: XAxisStrategy {
    public init() {}

    open func format(index: Int, axisValue: String?) -> String {
        return axisValue ?? ""
    }

    open func detailedFormat(index: Int, axisValue: String?) -> String {
        return format(index: index, axisValue: axisValue)
    }

    open func isTextVisible(index: Int, axisValue: String?, axisValues: [String]) -> Bool {
        return (index % 10) == 0
    }

    open func isLineVisible(index: Int, axisValue: String?, axisValues: [String]) -> Bool {
        return (index % 10) == 0
    }
}
