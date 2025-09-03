//
//  ChartView.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import UIKit

/// チャートの基盤View
open class ChartView: UIView, ColorConfigurable, UsesFontContext {
    
    static let defaultBackgroundColor: UIColor = UIColor.white
    static let defaultLoadingIndicatorColor: UIColor = UIColor.lightGray

    /// スクロール制御
    public let scroller = Scroller()
    /// チャートの枠線
    public let border = ChartBorder()
    /// グラフエリアの仕切り線
    public let separator = AreaSeparator()
    /// Y軸の設定
    public let yAxisSetting = YAxisSetting()

    /// マージンを除いた部分の背景色
    public var chartBackgroundColor: UIColor?
    /// グラフ描画領域の背景色
    public var graphBackgroundColor: UIColor?
    /// 上下左右の余白
    public var margin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    /// 全グラフ描画領域
    public var graphAreas: [GraphArea] {
        var areas = [GraphArea]()
        areas.append(mainGraphArea)
        areas.append(contentsOf: subGraphAreas)
        return areas
    }
    /// メインのグラフ描画領域
    public var mainGraphArea = GraphArea()
    /// サブグラフ描画領域
    public var subGraphAreas: [GraphArea] = []
    /// X軸
    public var xAxis = XAxis() {
        didSet {
            setXAxisTouchCallback()
            setXAxisIntervalChangeCallback()
        }
    }
    /// 背景の描画項目
    public var backgroundDrawers: [ChartDrawer] = []
    /// チャート上の描画項目
    public var overlayDrawers: [ChartDrawer] = []
    /// 選択されたレコードに変化があった場合に通知するコールバック。タッチ位置変更時とデータ更新時に呼ばれる
    /// (選択されたインデックス, チャートデータ) -> Void
    public var onChangeSelectedRecord: ((Int?, ChartData?) -> Void)? {
        didSet {
            setXAxisTouchCallback()
        }
    }
    /// X軸の刻み間隔が変更された際のコールバック
    /// ピンチイン・ピンチアウトなどで呼ばれる
    /// (X軸の刻み幅) -> Void
    public var onXAxisIntervalChanged: ((CGFloat) -> Void)? {
        didSet {
            setXAxisIntervalChangeCallback()
        }
    }
    /// スクロール変更時に実行されるコールバック (スクロール位置) -> Void
    public var onScrollChanged: ((CGFloat) -> Void)?
    /// チャートデータ。四本値などの情報
    public var chartData: ChartData?
    /// ピンチイン・ピンチアウト処理
    public let pinchInOut = PinchInOut()

    /// チャートのタッチが有効か
    open var canTouch = true

    /// チャートデータの最大数。nilの場合は無制限
    public var maxCount: Int?

    /// チャートデータが最大数を超えた場合、最大数から余分に削除するデータの個数
    /// 削除後はデータ数が maxCount - extraRemoveCount になる
    public var extraRemoveCount: Int = 0

    /// スクロール領域右端の余白
    public var rightScrollMargin: CGFloat = 50 {
        didSet {
            updateScrollSpan()
        }
    }
    /// スクロール領域左端の余白
    public var leftScrollMargin: CGFloat = 50 {
        didSet {
            updateScrollSpan()
        }
    }

    /// 色設定情報
    public var colorConfig: ColorConfig? {
        didSet {
            if let colorConfig = colorConfig {
                reflectColorConfig(colorConfig)
            }
        }
    }

    /// フォント設定情報
    public var fontContext: FontContext? {
        didSet {
            if let fontContext = fontContext {
                reflectFontContext(fontContext)
            }
        }
    }

    /// グラフの図形描画部分の幅
    public var graphWidth: CGFloat {
        var graphWidth = frame.width - margin.left - margin.right
        if !yAxisSetting.graphOverwrap {
            graphWidth -= yAxisSetting.visibleWidth
        }

        return graphWidth - border.leftWidth - border.rightWidth
    }

    /// スクロール位置
    public var scrollOffset: CGFloat {
        get { return CGFloat(scroller.scrollPosition) }
    }

