//
//  GraphAreaDrawer.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/30.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// グラフ領域の描画オブジェクト
public protocol GraphAreaDrawer: class {
    ///　描画する
    func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>)
}
