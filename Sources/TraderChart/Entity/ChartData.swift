//
//  ChartData.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 四本値、出来高などのチャートデータ
open class ChartData {
    /// 日時の一覧
    open var timeList: [String]
    /// 日時が同じで異なるレコードを識別するための通番（Tickは同一時刻に複数レコードが発生する可能性があるため必要）
    open var sequenceNumberList: [Int64]?

    /// 始値の一覧
    open var openList = NumberArray()
    /// 高値の一覧
    open var highList = NumberArray()
    /// 安値の一覧
    open var lowList = NumberArray()
    /// 終値の一覧
    open var closeList = NumberArray()
    public var values: NumberArray { return closeList }
    /// 出来高の一覧
    open var volumeList: NumberArray?
    /// VWAPの一覧
    open var vwapList: NumberArray?

    /// レコード数
    open var count: Int {
        return timeList.count
    }
    
    open var isEmpty: Bool {
        return timeList.isEmpty
    }

    open var latestTime: String? {
        return timeList.last
    }

    open var latestSequenceNumber: Int64? {
        return sequenceNumberList?.last
    }

    /// 時間を比較する（データマージの際、レコードの前後関係を判定するために使う）
    public var compareTime: ((String, String) -> ComparisonResult) = compareStringAsInt

    public init(timeList: [String] = [],
                sequenceNumberList: [Int64]? = nil,
                openList: [CGFloat?]? = nil,
                highList: [CGFloat?]? = nil,
                lowList: [CGFloat?]? = nil,
                closeList: [CGFloat?] = [],
                compareTime: @escaping ((String, String) -> ComparisonResult) = compareStringAsInt) {
        self.timeList = timeList
        self.sequenceNumberList = sequenceNumberList

        self.openList.append(contentsOf: openList ?? closeList)
        self.highList.append(contentsOf: highList ?? closeList)
        self.lowList.append(contentsOf: lowList ?? closeList)
        self.closeList.append(contentsOf: closeList)

        self.compareTime = compareTime
    }

    /// データをコピーする
    public func copy() -> ChartData {
        let other = ChartData()

        other.timeList = Array(timeList)
        if let sequenceNumberList = sequenceNumberList {
            other.sequenceNumberList = Array(sequenceNumberList)
        }
        other.openList = openList.copy()
        other.highList = highList.copy()
        other.lowList = lowList.copy()
        other.closeList = closeList.copy()
        other.volumeList = volumeList?.copy()
        other.vwapList = vwapList?.copy()
        return other
    }

    /// 既存のデータに新しいデータをマージする。
    /// 既に存在する日時のレコードは新しいデータで上書きされ、存在しなかった日時のレコードは末尾に追加される。
    ///
    /// - Parameters:
    ///   - data: マージするデータ
    /// - Returns: 更新された部分の先頭のインデックス
    public func merge(_ data: ChartData?) -> Int? {
        guard let data = data, !data.isEmpty else { return nil }
        if isEmpty {
            appendData(data)
            return 0
        }

        let oldLastIndex = count - 1
        
        // 既存データ末尾と追加データ先頭を比較
        let firstResult = compare(data, index: count - 1, targetIndex: 0)

        if firstResult == ComparisonResult.orderedAscending {
            appendData(data) // 単純に後ろに追加
            return oldLastIndex + 1
        } else if firstResult == ComparisonResult.orderedSame {
            removeLast() // 末尾レコードを差し替え
            appendData(data)
            return oldLastIndex
        }

        // 既存データ末尾と追加データ末尾を比較
        let lastResult = compare(data, index: count - 1, targetIndex: data.count - 1)
        if lastResult == .orderedDescending {
            // 追加データの方が古ければ何もしない
            return nil
        }

        var index = count - 2
        while 0 < index && compare(data, index: index, targetIndex: 0) == ComparisonResult.orderedDescending {
            index -= 1
        }
        removeLastFrom(index)
        appendData(data)
        
        return index
    }

    /// 最新の四本値を更新する。引数により終値を更新し、引数が高値を上回る、または安値を下回る場合は、高値または安値を更新する
    public func updateLatestFourValue(_ value: CGFloat) {
        let lastIndex = closeList.count - 1
        closeList[lastIndex] = value

        if let latestHight = highList.last, latestHight < value {
            highList[lastIndex] = value
        }
        if let latestLow = lowList.last, value < latestLow {
            lowList[lastIndex] = value
        }
    }

