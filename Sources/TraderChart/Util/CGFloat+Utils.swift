//
//  CGFloat+Utils.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/06.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

internal extension CGFloat {
    
    // 数値を文字列に変換して返す
    var stringValue: String {
        return description
    }
    
    // Double値に変換
    var doubleValue: Double {
        return Double(self)
    }
    
    // NSDecimalNumberに変換
    var decimalNumber: NSDecimalNumber {
        return Double(self).decimalNumber
    }
    
    // 数値を指定した小数桁で四捨五入した文字列を返す
    func stringValue(decimalLength: Int) -> String {
        if isNaN {
            return description
        }
        
        return NSDecimalNumber(value: Double(self)).stringValue(decimalLength: decimalLength)
    }
    
}
