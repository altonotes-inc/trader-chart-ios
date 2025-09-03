//
//  YAxis.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// グラフY軸
open class YAxis: ColorConfigurable, UsesFontContext {

    /// 標準の目盛りフォントサイズ
    nonisolated(unsafe) public static var defaultFontSize: CGFloat = 13

    /// 標準の目盛りフォント色
    nonisolated(unsafe) public static var defaultFontColor = UIColor.lightGray
    /// 標準の目盛り罫線の色
    nonisolated(unsafe) public static var defaultLineColor = UIColor(white: 0.5, alpha: 0.5)

    nonisolated(unsafe) public static var defaultTouchMarkerColor = UIColor(rgbValue: 0x5B84C7)
    nonisolated(unsafe) public static var defaultTouchMarkerFontColor = UIColor.white
    nonisolated(unsafe) public static var defaultTouchMarkerLineColor = UIColor.lightGray

    /// 目盛り間隔の下限
    public var minLimit = NSDecimalNumber(string: "1e-6")

    /// 目盛り間隔の取りうる単位の基準
    open var scaleUnits = [
        NSDecimalNumber(string: "5.0"),
        NSDecimalNumber(string: "2.5"),
        NSDecimalNumber(string: "2.0"),
        NSDecimalNumber(string: "1.0")
    ]

    /// Y軸の最小値
    open var min: CGFloat = CGFloat.nan
    /// Y軸の最大値
    open var max: CGFloat = CGFloat.nan

    /// パディングを含めたY軸の最小値
    public var bottom: CGFloat {
        if !isValid {
            return CGFloat.nan
        }
        return min - paddingBottom / valueHeightRate
    }

    /// パディングを含めたY軸の最大値
    public var top: CGFloat {
        if !isValid {
            return CGFloat.nan
        }
        return max - paddingTop / valueHeightRate
    }

    /// 上部のパディング幅。凡例の表示を想定して下部パディングより大きい標準値にしている
    open var paddingTop: CGFloat = 10
    /// 下部のパディング幅
    open var paddingBottom: CGFloat = 5

    /// 罫線の幅
    open var lineWidth: CGFloat = 0.5
    /// 罫線の最小数。この値よりも多くの罫線が入るよう目盛りが決定される
    open var minLineNumber: Int = 3

    /// 罫線の破線の実線と空白の幅。nilにすると破線ではなく実線になる
    open var lineDashIntervals: [CGFloat]? = [1, 1]

    /// 目盛りフォントの色
    open var fontColor: UIColor = defaultFontColor
    /// 罫線の色
    open var lineColor: UIColor = defaultLineColor
    
    /// 目盛りフォント
    open var font: UIFont = UIFont.systemFont(ofSize: defaultFontSize)
    /// 目盛りテキストの文字サイズ
    open var fontSize: CGFloat = YAxis.defaultFontSize {
        didSet {
            font = font.withSize(fontSize)
        }
    }
    /// 目盛りテキストの最小文字サイズ
    open var minFontSize: CGFloat = 5
    /// 目盛りフォントの罫線に対する位置
    open var graduationAlignment = GraduationAlignment.centerOfLine
    /// 目盛りフォントのパディング
    open var textPadding: CGFloat = 6
    
    /// マーカーをドラッグ中か
    open var isDragging = false
    
    /// マーカー。任意の価格位置に設定可能
    open var markers: [String: YAxisMarker] = [:]
    /// タッチ位置のマーカー
    open var touchMarker: YAxisMarker = PriceMarker(showLine: true,
                                                    lineColor: YAxis.defaultTouchMarkerLineColor,
                                                    fontColor: YAxis.defaultTouchMarkerFontColor,
                                                    markerColor: YAxis.defaultTouchMarkerColor)
    /// 固定の目盛り数値の小数点以下桁数。nilの場合は目盛り間隔に従って小数点以下桁数が自動設定される
    /// FX、スモールティック株式など小数があり桁数固定の場合は、銘柄に応じた桁数を設定する必要がある
    open var designatedDecimalLength: Int?
    
    /// 目盛り間隔に適した小数点以下桁数
    var suitableDecimalLength: Int = 0
    
