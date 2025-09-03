//
//  LegendDrawer.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/07/02.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 凡例の描画
open class LegendDrawer: UsesFontContext {
    /// 表示するか
    open var isVisible = true

    /// 標準のフォントサイズ
    public static let defaultFontSize: CGFloat = 10

    /// フォントの色
    open var fontColor: UIColor = UIColor.white
    /// 背景色
    open var backgroundColor: UIColor?
    /// フォント
    open var font: UIFont = UIFont.systemFont(ofSize: defaultFontSize)

    /// 左の余白
    open var leftMargin: CGFloat = 3
    /// 上の余白
    open var topMargin: CGFloat = 0
    /// 横並びの項目間の余白
    open var itemSpacing: CGFloat = 3
    /// 行間の余白
    open var lineSpacing: CGFloat = 2
    /// 複数凡例間の余白
    open var legendSpacing: CGFloat = 0
    
    public init() {
    }

    /// フォント設定を反映する
    public func reflectFontContext(_ fontContext: FontContext) {
        font = fontContext.descriptionFont(size: LegendDrawer.defaultFontSize)
    }

    /// 描画する
    open func draw(context: ChartDrawingContext, graphRect: CGRect, legends: [Legend]) {
        if !isVisible { return }
        let baseX = graphRect.minX + leftMargin
        let baseY = graphRect.minY + topMargin

        // 背景色の描画
        if let backgroundColor = backgroundColor {
            var width: CGFloat = 0
            var height: CGFloat = 0
            legends.forEach { legend in
                legend.lines.forEach { line in
                    var lineWidth: CGFloat = 0
                    var lineHeight: CGFloat = 0
                    line.filter { $0.isVisible }.forEach { colorText in
                        let fontSize = colorText.text.size(withAttributes: [.font: font])
                        lineWidth += fontSize.width + itemSpacing
                        lineHeight = max(lineHeight, fontSize.height)
                    }
                    width = max(width, lineWidth)
                    height += lineHeight + lineSpacing
                }
                height += legendSpacing
            }

            context.cgContext.setFillColor(backgroundColor.cgColor)
            context.cgContext.fill(CGRect(x: baseX, y: baseY, width: width, height: height))
        }

        var y = baseY
        var maxX: CGFloat = 0
        legends.forEach { legend in
            legend.lines.forEach { line in
                var x = baseX
                var lineHeight: CGFloat = 0
                line.filter { $0.isVisible }.forEach { colorText in
                    let fontSize = colorText.text.size(withAttributes: [.font: font])
                    colorText.text.draw(at: CGPoint(x: x, y: y),
                                        withAttributes: [.font: font, .foregroundColor: colorText.color])
                    x += fontSize.width + itemSpacing
                    maxX = max(maxX, x)
                    lineHeight = max(lineHeight, fontSize.height)
                }
                y += lineHeight + lineSpacing
            }
            y += legendSpacing
        }
    }
}
