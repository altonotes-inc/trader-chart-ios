//
//  XAxisMarker.swift
//  TraderChart
//
//  Created by altonotes on 2019/06/21.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// X軸のマーカー
public protocol XAxisMarker {
    /// マーカーを描画する
    func draw(context: ChartDrawingContext,
              xAxis: XAxis,
              xAxisRect: CGRect,
              graphRect: CGRect,
              visibleSpan: ClosedRange<Int>,
              font: UIFont,
              strategy: XAxisStrategy,
              dataList: [String]?,
              isDragging: Bool)
    // Int にするか CGFloat にして無断階にするかはどちらも一長一短あるが、検討の結果Intにする
    // Intにするとローソク足のヒゲとぴったり重なり、ヒゲが見づらくなるデメリットがあるが、
    // CGFloatにすると現在選択中のレコードがはっきり分かりづらいというデメリットがある
    /// マーカーを表示するインデックス
    var index: Int? { get set }

    func adjustIndex(removeCount: Int)
}

/// X軸のマーカー標準実装
open class TimeMarker: XAxisMarker {
    
    nonisolated(unsafe) public static var defaultFontColor: UIColor = UIColor.white
    nonisolated(unsafe) public static var defaultLineColor: UIColor = UIColor.gray
    nonisolated(unsafe) public static var defaultMarkerColor: UIColor = UIColor(rgbHex: "5B84C7")
    nonisolated(unsafe) public static var defaultDraggingTextBackgroundColor: UIColor = UIColor(white: 0.5, alpha: 0.4)
    nonisolated(unsafe) public static var defaultDraggingTextColor: UIColor = UIColor.white

    /// ラインを表示するか
    open var showLine = false
    /// ラインの幅
    open var lineWidth: CGFloat = 0.5
    /// ラインの色
    open var lineColor: UIColor = TimeMarker.defaultLineColor
    /// ラインの破線の実線と空白の幅（破線にしない場合はnil）
    open var lineDashIntervals: [CGFloat]?
    /// フォントの色
    open var fontColor: UIColor = TimeMarker.defaultFontColor
    /// マーカーの色
    open var markerColor: UIColor = TimeMarker.defaultMarkerColor
    /// マーカーの左右余白
    open var markerPadding: CGFloat = 5
    /// マーカーの三角形の幅
    open var arrowWidth: CGFloat = 5
    /// マーカーの最小の高さ。マーカーの高さはフォントの高さに応じて決まるが、このサイズより小さくならない
    open var minMarkerHeight: CGFloat = 14
    /// ドラッグ中に表示するテキストの背景色
    open var draggingTextBackgroundColor: UIColor = TimeMarker.defaultDraggingTextBackgroundColor
    /// ドラッグ中に表示するテキストの背景の角丸サイズ
    open var draggingTextBackgroundCornerRadius: CGFloat = 4
    /// ドラッグ中に表示するテキストの色
    open var draggingTextColor: UIColor = TimeMarker.defaultDraggingTextColor
    /// ドラッグ中に表示するテキストの文字サイズ
    open var draggingFontSize: CGFloat = 18.0
    
    /// マーカーを表示するインデックス
    open var index: Int?
    
    public init(index: Int? = nil, showLine: Bool = false) {
        self.index = index
        self.showLine = showLine
    }
    
    /// 描画する
    public func draw(context: ChartDrawingContext,
                     xAxis: XAxis,
                     xAxisRect: CGRect,
                     graphRect: CGRect,
                     visibleSpan: ClosedRange<Int>,
                     font: UIFont,
                     strategy: XAxisStrategy,
                     dataList: [String]?,
                     isDragging: Bool) {
        guard let timeList = dataList else { return }
        guard let index = index, visibleSpan.contains(index) else { return }
        let text = strategy.format(index: index, axisValue: timeList[safe: index])
        let detailedText = strategy.detailedFormat(index: index, axisValue: timeList[safe: index])
        let cgContext = context.cgContext
        cgContext.saveGState()
        
        let x = xAxisRect.maxX + context.rightOffset - (context.xAxisInterval / 2) - CGFloat(visibleSpan.upperBound - index) * context.xAxisInterval
        if x <= xAxisRect.minX || xAxisRect.maxX <= x {
            return
        }
        let attrs: [NSAttributedString.Key: Any] = [ .font: font, .foregroundColor: fontColor]
        let fontSize = text.size(withAttributes: attrs)
        let xOffset = -(fontSize.width / 2)
        let yOffset = round((xAxisRect.height - fontSize.height) / 2)
        let markerHeight = max(minMarkerHeight, fontSize.height)
        let markerWidth = fontSize.width + (markerPadding * 2)
        let markerX = x + xOffset - markerPadding
        
        // マーカーの描画
        cgContext.setFillColor(markerColor.cgColor)
        cgContext.move(to: CGPoint(x: x, y: xAxisRect.minY))
        cgContext.addLine(to: CGPoint(x: x - (arrowWidth / 2), y: xAxisRect.minY + yOffset))
        cgContext.addLine(to: CGPoint(x: x + (arrowWidth / 2), y: xAxisRect.minY + yOffset))
        cgContext.fillPath()
        cgContext.fill(CGRect(x: markerX, y: xAxisRect.minY + yOffset, width: markerWidth, height: markerHeight))
        
        // テキストの描画
        text.draw(at: CGPoint(x: x + xOffset, y: xAxisRect.minY + yOffset), withAttributes: attrs)
        
        // ラインの描画
        if showLine {
            let points = [CGPoint(x: x, y: graphRect.minY), CGPoint(x: x, y: graphRect.maxY)]
            cgContext.addLines(between: points)
            cgContext.setLineWidth(lineWidth)
            if let lineDashIntervals = lineDashIntervals {
                cgContext.setLineDash(phase: 0, lengths: lineDashIntervals)
            }
            cgContext.setStrokeColor(lineColor.cgColor)
            cgContext.strokePath()
        }
        
        // ドラッグ中の表示
        if isDragging && detailedText.isNotEmpty {
            let font = font.withSize(draggingFontSize)
            let attrs: [NSAttributedString.Key: Any] = [ .font: font, .foregroundColor: draggingTextColor]
            
            // マーカーの描画
            let size = detailedText.size(withAttributes: attrs)
            let y = (graphRect.height - size.height) / 2
            let width = size.width + (markerPadding * 2)
            let xOffset = -width / 2
            let path = UIBezierPath(roundedRect: CGRect(x: x + xOffset, y: y, width: width, height: size.height),
                                    cornerRadius: draggingTextBackgroundCornerRadius).cgPath
            cgContext.setFillColor(draggingTextBackgroundColor.cgColor)
            cgContext.addPath(path)
            cgContext.fillPath()
            
            // テキストの描画
            detailedText.draw(at: CGPoint(x: x + xOffset + markerPadding, y: y), withAttributes: attrs)
        }

        cgContext.restoreGState()
    }

    public func adjustIndex(removeCount: Int) {
        guard let index = index else { return }
        self.index = index - removeCount
    }
}