    /// 親のスクロールビュー
    public weak var parentScrollView: UIScrollView?
    /// 親のスクロールビューがスワイプ可能か (TouchPoint) -> canSwipe
    public var canScrollParent: ((CGPoint) -> Bool)?
    /// 親のスクロールビューをドラッグ中か
    public var isParentDragging = false
    /// インジケーター
    public var loadingIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)

    /// 選択中のインデックス
    public var selectedIndex: Int? {
        return xAxis.touchMarker.index
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    /// 初期化処理
    open func commonInit() {
        // ChartViewをコードで生成するとbackgroundColor がnilになるが、
        // その場合再描画時に以前の描画内容がクリアされなくなってしまうため、デフォルト背景色を設定する
        if backgroundColor == nil {
            backgroundColor = ChartView.defaultBackgroundColor
        }
        addSubview(loadingIndicatorView)
        loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        loadingIndicatorView.color = ChartView.defaultLoadingIndicatorColor
        loadingIndicatorView.hidesWhenStopped = true
        
        scroller.onScrollChanged = { [weak self] in
            self?.actionScrollChanged(position: CGFloat($0))
        }

        pinchInOut.onPinchInOut = { [weak self] xAxisInterval, scrollOffset in
            self?.horizontalScaling(xAxisInterval: xAxisInterval, scrollOffset: scrollOffset)
        }
    }

    /// スクロール変更時の処理
    open func actionScrollChanged(position: CGFloat) {
        onScrollChanged?(position)
        setNeedsDisplay()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateScrollSpan()
        setNeedsDisplay()
    }

    /// 各グラフエリアのサイズと位置を更新する
    /// Viewのサイズや、グラフエリアの数などUI要素に変化があった場合このメソッドを呼び出す必要がある
    /// （X軸・Y軸サイズ変更、表示グラフの増減、グラフサイズの変更、マージン・ボーダー・セパレータ幅などの変更）
    open func updateGraphAreaRects(graphRect: CGRect) {
        let graphAreas = self.graphAreas.filter { $0.isVisible }
        let fixedHeightSum = graphAreas
            .compactMap { $0.height }
            .reduce(0, +)

        let separatorHeightSum = separator.lineWidth * CGFloat(graphAreas.count - 1)
        let otherHeightSum = max(graphRect.height - fixedHeightSum - separatorHeightSum, 0)

        let weightSum = graphAreas
            .filter { $0.height == nil }
            .map { $0.heightWeight }
            .reduce(0, +)

        var topY = graphRect.minY
        graphAreas.forEach {
            let height = $0.height
                ?? otherHeightSum * ($0.heightWeight / weightSum)
            $0.graphRect = CGRect(x: graphRect.minX,
                                  y: topY,
                                  width: graphRect.width,
                                  height: height)

            topY += height + separator.lineWidth
        }
    }

    /// プロット数とプロット間隔に応じてスクロール範囲を更新する
    open func updateScrollSpan() {
        let fullWidth = CGFloat(xAxis.count) * xAxis.interval
        scroller.maxPosition = Double(max(0, fullWidth - graphWidth + leftScrollMargin))
        scroller.minPosition = Double(-rightScrollMargin)
    }

    /// チャートデータをセットする
    open func setData(_ data: ChartData?) {
        clear()
        addData(data)
    }

    /// 最新の4本値を更新する
    /// この関数で更新するのは4本値だけなので、出来高などの更新を行う場合は `addData` を使う
    ///
    /// - Parameters:
    ///   - value: 直近の価格
    open func updateLatestFourValue(_ value: CGFloat) {
        guard let chartData = chartData, 0 < chartData.count else { return }

        chartData.updateLatestFourValue(value)
        graphAreas.forEach {
            $0.updateData(chartData, updatedFrom: chartData.count - 1)
        }
        onChangeSelectedRecord?(xAxis.touchMarker.index, chartData)

        setNeedsDisplay()
    }

    /// チャートデータを追加する
    open func addData(_ addedData: ChartData?) {
        let updatedFrom: Int?
        if let chartData = chartData {
            updatedFrom = chartData.merge(addedData)
        } else {
            chartData = addedData
            updatedFrom = 0
        }

        graphAreas.forEach {
            $0.updateData(chartData, updatedFrom: updatedFrom)
        }

        // 上限を超えるデータを削除
        if let maxCount = maxCount, let chartData = chartData,
            maxCount < chartData.count {

            let removeCount = (chartData.count - maxCount) + extraRemoveCount
            chartData.removeOldData(count: removeCount)
            graphAreas.forEach {
                $0.removeOldData(count: removeCount)
            }
            xAxis.touchMarker.adjustIndex(removeCount: removeCount)
        }
        updateXAxis()

        onChangeSelectedRecord?(xAxis.touchMarker.index, chartData)

        setNeedsDisplay()
    }

    /// 描画する
    open override func draw(_ rect: CGRect) {
        super.draw(rect) // backgroundColorはUIView任せで塗る
        guard let cgContext = UIGraphicsGetCurrentContext() else { return }

        // パディング内側の背景色描画
        let chartRect = makeChartRect(fullRect: rect)
        if let chartBackgroundColor = chartBackgroundColor {
            cgContext.setFillColor(chartBackgroundColor.cgColor)
            cgContext.fill(chartRect)
        }
        
        let outerBorderRect = makeOuterBorderRect(chartRect: chartRect)
        let innerBorderRect = makeInnerBorderRect(outerBorderRect: outerBorderRect)
        xAxis.rect = makeXAxisRect(outerBorderRect: outerBorderRect, innerBorderRect: innerBorderRect)
        
        // グラフ描画領域の背景色描画
        if let graphBackgroundColor = graphBackgroundColor {
            cgContext.setFillColor(graphBackgroundColor.cgColor)
            cgContext.fill(innerBorderRect)
        }
        
        if xAxis.fixedCount != nil {
            // plotCountが指定されている場合はスクロール位置固定
            scroller.scrollPosition = xAxis.initialScrollPosition.doubleValue
        }

        // drawのたびに呼び出すのが重ければ、必要最低限の呼び出しに変える
        updateGraphAreaRects(graphRect: innerBorderRect)
        graphAreas.forEach {
            $0.yAxis.rect = $0.yAxisRect(chartRect: chartRect, setting: yAxisSetting, border: border)
        }

        let context = ChartDrawingContext(cgContext: cgContext,
                                          xAxisInterval: xAxis.interval,
                                          scrollOffset: scrollOffset)

        let visibleSpan = context.visibleSpan(width: innerBorderRect.width, recordCount: xAxis.count)
        backgroundDrawers.forEach {
            $0.draw(context: context, data: chartData, rect: rect, chartRect: chartRect, visibleSpan: visibleSpan)
        }

        // 枠線の描画
        border.draw(context: context, outerRect: outerBorderRect)

        // X軸の描画
        xAxis.drawBeforeChart(context: context, graphRect: innerBorderRect, visibleSpan: visibleSpan)

        // グラフ領域の描画
        graphAreas.filter { $0.isVisible }
            .enumerated()
            .forEach { offset, element in
                element.draw(context: context,
                             data: chartData,
                             yAxisSetting: yAxisSetting,
                             selectedIndex: xAxis.touchMarker.index,
                             visibleSpan: visibleSpan,
                             colorConfig: colorConfig)
                if 0 < offset {
                    separator.draw(context: context, graphRect: element.graphRect)
                }
            }

        xAxis.drawAfterChart(context: context, graphRect: innerBorderRect, visibleSpan: visibleSpan)

        overlayDrawers.forEach {
            $0.draw(context: context, data: chartData, rect: rect, chartRect: chartRect, visibleSpan: visibleSpan)
        }
    }

    func drawDemoWatermark(rect: CGRect) {
        let font = UIFont.boldSystemFont(ofSize: 70)
        let color = UIColor(white: 0.5, alpha: 0.4)
        let text = "デモ版"
        let textSize = text.size(withAttributes: [.font: font])
        let point = CGPoint(x: rect.minX + (rect.width - textSize.width) / 2,
                            y: rect.minY + (rect.height - textSize.height) / 2)
        text.draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    /// メインのグラフエリアに表示するチャートを設定する
    /// 複数設定した場合、一つのグラフエリアに複数のチャートが表示される
    public func setMainCharts(_ charts: [TechnicalChart]) {
        mainGraphArea.charts = charts
        reflectConfig(charts: charts)
    }

    /// サブのグラフエリアに表示するチャートを設定する
    /// 複数設定した場合、チャートの数だけグラフエリアが作成される
    public func setSubCharts(_ charts: [TechnicalChart], height: CGFloat? = nil, heightWeight: CGFloat = 0.4) {
        subGraphAreas = charts.map {
            let area = GraphArea(height: height, heightWeight: heightWeight)
            area.charts = [$0]
            return area
        }

        reflectConfig(charts: charts)
    }

    /// X軸を更新する
    /// - Parameters:
    ///   - resetOnChange: X軸が変わった場合にスクロール位置とマーカーをリセットするか
    public func updateXAxis(resetOnChange: Bool = false) {
        let oldXAxisDataList = xAxis.dataList
        xAxis.dataList = chartData?.timeList
        graphAreas.forEach {
            $0.updateXAxis(xAxis, data: chartData)
        }
        
        if let oldXAxisDataList = oldXAxisDataList, resetOnChange {
            for i in 0..<oldXAxisDataList.count {
                // 古いX軸が一つでもなくなっていたらマーカーとスクロール位置をリセット
                if oldXAxisDataList[safe: i] != xAxis.dataList?[safe: i] {
                    xAxis.touchMarker.index = nil
                    scroller.clear(position: Double(xAxis.initialScrollPosition))
                    break
                }
            }
        }
        
        updateScrollSpan()
    }

    /// 表示するメインチャートを指定する
    public func setVisibleMainCharts(_ charts: [TechnicalChart]) {
        mainGraphArea.setVisibleCharts(charts, data: chartData)
        updateXAxis(resetOnChange: true)
        setNeedsDisplay()
    }
    
    /// 表示するサブチャートを指定する
    public func setVisibleSubCharts(_ charts: [TechnicalChart]) {
        subGraphAreas.forEach { graph in
            graph.setVisibleCharts(charts, data: chartData)
            graph.isVisible = graph.charts.contains(where: { $0.isVisible })
        }
        
        updateXAxis(resetOnChange: true)
        updateGraphAreaLayout()
        setNeedsDisplay()
    }

    /// テクニカル指標パラメータの変更を反映する
    /// パラメータが変わったテクニカル指標をクリアし、X軸の更新を行う
    public func refrectParameterChange() {
        graphAreas.forEach {
            $0.refrectParameterChange(data: chartData)
        }
        updateXAxis(resetOnChange: true)
        setNeedsDisplay()
    }

    /// グラフエリアのサイズと位置を更新する
    /// (drawで全く同じことをやっている）
    public func updateGraphAreaLayout() {
        let chartRect = makeChartRect(fullRect: frame)
        let outerBorderRect = makeOuterBorderRect(chartRect: chartRect)
        let innerBorderRect = makeInnerBorderRect(outerBorderRect: outerBorderRect)
        updateGraphAreaRects(graphRect: innerBorderRect)
        graphAreas.forEach {
            $0.yAxis.rect = $0.yAxisRect(chartRect: chartRect, setting: yAxisSetting, border: border)
        }
    }

    /// 引数のチャートに設定情報を反映する
    public func reflectConfig(charts: [TechnicalChart]) {
        if let colorConfig = colorConfig {
            charts.forEach { $0.reflectColorConfig(colorConfig) }
        }
        if let fontContext = fontContext {
            charts.forEach { ($0 as? UsesFontContext)?.reflectFontContext(fontContext) }
        }
    }

    /// マージンを除いた領域
    open func makeChartRect(fullRect: CGRect) -> CGRect {
        return CGRect(x: fullRect.minX + margin.left,
                      y: fullRect.minY + margin.top,
                      width: fullRect.width - margin.left - margin.right,
                      height: fullRect.height - margin.top - margin.bottom)
    }

    /// X軸、Y軸を除いた枠線の外側
    func makeOuterBorderRect(chartRect: CGRect) -> CGRect {
        var leftX = chartRect.minX
        var graphWidth = chartRect.width
        if !yAxisSetting.graphOverwrap {
            graphWidth -= yAxisSetting.visibleWidth
            if yAxisSetting.alignment == YAxisAlignment.left {
                leftX += yAxisSetting.visibleWidth
            }
        }
        var height = chartRect.height
        if xAxis.isVisible {
            height -= xAxis.height
        }
        return CGRect(x: leftX,
                      y: chartRect.minY,
                      width: graphWidth,
                      height: height)
    }
    
    /// X軸、Y軸を除いた枠線の内側
    func makeInnerBorderRect(outerBorderRect: CGRect) -> CGRect {
        return CGRect(x: outerBorderRect.minX + border.leftWidth,
                      y: outerBorderRect.minY + border.topWidth,
                      width: outerBorderRect.width - border.leftWidth - border.rightWidth,
                      height: outerBorderRect.height - border.topWidth - border.bottomWidth)
    }

    /// X軸描画領域
    open func makeXAxisRect(outerBorderRect: CGRect, innerBorderRect: CGRect) -> CGRect {
        return CGRect(x: innerBorderRect.minX,
                      y: outerBorderRect.maxY,
                      width: innerBorderRect.width,
                      height: xAxis.height)
    }

    /// プロット間の幅を変更する
    open func horizontalScaling(xAxisInterval: CGFloat, scrollOffset: CGFloat) {
        xAxis.variableInterval = xAxisInterval
        updateScrollSpan()
        scroller.scrollPosition = Double(scrollOffset)

        setNeedsDisplay()
    }

    /// 色設定を反映する
    /// ※ xAxis、yAxis、separator、borderなどを差し替える場合、差し替え後のインスタンスに設定は反映されない
    public func reflectColorConfig(_ colorConfig: ColorConfig) {
        backgroundColor = colorConfig["background"] ?? backgroundColor
        chartBackgroundColor = colorConfig["chart_background"] ?? chartBackgroundColor
        graphBackgroundColor = colorConfig["graph_background"] ?? graphBackgroundColor
        loadingIndicatorView.color = colorConfig["loading_indicator"] ?? loadingIndicatorView.color
        
        separator.reflectColorConfig(colorConfig)
        border.reflectColorConfig(colorConfig)
        xAxis.reflectColorConfig(colorConfig)
        graphAreas.forEach {
            $0.reflectColorConfig(colorConfig)
        }
    }

    /// フォント設定を反映する
    /// ※ xAxis、yAxis、separator、borderなどを差し替える場合、差し替え後のインスタンスに設定は反映されない
    public func reflectFontContext(_ fontContext: FontContext) {
        xAxis.reflectFontContext(fontContext)
        graphAreas.forEach {
            $0.reflectFontContext(fontContext)
        }
    }

    /// 読込インジケーターを表示する
    open func showLoadingIndicator() {
        loadingIndicatorView.startAnimating()
    }
    
    /// 読込インジケーターを非表示にする
    open func hideLoadingIndicator() {
        loadingIndicatorView.stopAnimating()
    }

    /// チャートをクリアする
    open func clear() {
        chartData = nil
        scroller.clear(position: Double(xAxis.initialScrollPosition))
        scroller.maxPosition = Double(frame.width)
        graphAreas.forEach { $0.clear() }
        xAxis.clear()
    }

    /// チャートデータの最大数を設定する
    public func setMaxCount(_ count: Int, extraRemoveCount: Int = 0) {
        self.maxCount = count
        self.extraRemoveCount = extraRemoveCount
    }
    
    /// 親のスクロールビューを設定する
    /// ChartViewがスクロールビュー上にあり、かつタッチ処理を行う必要がある場合、
    /// このファンクションで親のスクロールビューとどちらのタッチを有効にするかの判定を設定する
    open func setParentScrollView(_ scrollView: UIScrollView, canScrollParent: @escaping (CGPoint) -> Bool) {
        self.parentScrollView = scrollView
        self.canScrollParent = canScrollParent
        scrollView.delaysContentTouches = false
    }

    /// X軸にタッチコールバックを設定する
    func setXAxisTouchCallback() {
        xAxis.onRecordSelected = { [weak self] index in
            self?.onChangeSelectedRecord?(index, self?.chartData)
        }
    }

    /// X軸のインターバル変更コールバックを設定する
    func setXAxisIntervalChangeCallback() {
        xAxis.onIntervalChanged = { [weak self] newInterval in
            self?.onXAxisIntervalChanged?(newInterval)
        }
    }

    /// タッチ開始
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if !canTouch { return }
        guard let firstPoint = locations(touches: touches).first else { return }
        
        if canScrollParent?(firstPoint) == true {
            isParentDragging = true
            return
        }
        parentScrollView?.isScrollEnabled = false
        
        // グラフエリア
        let visibleGraphAreas = graphAreas.filter { $0.isVisible }
        for i in visibleGraphAreas.indices {
            if visibleGraphAreas[i].touchesBegan(point: firstPoint) {
                setNeedsDisplay()
                return
            }
        }
        if xAxis.touchesBegan(point: firstPoint, scrollOffset: scrollOffset) {
            setNeedsDisplay()
            return
        }
        
        if xAxis.fixedCount == nil {
            // スクロール
            scroller.touch(position: firstPoint.x)
            
            // ピンチイン・アウトなど
            let points = locations(touches: event?.allTouches).filter { frame.contains($0) }
            pinchInOut.touchesBegan(points: points, xAxisInterval: xAxis.interval, scrollOffset: scrollOffset)
        }
    }

    /// タッチ移動
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if !canTouch || isParentDragging { return }
        
        guard let firstPoint = locations(touches: touches).first else { return }

        // グラフエリア
        let visibleGraphAreas = graphAreas.filter { $0.isVisible }
        for i in visibleGraphAreas.indices {
            let graphArea = visibleGraphAreas[i]
            if graphArea.yAxis.isDragging {
                if graphArea.touchesMoved(point: firstPoint) {
                    setNeedsDisplay()
                }
                return
            }
        }
        if xAxis.isDragging {
            if xAxis.touchesMoved(point: firstPoint, scrollOffset: scrollOffset) {
                setNeedsDisplay()
            }
            return
        }
        
        if xAxis.fixedCount == nil {
            // スクロール
            scroller.touch(position: firstPoint.x)
            
            // ピンチイン・アウトなど
            let points = locations(touches: event?.allTouches).filter { frame.contains($0) }
            pinchInOut.touchesMoved(points: points, xAxisInterval: xAxis.interval, scrollOffset: scrollOffset, xAxisRect: xAxis.rect)
        }
    }

    /// タッチ終了
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchesCompleted(touches, with: event)
    }
    
    /// タッチキャンセル
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchesCompleted(touches, with: event)
    }
    
    /// タッチ終了時の処理（キャンセル時も呼ばれる）
    open func touchesCompleted(_ touches: Set<UITouch>, with event: UIEvent?) {
        parentScrollView?.isScrollEnabled = true
        let wasParentDragging = isParentDragging
        isParentDragging = false
        if !canTouch || wasParentDragging { return }
        guard let firstPoint = locations(touches: touches).first else { return }
        
        // グラフエリア
        let visibleGraphAreas = graphAreas.filter { $0.isVisible }
        for i in visibleGraphAreas.indices {
            let graphArea = visibleGraphAreas[i]
            if graphArea.yAxis.isDragging {
                if graphArea.touchesCompleted(point: firstPoint) {
                    setNeedsDisplay()
                }
                return
            }
        }
        if xAxis.isDragging {
            if xAxis.touchesCompleted(point: firstPoint, scrollOffset: scrollOffset) {
                setNeedsDisplay()
            }
            return
        }
        
        if xAxis.fixedCount == nil {
            // スクロール
            scroller.touchEnd(position: firstPoint.x)
            
            // ピンチイン・アウトなど
            let points = locations(touches: event?.allTouches).filter { frame.contains($0) }
            pinchInOut.touchesEnded(points: points)
        }
    }

    /// タッチをView座標に変換する
    open func locations(touches: Set<UITouch>?) -> [CGPoint] {
        return touches?.map { $0.location(in: self) } ?? []
    }

    /// 別のChartViewの状態（チャートデータ、レコード幅、スクロール位置）を引き継ぐ
    public func importState(from: ChartView) {
        clear()
        addData(from.chartData)

        xAxis.importState(from: from.xAxis)
        scroller.importState(from: from.scroller)

        zip(from.graphAreas, graphAreas).forEach { from, to in
            to.importState(from: from)
        }
        setNeedsDisplay()
    }
}
