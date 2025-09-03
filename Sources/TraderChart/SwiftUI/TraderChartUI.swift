import SwiftUI

/// TraderChartViewをSwiftUIで使用するためのUIViewRepresentable
public struct TraderChartUI: UIViewRepresentable {
    let chartView: TraderChartView

    public init(chartView: TraderChartView) {
        self.chartView = chartView
    }
    
    public func makeUIView(context: Context) -> TraderChartView {
        return chartView
    }
    
    public func updateUIView(_ uiView: TraderChartView, context: Context) {
        // 特に更新処理は不要
    }
}
