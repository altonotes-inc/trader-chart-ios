//
//  YAxisMarker.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/18.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// Y軸のマーカー
public protocol YAxisMarker {
    /// 描画する
    func draw(context: ChartDrawingContext,
              yAxis: YAxis,
              yAxisSetting: YAxisSetting,
              yAxisRect: CGRect,
              graphRect: CGRect,
              font: UIFont,
              toText: (CGFloat) -> String,
              isDragging: Bool)
    /// マーカーを表示する値（価格）
    var value: CGFloat? { get set }
}

/// 指定した価格位置に表示するマーカー
open class PriceMarker: YAxisMarker {
    
    /// 標準のフォント色
    nonisolated(unsafe) public static var defaultFontColor: UIColor = UIColor.white
    /// 標準のライン色
    nonisolated(unsafe) public static var defaultLineColor: UIColor = UIColor.gray
    /// 標準のマーカー色
    nonisolated(unsafe) public static var defaultMarkerColor: UIColor = UIColor(rgbHex: "DAA520")
    
    /// 罫線を表示するか
    open var showLine = false
    /// 罫線の幅
    open var lineWidth: CGFloat = 0.5
    /// 罫線の色
    open var lineColor: UIColor
    /// 罫線の破線の実線と破線の幅。nilを指定した場合は破線でなく実線になる
    open var lineDashIntervals: [CGFloat]?
    /// 目盛りフォントの色
    open var fontColor: UIColor
    /// マーカーの色
    open var markerColor: UIColor
    /// マーカーの三角形部分の幅
    open var arrowWidth: CGFloat = 5
    /// マーカーの最小の高さ。マーカーの高さはフォントの高さに応じて決まるが、このサイズより小さくならない
    open var minMarkerHeight: CGFloat = 14
    
    /// マーカーを表示する値（価格）
    open var value: CGFloat?
    /// マーカーに表示する任意のテキスト。数値以外も表示可能。nilの場合は表示位置の値（価格）が表示される
    open var text: String?

    public init(value: CGFloat? = nil,
                showLine: Bool = false,
                lineColor: UIColor = PriceMarker.defaultLineColor,
                fontColor: UIColor = PriceMarker.defaultFontColor,
                markerColor: UIColor = PriceMarker.defaultMarkerColor) {
        self.value = value
        self.showLine = showLine
        self.lineColor = lineColor
        self.fontColor = fontColor
        self.markerColor = markerColor
    }

    /// 描画する
    open func draw(context: ChartDrawingContext,
                   yAxis: YAxis,
                   yAxisSetting: YAxisSetting,
                   yAxisRect: CGRect,
                   graphRect: CGRect,
                   font: UIFont,
                   toText: (CGFloat) -> String,
                   isDragging: Bool) {
        guard let value = value else { return }
        let cgContext = context.cgContext
        let valueY = yAxis.position(value)
        let markerText = text ?? toText(value)
        let fontSize = markerText.size(withAttributes: [.font: font])
        
        // グラフエリアを超える場合は描画しない
        if valueY < graphRect.minY || valueY > graphRect.maxY {
            return
        }
        
        cgContext.saveGState()
        cgContext.setShouldAntialias(true)
        
        // ライン
        if showLine {
            if let lineDashIntervals = lineDashIntervals {
                cgContext.setLineDash(phase: 0, lengths: lineDashIntervals)
            }
            cgContext.addLines(between: [
                CGPoint(x: graphRect.minX, y: valueY),
                CGPoint(x: graphRect.maxX, y: valueY)
            ])
            lineColor.setStroke()
            cgContext.strokePath()
        }
        
        cgContext.setFillColor(markerColor.cgColor)
        switch yAxisSetting.alignment {
        case .left:
            drawLeftMarker(cgContext: cgContext,
                           yAxis: yAxis,
                           yAxisRect: yAxisRect,
                           yAxisSetting: yAxisSetting,
                           graphRect: graphRect,
                           font: font,
                           markerText: markerText,
                           valueY: valueY,
                           fontSize: fontSize)
        case .right:
            drawRightMarker(cgContext: cgContext,
                            yAxis: yAxis,
                            yAxisRect: yAxisRect,
                            yAxisSetting: yAxisSetting,
                            graphRect: graphRect,
                            font: font,
                            markerText: markerText,
                            valueY: valueY,
                            fontSize: fontSize)
        }
        
        // ドラッグ中の表示
        if isDragging {
            cgContext.setFillColor(markerColor.cgColor)
            switch yAxisSetting.alignment {
            case .left:
                drawRightMarker(cgContext: cgContext,
                                yAxis: yAxis,
                                yAxisRect: yAxisRect,
                                yAxisSetting: yAxisSetting,
                                graphRect: graphRect,
                                font: font,
                                markerText: markerText,
                                valueY: valueY,
                                fontSize: fontSize)
            case .right:
                drawLeftMarker(cgContext: cgContext,
                               yAxis: yAxis,
                               yAxisRect: yAxisRect,
                               yAxisSetting: yAxisSetting,
                               graphRect: graphRect,
                               font: font,
                               markerText: markerText,
                               valueY: valueY,
                               fontSize: fontSize)
            }
        }
        
        cgContext.restoreGState()
    }
    