    /// 目盛り数値の小数点以下桁数
    open var decimalLength: Int {
        if let designated = designatedDecimalLength {
            return designated
        }
        return suitableDecimalLength
    }
    
    /// 目盛り数値
    open var graduations: [CGFloat] = []
    /// 目盛りの間隔
    open var interval: NSDecimalNumber?
    /// 目盛り表示ラベルのフォーマットを行う (value, decimalLength) -> formattedValueText
    open var formatter: ((CGFloat, Int) -> String)?
    
    /// 目盛りの罫線を描画するかどうか
    open var isLineVisible: Bool = true
    
    /// タッチラインを表示するかどうか
    open var isTouchEnabled: Bool = true

    /// Y軸の範囲が有効か
    open var isValid: Bool {
        return !min.isNaN && !max.isNaN && (min < max) && (0 < valueHeightRate)
    }
    
    // グラフ値の幅
    open var range: CGFloat {
        return max - min
    }

    /// Y軸の系を高さに変換する係数
    var valueHeightRate: CGFloat = 0

    /// Y軸の目盛り領域
    open var rect: CGRect = CGRect.zero

    /// 最大・最小値を固定するか
    open var lockMinMax = false

    public init() {}
    public init(min: CGFloat, max: CGFloat, lockMinMax: Bool = false) {
        self.min = min
        self.max = max
        self.lockMinMax = lockMinMax
    }

    /// 色設定を反映する
    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        fontColor = colorConfig["y_axis.font"] ?? YAxis.defaultFontColor
        lineColor = colorConfig["y_axis.line"] ?? YAxis.defaultLineColor

