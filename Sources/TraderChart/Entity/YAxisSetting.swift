//
//  YAxisSetting.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/13.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 全グラフエリアのY軸共通の設定
public class YAxisSetting {
    /// Y軸の左右位置
    public var alignment = YAxisAlignment.right
    /// Y軸の幅
    public var width: CGFloat = 55
    /// Y軸をグラフエリアと重ねるか
    public var graphOverwrap = false
    
    /// 表示する横幅。非表示の場合0
    public var visibleWidth: CGFloat {
        return isVisible ? width : 0.0
    }
    
    /// 表示するか
    public var isVisible: Bool = true
}
