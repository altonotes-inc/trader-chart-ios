//
//  ChartRecord.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/14.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// チャートの一時点のレコード
public struct ChartRecord {
    /// 日時
    public let time: String?
    /// 始値
    public let open: CGFloat?
    /// 高値
    public let high: CGFloat?
    /// 安値
    public let low: CGFloat?
    /// 終値
    public let close: CGFloat?
    /// 出来高
    public let volume: CGFloat?
    /// VWAP
    public let vwap: CGFloat?

    public init(time: String?,
                open: CGFloat?,
                high: CGFloat?,
                low: CGFloat?,
                close: CGFloat?,
                volume: CGFloat? = nil,
                vwap: CGFloat? = nil) {

        self.time = time
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.vwap = vwap
    }
}
