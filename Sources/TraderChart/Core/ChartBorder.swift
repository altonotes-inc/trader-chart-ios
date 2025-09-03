//
//  ChartBorder.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/20.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// チャートの枠線
public class ChartBorder: ColorConfigurable {

    /// 左の枠線の色
    public var leftColor = UIColor.lightGray
    /// 右の枠線の色
    public var rightColor = UIColor.lightGray
    /// 上の枠線の色
    public var topColor = UIColor.lightGray
    /// 下の枠線の色
    public var bottomColor = UIColor.lightGray

    /// 左の枠線の幅
    public var leftWidth: CGFloat = 0.5
    /// 右の枠線の幅
    public var rightWidth: CGFloat = 0.5
    /// 上の枠線の幅
    public var topWidth: CGFloat = 0.5
    /// 下の枠線の幅
    public var bottomWidth: CGFloat = 0.5

    public init() {}
    
    public init(width: CGFloat, color: UIColor) {
        setWidth(left: width, right: width, top: width, bottom: width)
        setColor(left: color, right: color, top: color, bottom: color)
    }
    
    /// 色設定を反映する
    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        leftColor = colorConfig["border.left"] ?? leftColor
        rightColor = colorConfig["border.right"] ?? rightColor
        topColor = colorConfig["border.top"] ?? topColor
        bottomColor = colorConfig["border.bottom"] ?? bottomColor
    }
    
    /// 上下左右の枠線の幅を指定する
    public func setWidth(left: CGFloat, right: CGFloat, top: CGFloat, bottom: CGFloat) {
        leftWidth = left
        rightWidth = right
        topWidth = top
        bottomWidth = bottom
    }
    
    /// 上下左右の枠線の色を指定する
    public func setColor(left: UIColor, right: UIColor, top: UIColor, bottom: UIColor) {
        leftColor = left
        rightColor = right
        topColor = top
        bottomColor = bottom
    }
    
    ///　描画する
    open func draw(context: ChartDrawingContext, outerRect: CGRect) {
        let cgContext = context.cgContext

        cgContext.saveGState()

        var x: CGFloat = 0
        cgContext.setStrokeColor(leftColor.cgColor)
        cgContext.setLineWidth(leftWidth)
        x = outerRect.minX + leftWidth / 2
        cgContext.addLines(between: [CGPoint(x: x, y: outerRect.minY), CGPoint(x: x, y: outerRect.maxY)])
        cgContext.strokePath()

        cgContext.setStrokeColor(rightColor.cgColor)
        cgContext.setLineWidth(rightWidth)
        x = outerRect.maxX - rightWidth / 2
        cgContext.addLines(between: [CGPoint(x: x, y: outerRect.minY), CGPoint(x: x, y: outerRect.maxY)])
        cgContext.strokePath()

        var y: CGFloat = 0
        cgContext.setStrokeColor(topColor.cgColor)
        cgContext.setLineWidth(topWidth)
        y = outerRect.minY + topWidth / 2
        cgContext.addLines(between: [CGPoint(x: outerRect.minX, y: y), CGPoint(x: outerRect.maxX, y: y)])
        cgContext.strokePath()

        cgContext.setStrokeColor(bottomColor.cgColor)
        cgContext.setLineWidth(bottomWidth)
        y = outerRect.maxY - bottomWidth / 2
        cgContext.addLines(between: [CGPoint(x: outerRect.minX, y: y), CGPoint(x: outerRect.maxX, y: y)])
        cgContext.strokePath()

        cgContext.restoreGState()
    }
}
