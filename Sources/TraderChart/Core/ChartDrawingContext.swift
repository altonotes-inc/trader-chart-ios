//
//  ChartContext.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 描画コンテキスト
public class ChartDrawingContext {
    /// 描画に使うChartViewのCGContext
    public let cgContext: CGContext
    /// X軸の刻み幅
    public let xAxisInterval: CGFloat
    /// 右端からのスクロール位置
    public let scrollOffset: CGFloat

    init(cgContext: CGContext,
         xAxisInterval: CGFloat,
         scrollOffset: CGFloat) {
        self.cgContext = cgContext
        self.xAxisInterval = xAxisInterval
        self.scrollOffset = scrollOffset
    }

    /// visibleSpan右端のX座標オフセット
    public var rightOffset: CGFloat {
        let index = floor(scrollOffset / xAxisInterval)
        let divisibleMove = xAxisInterval * index
        return scrollOffset - divisibleMove
    }

    /// 現在のスクロール位置で画面に表示されるプロットのインデックスの範囲
    public func visibleSpan(width: CGFloat, recordCount: Int?) -> ClosedRange<Int> {
        let visibleCount = width / xAxisInterval
        let recordCount = CGFloat(recordCount ?? 0)
        let toIndex = recordCount - (scrollOffset / xAxisInterval) - 1
        let fromIndex = toIndex - visibleCount + 1
        return Int(fromIndex)...Int(ceil(toIndex))
    }
}
