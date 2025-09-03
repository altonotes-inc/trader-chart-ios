//
//  FontContext.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/17.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// 共通のフォントを決定する
public protocol FontContext {
    func numericFont(size: CGFloat) -> UIFont
    func descriptionFont(size: CGFloat) -> UIFont
}

/// FontContextを判定可能なことを示すプロトコル
public protocol UsesFontContext {
    func reflectFontContext(_ fontContext: FontContext)
}

/// 標準のFontContext
public class DefaultFontContext: FontContext {
    public func numericFont(size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }

    public func descriptionFont(size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }
}
