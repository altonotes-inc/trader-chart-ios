//
//  TechnicalChart.swift
//  TraderChart
//
//  Created by 山本敬太 on 2019/06/30.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// テクニカル指標
public protocol TechnicalChart: GraphAreaDrawer, ColorConfigurable {
    /// 表示/非表示の切り替え
    var isVisible: Bool { get set }

    /// 凡例。nilの場合は凡例を表示しない
    func legend(selectedIndex: Int?) -> Legend?

    ///　チャートの4本値一覧データを更新する
    ///
    /// - Parameters:
    ///   - data: チャートデータ
    ///   - updatedFrom: 更新された部分の先頭のインデックス
    func updateData(_ data: ChartData?, updatedFrom: Int?)
    
    ///　Y軸を更新する
    func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>)
    
    ///　X軸を更新する
    func updateXAxis(_ xAxis: XAxis, data: ChartData?)
    
    ///　保持するデータをクリアする
    func clear()

    ///　パラメーターの変更を通知する
    func onParameterChanged()

    /// 最古のデータを指定の数だけ削除する
    func removeOldData(count: Int)
}

open class SimpleTechnicalChart: TechnicalChart {
    /// 初期化
    public init() {}
    
    open var isVisible: Bool = true
    public func legend(selectedIndex: Int?) -> Legend? { return nil }
    open func updateData(_ data: ChartData?, updatedFrom: Int?) {}
    open func updateYAxis(_ yAxis: YAxis, data: ChartData?, height: CGFloat, visibleSpan: ClosedRange<Int>) {}
    open func updateXAxis(_ xAxis: XAxis, data: ChartData?) {}
    open func clear() {}
    open func onParameterChanged() {}
    open func draw(context: ChartDrawingContext, yAxis: YAxis, data: ChartData?, rect: CGRect, visibleSpan: ClosedRange<Int>) {}
    open func reflectColorConfig(_ colorConfig: ColorConfig) {}
    open func removeOldData(count: Int) {}
}
