//
//  ChartDrawer.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// チャート全体の描画のインターフェース
public protocol ChartDrawer: class {
    func draw(context: ChartDrawingContext,
              data: ChartData?,
              rect: CGRect,
              chartRect: CGRect,
              visibleSpan: ClosedRange<Int>)
}