    /// 右側のマーカーを描画する
    private func drawRightMarker(cgContext: CGContext,
                                 yAxis: YAxis,
                                 yAxisRect: CGRect,
                                 yAxisSetting: YAxisSetting,
                                 graphRect: CGRect,
                                 font: UIFont,
                                 markerText: String,
                                 valueY: CGFloat,
                                 fontSize: CGSize) {
        let markerWidth = yAxisRect.width - arrowWidth
        let markerHeight = max(minMarkerHeight, fontSize.height)
        let markerTopY = valueY - (markerHeight / 2)
        let baseX = (yAxisSetting.alignment == .right) ? yAxisRect.minX : (graphRect.maxX - yAxisRect.width)
        let fontX = baseX + yAxis.textPadding
        let fontTopY = valueY - fontSize.height / 2
        let arrowRightX = round(baseX + arrowWidth)
        
        cgContext.move(to: CGPoint(x: baseX, y: valueY))
        cgContext.addLine(to: CGPoint(x: arrowRightX, y: valueY - markerHeight / 2))
        cgContext.addLine(to: CGPoint(x: arrowRightX, y: valueY + markerHeight / 2))
        cgContext.fillPath()
        
        cgContext.fill(CGRect(x: arrowRightX, y: markerTopY, width: markerWidth, height: markerHeight))
        markerText.draw(at: CGPoint(x: fontX, y: fontTopY),
                        withAttributes: [.font: font, .foregroundColor: fontColor])
    }
    
    /// 左側のマーカーを描画する
    private func drawLeftMarker(cgContext: CGContext,
                                yAxis: YAxis,
                                yAxisRect: CGRect,
                                yAxisSetting: YAxisSetting,
                                graphRect: CGRect,
                                font: UIFont,
                                markerText: String,
                                valueY: CGFloat,
                                fontSize: CGSize) {
        let markerWidth = yAxisRect.width - arrowWidth
        let markerHeight = max(minMarkerHeight, fontSize.height)
        let markerTopY = valueY - (markerHeight / 2)
        
        // マーカーの矢印部分と四角部分の描画開始位置が整数ではない場合に隙間が出来てしまう場合があるので、四捨五入している
        let baseX = (yAxisSetting.alignment == .right) ? round(graphRect.minX) : round(yAxisRect.minX)
        let fontX = (yAxisSetting.alignment == .right) ? baseX : yAxisRect.maxX - fontSize.width - yAxis.textPadding
        let fontTopY = valueY - fontSize.height / 2

        cgContext.move(to: CGPoint(x: baseX + markerWidth + arrowWidth, y: valueY))
        cgContext.addLine(to: CGPoint(x: baseX + markerWidth, y: valueY - markerHeight / 2))
        cgContext.addLine(to: CGPoint(x: baseX + markerWidth, y: valueY + markerHeight / 2))
        cgContext.fillPath()
        
        cgContext.fill(CGRect(x: baseX, y: markerTopY, width: markerWidth, height: markerHeight))
        markerText.draw(at: CGPoint(x: fontX, y: fontTopY),
                        withAttributes: [.font: font, .foregroundColor: fontColor])
    }
}
