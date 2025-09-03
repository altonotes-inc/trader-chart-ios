//
//  Double+Utils.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/06.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

internal extension Double {
    // NSDecimalNumberに変換
    var decimalNumber: NSDecimalNumber {
        // NSDecimalNumber(value: Double)を使うと浮動小数点誤差が出るため、NSNumber.stringValueからNSDecimalNumberを作る
        let number = self as NSNumber
        return NSDecimalNumber(string: number.stringValue)
    }
    
    // CGFloatに変換して返す
    var cgFloatValue: CGFloat {
        return CGFloat(self)
    }
}
