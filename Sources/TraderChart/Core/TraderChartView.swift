//
//  TraderChartView.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/06/24.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 金融商品取引に特化したチャートのView。
/// ChartViewに各テクニカル指標の表示を追加している。
open class TraderChartView: ChartView {

    /// ローソク足
    public let candle = Candle()
    /// 転換点
    public let turningPoint = TurningPoint()
    /// 価格ライン
    public let priceLine = PriceLine()

    /// 移動平均
    public let sma = SMA()
    /// 指数平滑移動平均
    public let ema = EMA()
    /// 多重移動平均
    public let multipleSma = MultipleSMA()
    /// 一目均衡表
    public let ichimoku = Ichimoku()
    /// Bollinger band
    public let bollingerBand = BollingerBand()
    /// VWAP
    public let vwap = VWAP()
    /// エンベロープ
    public let envelope = Envelope()
    /// パラボリック
    public let parabolic = Parabolic()

    /// MACD
    public let macd = MACD()
    /// RSI
    public let rsi = RSI()
    /// RCI
    public let rci = RCI()
    /// DIM/ADX
    public let dmiAdx = DMIADX()
    /// Stochastics
    public let stochastics = Stochastics()
    /// 出来高
    public let volume = Volume()
    /// 標準偏差
    public let standardDeviation = StandardDeviation()
    /// モメンタム
    public let momentum = Momentum()
    /// 移動平均乖離率
    public let movingAverageDifference = MovingAverageDifference()
    /// サイコロジカル
    public let psychological = Psychological()

    open override func commonInit() {
        super.commonInit()

        setMainCharts(mainCharts)
        setSubCharts(subCharts)

        setVisibleMainCharts([candle, turningPoint])
        setVisibleSubCharts([])
    }

    /// メインエリアに表示可能なテクニカルチャート
    open var mainCharts: [TechnicalChart] {
        return [
            candle,
            priceLine,
            sma,
            ema,
            multipleSma,
            ichimoku,
            bollingerBand,
            vwap,
            envelope,
            parabolic,
            turningPoint
        ]
    }

    /// サブエリアに表示可能なテクニカルチャート
    open var subCharts: [TechnicalChart] {
        return [
            macd,
            rsi,
            rci,
            dmiAdx,
            stochastics,
            volume,
            standardDeviation,
            momentum,
            movingAverageDifference,
            psychological
        ]
    }

    /// 表示するメインチャートを設定する
    public func setVisibleMainChartTypes(_ types: [MainChartItem]) {
        let charts = types.map { self.mainChart(type: $0) }
        setVisibleMainCharts(charts)
    }

    /// 表示するサブチャートを設定する
    public func setVisibleSubChartTypes(_ types: [SubChartItem]) {
        let charts = types.map { self.subChart(type: $0) }
        setVisibleSubCharts(charts)
    }

    /// メインチャートの `enum`　に対応する `TechnicalChart` インスタンスを取得する
    public func mainChart(type: MainChartItem) -> TechnicalChart {
        switch type {
        case .candle: return candle
        case .priceLine: return priceLine
        case .sma: return sma
        case .multipleSma: return multipleSma
        case .ema: return ema
        case .ichimoku: return ichimoku
        case .bollingerBand: return bollingerBand
        case .vwap: return vwap
        case .envelope: return envelope
        case .turningPoint: return turningPoint
        case .parabolic: return parabolic

        }
    }

    /// サブチャートの `enum`　に対応する `TechnicalChart` インスタンスを取得する
    public func subChart(type: SubChartItem) -> TechnicalChart {
        switch type {
        case .macd: return macd
        case .stochastics: return stochastics
        case .rsi: return rsi
        case .rci: return rci
        case .dmiAdx: return dmiAdx
        case .volume: return volume
        case .standardDeviation: return standardDeviation
        case .momentum: return momentum
        case .movingAverageDifference: return movingAverageDifference
        case .psychological: return psychological
        }
    }
}
