//
//  CGContext+Utils.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/07/09.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

public extension CGContext {

    func drawString(_ string: String, rect: CGRect, font: UIFont, color: UIColor) {
        let attrStr = NSAttributedString(string: string, attributes: [
            .font: font,
            .foregroundColor: color
        ])
        let setter = CTFramesetterCreateWithAttributedString(attrStr)
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(setter, CFRange(), path, nil)
        CTFrameDraw(frame, self)
    }
}
