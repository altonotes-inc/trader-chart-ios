//
//  ChartItem.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/24.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// TraderChartView向けの組み込みテクニカル指標
public protocol ChartItem {
    var displayName: String { get }
    var name: String { get }
}

/// メイン組み込みテクニカル指標
public enum MainChartItem: String, ChartItem, CaseIterable {
    /// ローソク足
    case candle
    /// ラインチャート
    case priceLine
    /// 単純移動平均
    case sma
    /// 指数平滑移動平均
    case ema
    /// 一目均衡表
    case ichimoku
    /// ボリンジャーバンド
    case bollingerBand
    /// VWAP
    case vwap
    /// 転換点
    case turningPoint
    /// 多重移動平均
    case multipleSma
    /// エンベロープ
    case envelope
    /// パラボリック
    case parabolic

    public var name: String { return rawValue }

    public var displayName: String {
        switch self {
        case .candle: return "ローソク足"
        case .priceLine: return "ラインチャート"
        case .sma: return "単純移動平均"
        case .ema: return "指数平滑移動平均"
        case .ichimoku: return "一目均衡表"
        case .bollingerBand: return "ボリンジャーバンド"
        case .vwap: return "VWAP"
        case .turningPoint: return "転換点"
        case .multipleSma: return "多重移動平均"
        case .envelope: return "エンベロープ"
        case .parabolic: return "パラボリック"
        }
    }
}

/// サブ組み込みテクニカル指標
public enum SubChartItem: String, ChartItem, CaseIterable {
    /// MACD
    case macd
    /// ストキャスティクス
    case stochastics
    /// RSI
    case rsi
    /// RCI
    case rci
    /// DMI/ADX
    case dmiAdx
    /// 出来高
    case volume
    /// 標準偏差
    case standardDeviation
    /// モメンタム
    case momentum
    /// 移動平均乖離率
    case movingAverageDifference
    /// サイコロジカル
    case psychological

    public var name: String { return rawValue }

    public var displayName: String {
        switch self {
        case .macd: return "MACD"
        case .rsi: return "RSI"
        case .rci: return "RCI"
        case .stochastics: return "ストキャスティクス"
        case .dmiAdx: return "DMI/ADX"
        case .volume: return "出来高"
        case .standardDeviation: return "標準偏差"
        case .momentum: return "モメンタム"
        case .movingAverageDifference: return "移動平均乖離率"
        case .psychological: return "サイコロジカル"
        }
    }
}
