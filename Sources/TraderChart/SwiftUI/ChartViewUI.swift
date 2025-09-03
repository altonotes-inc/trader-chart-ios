import SwiftUI

/// ChartViewをSwiftUIで使用するためのUIViewRepresentable
public struct ChartViewUI: UIViewRepresentable {
    let chartView: ChartView
    
    public init(chartView: ChartView) {
        self.chartView = chartView
    }
    
    public func makeUIView(context: Context) -> ChartView {
        return chartView
    }
    
    public func updateUIView(_ uiView: ChartView, context: Context) {
        // 特に更新処理は不要
    }
}