        if let touchMarker = touchMarker as? PriceMarker {
            touchMarker.markerColor = colorConfig["y_axis.touch_marker.marker"] ?? YAxis.defaultTouchMarkerColor
            touchMarker.fontColor = colorConfig["y_axis.touch_marker.font"] ?? YAxis.defaultTouchMarkerFontColor
            touchMarker.lineColor = colorConfig["y_axis.touch_marker.line"] ?? YAxis.defaultTouchMarkerLineColor
        }
    }

    /// フォント設定を反映する
    public func reflectFontContext(_ fontContext: FontContext) {
        font = fontContext.numericFont(size: fontSize)
    }

    /// パディングを設定する
    public func setPadding(top: CGFloat, bottom: CGFloat) {
        self.paddingTop = top
        self.paddingBottom = bottom
    }

    /// 最大・最小値を設定する
    public func setMinMax(min: CGFloat, max: CGFloat, lock: Bool = false) {
        self.min = min
        self.max = max
        lockMinMax = lock
    }
    
    /// チャート描画前の描画
    open func drawBeforeChart(context: ChartDrawingContext, graphRect: CGRect, yAxisSetting: YAxisSetting) {
    }

    /// チャート描画後の描画
    open func drawAfterChart(context: ChartDrawingContext, graphRect: CGRect, yAxisSetting: YAxisSetting) {
        let cgContext = context.cgContext
        cgContext.saveGState()
        cgContext.setShouldAntialias(true)
        cgContext.setLineWidth(lineWidth)
        fontColor.setFill()
        
        let font = getScaleFont(width: rect.width - textPadding)
        cgContext.beginPath()
        
        // テキスト
        graduations.forEach {value in
            let y = position(value)
            let text = valueToText(value: value)
            let fontSize = text.size(withAttributes: [.font: font])
            
            let fontY: CGFloat = y + adjustedFontY(fontSize: fontSize)
            let fontX = (yAxisSetting.alignment == .right) ? rect.minX + textPadding : rect.maxX - fontSize.width - textPadding
            
            text.draw(at: CGPoint(x: fontX, y: fontY),
                      withAttributes: [.font: font, .foregroundColor: fontColor])
        }
        
        // ライン
        if isLineVisible {
            if let lineDashIntervals = lineDashIntervals {
                cgContext.setLineDash(phase: 0, lengths: lineDashIntervals)
            }
            graduations.forEach { value in
                let y = position(value)
                cgContext.addLines(between: [
                    CGPoint(x: graphRect.minX, y: y),
                    CGPoint(x: graphRect.maxX, y: y)
                ])
            }
            lineColor.setStroke()
            cgContext.strokePath()
        }
        cgContext.restoreGState()
        
        markers.values.forEach {
            $0.draw(context: context,
                    yAxis: self,
                    yAxisSetting: yAxisSetting,
                    yAxisRect: rect,
                    graphRect: graphRect,
                    font: font,
                    toText: valueToText,
                    isDragging: false)
        }
        
        // タッチラインの描画
        touchMarker.draw(context: context,
                         yAxis: self,
                         yAxisSetting: yAxisSetting,
                         yAxisRect: rect,
                         graphRect: graphRect,
                         font: font,
                         toText: valueToText,
                         isDragging: isDragging)
    }

    /// 値（価格）に対応するテキストを取得する
    open func valueToText(value: CGFloat) -> String {
        if let formatter = formatter {
            return formatter(value, decimalLength)
        }
        return value.decimalNumber.stringValue(decimalLength: decimalLength).numberFormat
    }

    /// Y軸の最大、最小値を更新し、目盛り描画位置を決定する
    open func update(data: ChartData?, charts: [TechnicalChart], visibleSpan: ClosedRange<Int>) {
        if lockMinMax {
            prepare()
            return
        }

        let oldMin = min
        let oldMax = max
        clearRange()

        charts.forEach {
            $0.updateYAxis(self, data: data, height: rect.height, visibleSpan: visibleSpan)
        }

        // 最大・最小がなければ前の値を引き継ぎ
        if min.isNaN {
            min = oldMin
        }
        if max.isNaN {
            max = oldMax
        }
        
        // 最大、最小値に差がない場合も前の値を引き継ぎ
        if range == 0 {
            if !oldMax.isNaN {
                max = Swift.max(max, oldMax)
            }
            if !oldMin.isNaN {
                min = Swift.min(min, oldMin)
            }
        }

        // 最終的に min,max がnan、または同一になる場合、visibleSpan 外のデータも見て範囲を決めるのが望ましい
        // しかし仕様が複雑になるのとパフォーマンスの懸念があるため、いったん固定値で幅を広げる
        if range == 0 {
            max += 1
            min -= 1
        }

        prepare()
    }

    /// 目盛り描画位置などを決定する
    open func prepare() {
        if !range.isNaN && 0 < range {
            valueHeightRate = Swift.max(0, rect.height - paddingTop - paddingBottom) / range
        } else {
            valueHeightRate = CGFloat.nan
        }
        
        calculateGraduations()
    }
    
    /// 引数の座標に対応する値（価格）
    open func value(_ position: CGFloat) -> CGFloat {
        return max - ((position - rect.minY - paddingTop) / valueHeightRate)
    }

    /// 引数の値（価格）に対応するY座標
    open func position(_ value: CGFloat) -> CGFloat {
        let top = (max - value) * valueHeightRate
        return rect.minY + paddingTop + top
    }
    
    /// 横幅に収まるよう縮小されたフォント
    open func getScaleFont(width: CGFloat) -> UIFont {
        // フォントサイズ決定
        let text = graduations.map {
            valueToText(value: $0)
        }.max(by: { str1, str2 in
            str1.count < str2.count
        })
        guard let longestText = text else { return font }
        var font = self.font
        var fontWidth = longestText.size(withAttributes: [.font: font]).width
        
        while width < fontWidth {
            font = font.withSize(font.pointSize - 1.0)
            fontWidth = longestText.size(withAttributes: [.font: font]).width
            if font.pointSize <= minFontSize {
                break
            }
        }
        return font
    }

    /// graduationAlignment に応じて調整するフォントY座標の幅
    open func adjustedFontY(fontSize: CGSize) -> CGFloat {
        switch graduationAlignment {
        case .belowLine:
            return 0
        case .aboveLine:
            return -fontSize.height
        case .centerOfLine:
            return -fontSize.height / 2
        }
    }
    
    /// 最大値、最小値を引数の値で更新する
    open func updateRange(_ value: CGFloat?) {
        guard let value = value else { return }

        if min.isNaN || value < min {
            min = value
        }
        if max.isNaN || max < value {
            max = value
        }
    }

    /// spanに含まれるNumberArrayの値で最大値、最小値を更新する
    open func updateRangeAll(_ array: NumberArray?, span: ClosedRange<Int>) {
        guard let array = array else { return }
        for i in span {
            updateRange(array[i])
        }
    }
    
    /// 目盛り描画位置を計算
    open func calculateGraduations() {
        graduations.removeAll()
        if !isValid { return }
        
        // 目盛間隔を計算
        let fontHeight: CGFloat = "0123456789.,".size(withAttributes: [.font: font]).height
        let minInterval: CGFloat = fontHeight / valueHeightRate
        let interval = calcScaleInterval(range: range, minLineNumber: minLineNumber, minInterval: minInterval)
        self.interval = interval
        suitableDecimalLength = calcSuitableDecimalLength(interval: interval)
        let floatInterval = CGFloat(interval.doubleValue)
        
        // 一番下のライン位置を計算
        let minRemainder = min.truncatingRemainder(dividingBy: floatInterval)
        var bottomGrid = min - minRemainder
        if 0 < minRemainder {
            bottomGrid += floatInterval
        }
        
        var value = bottomGrid
        while value <= max {
            graduations.append(value)
            value += floatInterval
        }
    }
    
    /// spanに含まれるNumberArrayの値で最大値、最小値を更新する
    open func calcSuitableDecimalLength(interval: NSDecimalNumber) -> Int {
        if 2.5 < interval {
            return 0
        }
        
        var base = NSDecimalNumber.one
        
        var decimalCount = 0
        while true {
            if interval.compare(base) != .orderedAscending {
                let quotient = interval.dividing(by: base)
                if quotient != quotient.roundDown() {
                    decimalCount += 1
                }
                break
            }
            base = base.multiplying(byPowerOf10: -1)
            decimalCount += 1
        }
        return decimalCount
    }
    
    /// Y軸目盛間隔を計算する
    open func calcScaleInterval(range: CGFloat, minLineNumber: Int, minInterval: CGFloat?) -> NSDecimalNumber {
        if minLineNumber <= 0 {
            assertionFailure("minLineNumber must be greater than 0")
        }
        var base = baseNumber(range: range)
        
        // 幅の1/Nより細かく刻む
        let maxDelta: NSDecimalNumber = NSDecimalNumber(value: Double(range / CGFloat(minLineNumber)))
        let minIntervalDecimal = minInterval?.decimalNumber
        var preInterval: NSDecimalNumber?
        while true {
            for i in scaleUnits.indices {
                let interval = base.multiplying(by: scaleUnits[i])
                
                if let minIntervalDecimal = minIntervalDecimal, interval < minIntervalDecimal {
                    return preInterval ?? interval
                }
                
                if maxDelta.compare(interval) != .orderedAscending {
                    return interval
                }
                
                if minLimit.compare(interval) != .orderedAscending {
                    return interval
                }
                preInterval = interval
            }
            base = base.dividing(by: NSDecimalNumber.ten)
        }
    }
    
    /// 引数の幅に対応する基準値。目盛り間隔の計算の初期値に使われる
    func baseNumber(range: CGFloat) -> NSDecimalNumber {
        return NSDecimalNumber(string: baseNumberText(range: range))
    }
    
    func baseNumberText(range: CGFloat) -> String {
        if range < 1 {
            return "1"
        }
        let textLength = String(Int64(ceil(Double(range)))).count
        var numberText = "1"
        (1...textLength).forEach {_ in
            numberText += "0"
        }
        return numberText
    }

    /// 最大、最小値をクリアする
    open func clearRange() {
        min = CGFloat.nan
        max = CGFloat.nan
        graduations.removeAll()
        valueHeightRate = 0
    }

    /// 最大、最小値、マーカー
    open func clear() {
        clearRange()
        markers.removeAll()
        touchMarker.value = nil
        lockMinMax = false
    }
    
    /// 別のYAxisの状態を引き継ぐ
    public func importState(from: YAxis) {
        touchMarker.value = from.touchMarker.value
    }

    /// 目盛りテキストの罫線に対する位置
    public enum GraduationAlignment {
        case centerOfLine
        case aboveLine
        case belowLine
    }
}
