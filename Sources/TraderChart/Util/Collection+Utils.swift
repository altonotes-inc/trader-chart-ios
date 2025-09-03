//
//  Collection+Utils.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/07/03.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

internal extension Collection {
    // 指定したindexの要素を取得する。
    // 通常の[]による要素取得と異なり、マイナスや存在しないインデックスを指定してもクラッシュせずnilを返す。
    // ex. list[safe: 10]
    subscript (safe index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[self.index(startIndex, offsetBy: index)]
        }
        return nil
    }
}
