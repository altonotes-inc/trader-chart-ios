//
//  ColorText.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/07/02.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 色指定されたテキスト。主に凡例の位置項目を表現するのに使う
public struct ColorText {
    /// テキスト
    public let text: String
    /// 色
    public let color: UIColor
    /// 表示するか
    public let isVisible: Bool

    public init(_ text: String, _ color: UIColor, visible: Bool = true) {
        self.text = text
        self.color = color
        self.isVisible = visible
    }
}
