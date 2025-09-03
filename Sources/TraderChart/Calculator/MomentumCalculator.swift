//
//  MomentumCalculator.swift
//  TraderChart
//
//  Created by altonotes on 2019/08/30.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// モメンタムの計算
public class MomentumCalculator {
    
    /// 計算タイプ
    public var type: CalculationType
    
    /// 初期化
    public init(type: CalculationType = .subtract) {
        self.type = type
    }
    
    /// 計算する
    ///
    /// - Parameters:
    ///   - span: 期間
    ///   - src: 計算元の数値配列
    /// - Returns: モメンタム
    public func calculate(span: Int, src: NumberArray?) -> NumberArray? {
        guard let src = src else { return nil }
        assert(0 < span, "span must be greater than 0")
        
        let result = NumberArray()
        for index in 0..<src.count {
            guard let value = src[index], !value.isNaN, let oldValue = src[index - span], !oldValue.isNaN else {
                result.append(nil)
                continue
            }
            switch type {
            case .subtract:
                result.append(value - oldValue)
            case .divide:
                result.append((value / oldValue) * 100)
            }
        }
        
        return result
    }
    
    /// 更新する
    ///
    /// - Parameters:
    ///   - span: 期間
    ///   - src: 計算元の数値配列
    ///   - momentumList: 計算済みのモメンタム
    /// - Returns: モメンタム
    public func update(span: Int, src: NumberArray?, momentumList: NumberArray? = nil) -> NumberArray? {
        guard let src = src else { return momentumList }
        guard let momentumList = momentumList else {
            return calculate(span: span, src: src)
        }
        let remainingData = src.subArray(from: max(0, momentumList.count - span))
        let result = calculate(span: span, src: remainingData)
        let additionalData = result?.last(size: src.count - momentumList.count)
        let list = momentumList.copy()
        list.append(other: additionalData)
        return list
    }
    
    public enum CalculationType {
        case subtract
        case divide
    }
}
