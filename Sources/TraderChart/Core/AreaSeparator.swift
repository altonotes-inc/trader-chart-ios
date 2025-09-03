//
//  AreaSeparator.swift
//  TraderChart
//
//  Created by altonotes on 2019/06/25.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// グラフエリアの仕切り線
public class AreaSeparator: ColorConfigurable {

    /// 仕切り線の色
    public var lineColor = UIColor.lightGray
    
    /// 仕切り線の幅
    public var lineWidth: CGFloat = 0.5

    /// 初期化
    public init() {}
    
    /// 初期化
    public init(width: CGFloat, color: UIColor) {
        lineWidth = width
        lineColor = color
    }
    
    /// 色設定を反映する
    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        lineColor = colorConfig["area_separator"] ?? lineColor
    }
    
    ///　描画する
    open func draw(context: ChartDrawingContext, graphRect: CGRect) {
        let cgContext = context.cgContext
        
        cgContext.saveGState()
        
        cgContext.setLineWidth(lineWidth)
        cgContext.setShouldAntialias(false)
        cgContext.beginPath()
        lineColor.setStroke()
        
        let y = graphRect.minY - lineWidth / 2
        cgContext.addLines(between: [CGPoint(x: graphRect.minX, y: y), CGPoint(x: graphRect.maxX, y: y)])
        cgContext.strokePath()
        
        cgContext.restoreGState()
    }
}
