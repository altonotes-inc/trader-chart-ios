//
//  MACDCalculator.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/22.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// MACDの計算
public class MACDCalculator {

    let emaCalculator = EMACalculator()
    let smaCalculator = SMACalculator()
    
    /// シグナルの計算タイプ
    public var signalType: SignalType

    /// 初期化
    public init(signalType: SignalType = .ema) {
        self.signalType = signalType
    }

    /// 計算する
    ///
    /// - Parameters:
    ///   - shortSpan: 短期EMAのスパン
    ///   - longSpan: 長期EMAのスパン
    ///   - signalSpan: シグナルのスパン
    ///   - src: 終値の配列
    /// - Returns: 計算結果
    public func calculate(shortSpan: Int, longSpan: Int, signalSpan: Int, src: NumberArray?) -> Results? {
        guard let src = src else { return nil }
        
        // MACD = 短期EMA - 中期EMA
        // シグナル = MACDのEMA
        // オシレータ = MACD - シグナル

        guard let emaShortList = emaCalculator.calculate(span: shortSpan, src: src) else { return nil }
        guard let emaLongList = emaCalculator.calculate(span: longSpan, src: src) else { return nil }
        
        // MACDの計算
        let macdList = NumberArray()
        
        for i in emaShortList.indicies {
            var macd: CGFloat? = nil
            if let emaShort = emaShortList[i], let emaLong = emaLongList[i] {
                macd = emaShort - emaLong
            }
            macdList.append(macd)
        }
        
        // シグナルの計算
        guard let signalList = (signalType == .ema) ?
            emaCalculator.calculate(span: signalSpan, src: macdList)
            : smaCalculator.calculate(span: signalSpan, src: macdList) else {
                return nil
        }
        
        // オシレーター
        let oscList = NumberArray()
        for i in macdList.indicies {
            var osc: CGFloat? = nil
            if let macd = macdList[i], let signal = signalList[i] {
                osc = macd - signal
            }
            oscList.append(osc)
        }
        return Results(macd: macdList, signal: signalList, osc: oscList, emaShortList: emaShortList, emaLongList: emaLongList)
    }
    
    public func update(shortSpan: Int, longSpan: Int, signalSpan: Int, src: NumberArray?, results: Results? = nil) -> Results? {
        guard let src = src else { return results }
        guard let results = results else { return calculate(shortSpan: shortSpan, longSpan: longSpan, signalSpan: signalSpan, src: src) }
        let remainingCount = src.count - results.count
        
        // 短期EMA, 長期EMAの計算
        guard let emaShortList = EMACalculator().update(span: shortSpan, src: src, emaList: results.emaShortList) else { return results }
        guard let emaLongList = EMACalculator().update(span: longSpan, src: src, emaList: results.emaLongList) else { return results }

        // MACDの計算
        let macdList = results.macd.copy()
        
        (0..<remainingCount).forEach { _ in
            var macd: CGFloat? = nil
            if let emaShort = emaShortList[macdList.count], let emaLong = emaLongList[macdList.count] {
                macd = emaShort - emaLong
            }
            macdList.append(macd)
        }
        
        // シグナルの計算
        guard let signalList = (signalType == .ema) ?
            emaCalculator.update(span: signalSpan, src: macdList, emaList: results.signal)
            : smaCalculator.calculate(span: signalSpan, src: macdList, existingSMA: results.signal) else {
                return results
        }
        
        // オシレーター
        let oscList = results.osc.copy()
        (0..<remainingCount).forEach { _ in
            var osc: CGFloat? = nil
            if let macd = macdList[oscList.count], let signal = signalList[oscList.count] {
                osc = macd - signal
            }
            oscList.append(osc)
        }
        return Results(macd: macdList, signal: signalList, osc: oscList, emaShortList: emaShortList, emaLongList: emaLongList)
    }
    
    public enum SignalType {
        case sma
        case ema
    }

    /// MACDの計算結果
    public struct Results {
        public let macd: NumberArray
        public let signal: NumberArray
        public let osc: NumberArray
        public let emaShortList: NumberArray
        public let emaLongList: NumberArray
        
        public var count: Int {
            return macd.count
        }

        /// 初期化
        public init(macd: NumberArray, signal: NumberArray, osc: NumberArray, emaShortList: NumberArray, emaLongList: NumberArray) {
            self.macd = macd
            self.signal = signal
            self.osc = osc
            self.emaShortList = emaShortList
            self.emaLongList = emaLongList
        }
        
        public func removeLastFrom(_ index: Int?) {
            macd.removeLastFrom(index)
            signal.removeLastFrom(index)
            osc.removeLastFrom(index)
            emaShortList.removeLastFrom(index)
            emaLongList.removeLastFrom(index)
        }

        public func removeFirst(_ count: Int) {
            macd.removeFirst(count)
            signal.removeFirst(count)
            osc.removeFirst(count)
            emaShortList.removeFirst(count)
            emaLongList.removeFirst(count)
        }
    }
}
