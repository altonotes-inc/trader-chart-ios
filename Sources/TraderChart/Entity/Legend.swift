//
//  Legend.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/07/02.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 凡例
public struct Legend {
    /// 凡例の行
    public var lines: [[ColorText]] = []

    /// 行の項目の配列を指定して初期化
    public init(_ line: [ColorText]) {
        lines.append(line)
    }

    /// 行のリストを指定して初期化
    public init(lines: [[ColorText]]) {
        self.lines = lines
    }
}
