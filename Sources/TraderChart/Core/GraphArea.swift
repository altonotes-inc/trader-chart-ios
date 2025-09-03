//
//  GraphArea.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// チャート内のグラフ描画領域
open class GraphArea: ColorConfigurable, UsesFontContext {

    /// 表示するか
    open var isVisible: Bool = true
    /// エリアの高さ。nilの場合はheightWeightにより全体の割合で高さが決まる
    open var height: CGFloat?
    /// エリアの高さ比率。heightが指定された場合は無視される
    open var heightWeight: CGFloat
    /// Y軸を含まない図形描画領域
    open var graphRect: CGRect = CGRect.zero
    /// 描画するチャート
    open var charts: [TechnicalChart] = []
    /// Y軸
    open var yAxis = YAxis()
    /// 凡例の描画
    open var legendDrawer = LegendDrawer()

    public init(height: CGFloat? = nil, heightWeight: CGFloat = 1) {
        self.height = height
        self.heightWeight = heightWeight
    }

    /// Y軸領域のCGRectを返す
    open func yAxisRect(chartRect: CGRect, setting: YAxisSetting, border: ChartBorder) -> CGRect {
        let outerRect = setting.graphOverwrap ? graphRect : chartRect
        let x = (setting.alignment == YAxisAlignment.left)
            ? outerRect.minX : outerRect.maxX - setting.visibleWidth
        return CGRect(x: x,
                      y: graphRect.minY,
                      width: setting.visibleWidth,
                      height: graphRect.height)
    }

    /// 各テクニカルチャートによりX軸の範囲を更新する
    open func updateXAxis(_ xAxis: XAxis, data: ChartData?) {
        charts.forEach {
            if $0.isVisible {
                $0.updateXAxis(xAxis, data: data)
            }
        }
    }

    /// 各テクニカルチャートにデータを反映する
    open func updateData(_ data: ChartData?, updatedFrom: Int?) {
        charts.forEach {
            if $0.isVisible {
                $0.updateData(data, updatedFrom: updatedFrom)
            }
        }
    }

    /// 最古のデータを削除する
    open func removeOldData(count: Int) {
        charts.forEach {
            if $0.isVisible {
                $0.removeOldData(count: count)
            }
        }
    }

    /// 色設定を反映する
    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        yAxis.reflectColorConfig(colorConfig)
        charts.forEach {
            $0.reflectColorConfig(colorConfig)
        }
    }

    /// フォント設定を反映する
    public func reflectFontContext(_ fontContext: FontContext) {
        yAxis.reflectFontContext(fontContext)
        legendDrawer.reflectFontContext(fontContext)
        charts.forEach {
            ($0 as? UsesFontContext)?.reflectFontContext(fontContext)
        }
    }

    /// 描画する
    open func draw(context: ChartDrawingContext,
                   data: ChartData?,
                   yAxisSetting: YAxisSetting,
                   selectedIndex: Int?,
                   visibleSpan: ClosedRange<Int>,
                   colorConfig: ColorConfig?) {
        let charts = self.charts.filter { $0.isVisible }

        // Y軸の更新
        yAxis.update(data: data, charts: charts, visibleSpan: visibleSpan)
        
        // グラフの描画
        if yAxis.isValid {
            if yAxisSetting.isVisible {
                yAxis.drawBeforeChart(context: context, graphRect: graphRect, yAxisSetting: yAxisSetting)
            }
            charts.forEach {
                $0.draw(context: context, yAxis: yAxis, data: data, rect: graphRect, visibleSpan: visibleSpan)
            }
            if yAxisSetting.isVisible {
                yAxis.drawAfterChart(context: context, graphRect: graphRect, yAxisSetting: yAxisSetting)
            }
        }
        let legends = charts.compactMap { $0.legend(selectedIndex: selectedIndex) }
        legendDrawer.draw(context: context, graphRect: graphRect, legends: legends)
    }

    /// 表示するテクニカルチャートを指定する
    public func setVisibleCharts(_ charts: [TechnicalChart], data: ChartData?) {
        self.charts.forEach { chart in
            if charts.contains(where: { $0 === chart }) {
                if !chart.isVisible {
                    chart.isVisible = true
                    chart.clear()
                    chart.updateData(data, updatedFrom: nil)
                }
            } else {
                chart.isVisible = false
            }
        }
    }

    /// テクニカル指標パラメータの変更を各テクニカルチャートに通知する
    public func refrectParameterChange(data: ChartData?) {
        charts.forEach { chart in
            chart.onParameterChanged()
            if chart.isVisible {
                chart.updateData(data, updatedFrom: nil)
            }
        }
    }
    
    open func touchesBegan(point: CGPoint) -> Bool {
        guard yAxis.isTouchEnabled && yAxis.rect.contains(point) else { return false }
        yAxis.touchMarker.value = valueOf(point: point)
        yAxis.isDragging = true
        return true
    }
    
    @discardableResult
    open func touchesMoved(point: CGPoint) -> Bool {
        guard yAxis.isTouchEnabled else { return false }
        yAxis.touchMarker.value = valueOf(point: point)
        return true
    }
    
    @discardableResult
    open func touchesCompleted(point: CGPoint) -> Bool {
        guard yAxis.isTouchEnabled else { return false }
        if yAxis.isDragging {
            yAxis.isDragging = false
            return true
        }
        return false
    }
    
    /// 引数に指定した座標に対応するY軸の値
    open func valueOf(point: CGPoint) -> CGFloat? {
        let value = yAxis.value(point.y)
        let paddingTopValue = yAxis.paddingTop / yAxis.valueHeightRate
        let paddingBottomValue = yAxis.paddingBottom / yAxis.valueHeightRate
        if value < (yAxis.min - paddingBottomValue) || (yAxis.max + paddingTopValue) < value {
            return nil
        } else {
            return value
        }
    }
    
    /// Y軸および各種テクニカルチャートの表示をクリアする
    open func clear() {
        yAxis.clear()
        charts.forEach {
            $0.clear()
        }
    }
    
    /// 別のGraphAreaの状態を引き継ぐ
    public func importState(from: GraphArea) {
        yAxis.importState(from: from.yAxis)
    }
}