    /// 最新の足の情報を削除する
    public func removeLast() {
        if !timeList.isEmpty {
            timeList.removeLast()
        }
        if sequenceNumberList?.isEmpty == false {
            sequenceNumberList?.removeLast()
        }
        openList.removeLast()
        highList.removeLast()
        lowList.removeLast()
        closeList.removeLast()
        volumeList?.removeLast()
        vwapList?.removeLast()
    }

    /// 最古の足の情報を削除する
    public func removeOldData(count: Int) {
        timeList.removeFirst(min(count, timeList.count))

        if var sequenceList = sequenceNumberList {
            sequenceList.removeFirst(min(count, sequenceList.count))
        }

        openList.removeFirst(count)
        highList.removeFirst(count)
        lowList.removeFirst(count)
        closeList.removeFirst(count)
        volumeList?.removeFirst(count)
        vwapList?.removeFirst(count)
    }

    /// 引数に指定したインデックス以降の足の情報を削除する
    public func removeLastFrom(_ index: Int) {
        timeList.removeLastFrom(index)
        sequenceNumberList?.removeLastFrom(index)
        openList.removeLastFrom(index)
        highList.removeLastFrom(index)
        lowList.removeLastFrom(index)
        closeList.removeLastFrom(index)
        volumeList?.removeLastFrom(index)
        vwapList?.removeLastFrom(index)
    }

    private func appendData(_ data: ChartData) {
        for i in data.timeList.indices {
            timeList.append(data.timeList[i])
            sequenceNumberList?.append(data.sequenceNumberList?[safe: i] ?? 0)
            openList.append(data.openList[i])
            highList.append(data.highList[i])
            lowList.append(data.lowList[i])
            closeList.append(data.closeList[i])
            volumeList?.append(data.volumeList?[i])
            vwapList?.append(data.vwapList?[i])
        }
    }

    /// 指定したindex位置の日時を比較する
    public func compare(_ data: ChartData, index: Int, targetIndex: Int) -> ComparisonResult {
        if let seq1 = sequenceNumberList?[safe: index],
            let seq2 = data.sequenceNumberList?[safe: targetIndex] {
            return compareSequence(seq1, seq2)
        }

        if let time1 = timeList[safe: index], let time2 = data.timeList[safe: targetIndex] {
            return compareTime(time1, time2)
        }

        // シーケンスも日時もない不正なケース
        return ComparisonResult.orderedSame
    }

    /// 特定インデックスのレコードを取得する
    open subscript(index: Int) -> ChartRecord? {
        get {
            if 0 <= index && index < count {
                return ChartRecord(time: timeList[safe: index],
                                   open: openList[index],
                                   high: highList[index],
                                   low: lowList[index],
                                   close: closeList[index],
                                   volume: volumeList?[index],
                                   vwap: vwapList?[index])
            }
            return nil
        }
    }

    public func compareSequence(_ left: Int64, _ right: Int64) -> ComparisonResult {
        if left < right {
            return ComparisonResult.orderedAscending
        } else if left > right {
            return ComparisonResult.orderedDescending
        } else {
            return ComparisonResult.orderedSame
        }
    }

    /// Stringを整数値として比較する
    public static func compareStringAsInt(left: String, right: String) -> ComparisonResult {
        // 同じ文字列ならIntにせず同一扱い
        if left == right {
            return ComparisonResult.orderedSame
        }

        guard let leftInt = Int64(left), let rightInt = Int64(right) else {
            // Intにできない場合は仕方ないので文字列比較
            if left < right {
                return ComparisonResult.orderedAscending
            } else {
                return ComparisonResult.orderedDescending
            }
        }

        // 数値比較
        if leftInt < rightInt {
            return ComparisonResult.orderedAscending
        } else {
            return ComparisonResult.orderedDescending
        }
    }
}

extension Array {

    mutating func removeLastFrom(_ index: Int) {
        if index < 0 || count <= index {
            return
        }
        self = Array(prefix(upTo: index))
    }
}
